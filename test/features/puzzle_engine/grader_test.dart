import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grader.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';

import 'support/corpus.dart';
import 'support/positions.dart';

CorpusEntry entryFor(Technique technique) =>
    corpus.firstWhere((entry) => entry.technique == technique);

void main() {
  test('a puzzle solvable by singles alone grades Greenhorn', () {
    for (final technique in <Technique>[
      Technique.fullHouse,
      Technique.nakedSingle,
    ]) {
      final result = grade(entryFor(technique).grid);
      expect(result, isA<Graded>());
      expect((result as Graded).rank, Rank.greenhorn);
      expect(result.hardest, technique);
    }
  });

  test(
    'every rank is reachable, and only by the technique that defines it',
    () {
      for (final entry in corpus) {
        final result = grade(entry.grid);
        expect(result, isA<Graded>(), reason: entry.technique.name);
        final graded = result as Graded;
        expect(graded.hardest, entry.technique, reason: entry.technique.name);
        expect(graded.rank, entry.rank, reason: entry.technique.name);
      }
      expect(
        corpus.map((entry) => entry.rank).toSet(),
        Rank.values.toSet(),
        reason: 'the corpus must reach all six ranks',
      );
    },
  );

  // D-07: the grade is the hardest technique required, never the clue count. A
  // 26-clue puzzle can be easier than a 30-clue one, which is the whole reason
  // the ladder is graded this way.
  test('clue count does not move a grade', () {
    for (final entry in corpus) {
      final first = grade(entry.grid) as Graded;
      final second = grade(entry.alternateGrid) as Graded;

      expect(
        entry.grid.filledCount,
        isNot(entry.alternateGrid.filledCount),
        reason: '${entry.technique.name}: the pair must differ in clue count',
      );
      expect(second.rank, first.rank, reason: entry.technique.name);
      expect(second.hardest, first.hardest, reason: entry.technique.name);
    }
  });

  group('a puzzle beyond the ladder', () {
    test('is ungradable, not Legend', () {
      final result = grade(gridOf(puzzleBeyondTheLadder));

      expect(result, isA<Ungradable>());
      expect(result, isNot(isA<Graded>()));
      final ungradable = result as Ungradable;
      expect(ungradable.cellsRemaining, greaterThan(0));
      expect(ungradable.stalledAt.filledCount, lessThan(81));
    });

    test('an empty grid is ungradable too, and nothing is thrown', () {
      expect(() => grade(Grid.empty), returnsNormally);
      expect(grade(Grid.empty), isA<Ungradable>());
    });
  });

  // The ladder is only meaningful at its edges: a technique that grades one
  // step out lands every puzzle in the wrong rank at exactly the boundary a
  // player is told they have crossed.
  // Classic techniques, walked in ladder order. The **killer** ones are graded
  // on **cage**d grids in killer_grader_test.dart.
  test('each technique grades to its own rank, and the next one grades up', () {
    final classic = Technique.values
        .where((technique) => !technique.killerOnly)
        .toList();
    for (var i = 1; i < classic.length; i++) {
      final lower = classic[i - 1];
      final higher = classic[i];
      final lowerGrade = grade(entryFor(lower).grid) as Graded;
      final higherGrade = grade(entryFor(higher).grid) as Graded;

      expect(lowerGrade.rank, lower.introducedAt);
      expect(higherGrade.rank, higher.introducedAt);
      expect(
        higherGrade.rank.index,
        greaterThanOrEqualTo(lowerGrade.rank.index),
        reason: '${lower.name} then ${higher.name}',
      );
      if (higher.introducedAt != lower.introducedAt) {
        expect(
          higherGrade.rank.index,
          lowerGrade.rank.index + 1,
          reason: 'the boundary between ${lower.name} and ${higher.name}',
        );
      }
    }
  });

  test('a finished grid needs no technique and grades Greenhorn', () {
    final result = grade(gridOf(referenceSolution));
    expect(result, isA<Graded>());
    expect((result as Graded).rank, Rank.greenhorn);
    expect(result.hardest, isNull);
  });

  test('grading reports what it used, not only the hardest of it', () {
    final graded = grade(entryFor(Technique.xWing).grid) as Graded;
    expect(graded.techniquesUsed, contains(Technique.xWing));
    expect(graded.techniquesUsed, contains(Technique.nakedSingle));
    for (final technique in graded.techniquesUsed) {
      expect(technique.index, lessThanOrEqualTo(graded.hardest!.index));
    }
  });
}
