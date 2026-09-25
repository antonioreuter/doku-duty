import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/techniques/ladder.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';

void main() {
  group('the catalogue covers the ladder', () {
    // Cage combination is the exception, and D-128 is why: everyone meets full
    // house and naked single before they meet the app, and nobody meets a
    // **cage** before their first **variant node**, whatever their **rank**.
    test('every technique above Greenhorn, and every killer technique, has '
        'exactly one lesson', () {
      for (final technique in Technique.values) {
        final matches = lessonCatalogue.where(
          (lesson) => lesson.technique == technique,
        );
        if (technique.introducedAt.isHarderThan(Rank.greenhorn) ||
            technique.killerOnly) {
          expect(matches, hasLength(1), reason: technique.name);
        } else {
          expect(matches, isEmpty, reason: '${technique.name} is the game');
        }
      }
    });

    test('both killer lessons are in it (D-128)', () {
      expect(
        lessonCatalogue.map((lesson) => lesson.technique),
        containsAll(<Technique>[
          Technique.cageCombination,
          Technique.fortyFiveRule,
        ]),
      );
    });

    test('a killer lesson carries valid cages, and a classic one none', () {
      for (final lesson in lessonCatalogue) {
        final killer = lesson.technique?.killerOnly ?? false;
        expect(lesson.cageSet != null, killer, reason: lesson.id);
      }
    });

    test('the notes lesson is in it, and teaches no technique', () {
      final notes = lessonCatalogue.singleWhere(
        (lesson) => lesson.id == Lesson.notes.id,
      );
      expect(notes.technique, isNull);
    });

    test('ids are unique and stable-looking', () {
      final ids = lessonCatalogue.map((lesson) => lesson.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, isNotEmpty);
        expect(id.trim(), id, reason: 'a stored key with whitespace');
      }
    });

    test('every lesson is titled and has steps ending in a placement', () {
      for (final lesson in lessonCatalogue) {
        expect(lesson.title, isNotEmpty, reason: lesson.id);
        expect(lesson.steps, isNotEmpty, reason: lesson.id);
        for (final step in lesson.steps) {
          expect(step.text, isNotEmpty, reason: lesson.id);
        }
        expect(lesson.placement.digit, inInclusiveRange(1, 9));
        expect(lesson.placement.cell, inInclusiveRange(0, 80));
      }
    });
  });

  group('every lesson grid is a real position', () {
    test('81 characters, and a legal sudoku position', () {
      for (final lesson in lessonCatalogue) {
        expect(lesson.grid.length, 81, reason: lesson.id);
        expect(
          Grid.parse(lesson.grid),
          isA<ValidGrid>(),
          reason: '${lesson.id} is not a legal position',
        );
      }
    });

    test('the cell the player fills is empty on the grid', () {
      for (final lesson in lessonCatalogue) {
        expect(
          lesson.grid[lesson.placement.cell],
          '.',
          reason: '${lesson.id} asks for a cell that is already filled',
        );
      }
    });

    test('every highlighted cell is on the board', () {
      for (final lesson in lessonCatalogue) {
        for (final step in lesson.steps) {
          for (final cell in step.cells) {
            expect(cell, inInclusiveRange(0, 80), reason: lesson.id);
          }
        }
      }
    });
  });

  // The test this whole section exists for. A lesson demonstrating a naked pair
  // on a grid that holds no naked pair reads perfectly and teaches nothing, and
  // nothing else here would catch it.
  group('every lesson teaches something its own grid contains', () {
    test('the technique it names actually applies to its position', () {
      for (final lesson in lessonCatalogue) {
        final technique = lesson.technique;
        if (technique == null) continue;

        final parsed = Grid.parse(lesson.grid) as ValidGrid;
        final state = SolverState.fromGrid(parsed.grid, cages: lesson.cageSet);
        final deduction = techniqueFor(technique).deduce(state);

        expect(
          deduction,
          isNotNull,
          reason:
              '${lesson.id}: the grid holds no ${technique.name} to point at',
        );
        expect(deduction!.technique, technique, reason: lesson.id);
        expect(deduction.changesNothing, isFalse, reason: lesson.id);
      }
    });

    test('the placement the lesson asks for is the right digit', () {
      // Checked against a full solve rather than against the lesson's own
      // claim: the answer has to be what the puzzle actually holds, not what
      // the copy says it holds.
      for (final lesson in lessonCatalogue) {
        final parsed = Grid.parse(lesson.grid) as ValidGrid;
        final state = SolverState.fromGrid(parsed.grid, cages: lesson.cageSet);

        for (var step = 0; step < 300 && !state.isSolved; step++) {
          var advanced = false;
          for (final entry in techniqueLadder) {
            final deduction = entry.deduce(state);
            if (deduction != null) {
              state.apply(deduction);
              advanced = true;
              break;
            }
          }
          if (!advanced) break;
        }

        expect(
          state.isSolved,
          isTrue,
          reason: '${lesson.id}: its grid cannot be finished by the ladder',
        );
        expect(
          state.digitAt(lesson.placement.cell),
          lesson.placement.digit,
          reason: '${lesson.id}: it asks for the wrong digit',
        );
      }
    });

    test('the cells a step marks are not empty of meaning', () {
      // Every lesson but the last step of the notes lesson points somewhere.
      for (final lesson in lessonCatalogue) {
        final marked = lesson.steps.where((s) => s.cells.isNotEmpty);
        expect(
          marked,
          isNotEmpty,
          reason: '${lesson.id}: no step marks anything to look at',
        );
      }
    });

    test('the last step names the digit the player is asked for', () {
      // The gap a golden found and nothing else did. Three lessons shipped a
      // first draft whose closing sentence named the *eliminated* digit where
      // it meant the placed one — "only the 2 left" over a cell whose answer
      // was 5. Every other test passed: the placement was right, the grid was
      // right, the technique was right. Only the sentence was wrong, and the
      // sentence is the lesson.
      for (final lesson in lessonCatalogue) {
        final last = lesson.steps.last.text;
        expect(
          last.contains('${lesson.placement.digit}'),
          isTrue,
          reason:
              '${lesson.id}: the closing step never names '
              '${lesson.placement.digit}, the digit it asks for — "$last"',
        );
      }
    });

    test('no step names a digit as the answer that is not the answer', () {
      // The narrower half of the same check: the closing sentence of a lesson
      // that says "only the N left" has to mean the placement.
      final claim = RegExp(r'only the (\d)');
      for (final lesson in lessonCatalogue) {
        for (final step in lesson.steps) {
          final match = claim.firstMatch(step.text);
          if (match == null) continue;
          expect(
            match.group(1),
            '${lesson.placement.digit}',
            reason:
                '${lesson.id}: claims "${match.group(0)}" but places '
                '${lesson.placement.digit}',
          );
        }
      }
    });
  });
}
