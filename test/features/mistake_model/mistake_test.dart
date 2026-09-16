import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/mistake_model/domain/mistake.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/placement.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

void main() {
  final clues = _gridOf(_clues);
  final solution = _gridOf(_solution);

  /// Cell 2 is empty in the clues and the solution has a 4 there.
  const empty = 2;
  const rightDigit = 4;
  const wrongDigit = 7;

  PlacementReport report(Grid grid, int cell, int digit) => inspectPlacement(
    grid: grid,
    solution: solution,
    cell: cell,
    digit: digit,
  );

  /// The clues with [digit] already sitting in [cell].
  Grid holding(int cell, int digit) => clues.withDigit(cell, digit);

  group('a placement that disagrees with the solution', () {
    test('a wrong digit in an empty cell is a mistake', () {
      expect(isMistake(report(clues, empty, wrongDigit)), isTrue);
    });

    test('the right digit is not a mistake', () {
      expect(isMistake(report(clues, empty, rightDigit)), isFalse);
    });

    test('placing the right digit again is not a mistake', () {
      final board = holding(empty, rightDigit);
      expect(isMistake(report(board, empty, rightDigit)), isFalse);
    });
  });

  // D-05. The player did not get a logic problem wrong; they mis-tapped.
  group('overwriting an already-correct value', () {
    test('is never a mistake', () {
      final board = holding(empty, rightDigit);
      expect(isMistake(report(board, empty, wrongDigit)), isFalse);
    });

    test('is not a mistake whichever wrong digit replaces it', () {
      final board = holding(empty, rightDigit);
      for (var digit = 1; digit <= 9; digit++) {
        expect(
          isMistake(report(board, empty, digit)),
          isFalse,
          reason: 'digit $digit over a correct value',
        );
      }
    });
  });

  // The two rules must not overlap: only a *correct* value being overwritten is
  // exempt, and a wrong value being overwritten is an ordinary wrong placement.
  group('the exemption is narrow', () {
    test('a wrong digit over a wrong digit is a mistake', () {
      final board = holding(empty, wrongDigit);
      expect(isMistake(report(board, empty, 8)), isTrue);
    });

    test('the right digit over a wrong digit is not a mistake', () {
      final board = holding(empty, wrongDigit);
      expect(isMistake(report(board, empty, rightDigit)), isFalse);
    });

    test('a wrong digit that breaks no unit still counts', () {
      // A digit can conflict with no **peer** and still disagree with the
      // solution. The engine reports the two apart precisely so this layer can
      // count the second without the first.
      final quiet = <int>[
        for (var digit = 1; digit <= 9; digit++)
          if (report(clues, empty, digit).conflictingCells.isEmpty &&
              digit != rightDigit)
            digit,
      ];
      expect(quiet, isNotEmpty, reason: 'nothing to prove otherwise');
      for (final digit in quiet) {
        expect(
          isMistake(report(clues, empty, digit)),
          isTrue,
          reason: '$digit',
        );
      }
    });

    test('a conflicting digit that is nonetheless right is not a mistake', () {
      // Nothing about a **unit** clash enters the verdict — only the solution
      // and D-05 do.
      final verdict = report(clues, empty, rightDigit);
      expect(verdict.agreesWithSolution, isTrue);
      expect(isMistake(verdict), isFalse);
    });
  });

  // D-14, made structural rather than careful. A candidate is thinking out
  // loud, and punishing exploration is what would undermine the technique
  // ladder the whole progression rests on — so the verdict is not given the
  // means to see one.
  group('no note can reach the verdict', () {
    final source = File(
      'lib/features/mistake_model/domain/mistake.dart',
    ).readAsStringSync();

    test('the rule imports nothing that knows what a note is', () {
      for (final forbidden in const <String>[
        'note_set',
        'note_enums',
        'NoteSet',
        'NoteKind',
        'NoteOrigin',
        'grid_input',
      ]) {
        expect(
          source,
          isNot(contains(forbidden)),
          reason: 'the verdict must not be able to read a note ($forbidden)',
        );
      }
    });

    test('it takes a placement, and a placement is a value in a cell', () {
      // Every fact the verdict can consult, enumerated. A note is not among
      // them and cannot become one without this failing.
      final verdict = report(clues, empty, wrongDigit);
      expect(verdict.cell, empty);
      expect(verdict.digit, wrongDigit);
      expect(verdict.agreesWithSolution, isFalse);
      expect(verdict.overwritesCorrectValue, isFalse);
      expect(verdict.conflictingCells, isA<List<int>>());
    });
  });
}
