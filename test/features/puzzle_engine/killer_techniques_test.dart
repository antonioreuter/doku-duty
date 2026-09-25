import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';
import 'package:doku_duty/features/puzzle_engine/domain/deduction.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/solver_state.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/puzzle_engine/domain/techniques/ladder.dart';

import 'support/killer.dart';
import 'support/positions.dart';

Deduction? run(Technique technique, SolverState state) =>
    techniqueFor(technique).deduce(state);

const List<int> _all = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

/// Every digit except [keep], struck from [cell] — the shape of a cage
/// combination deduction.
List<CellDigit> _strikeAllBut(int cell, Set<int> keep) => <CellDigit>[
  for (final digit in _all)
    if (!keep.contains(digit)) CellDigit(cell, digit),
];

void main() {
  group('cage combination', () {
    test('a two-cell cage of 3 restricts to {1,2}', () {
      final cages = cagesAround(<Cage>[
        Cage(cells: <int>[at(0, 0), at(0, 1)], sum: 3),
      ]);
      final state = killerPosition(
        cages,
        candidates: <int, List<int>>{at(0, 0): _all, at(0, 1): _all},
      );
      final deduction = run(Technique.cageCombination, state)!;

      expect(deduction.technique, Technique.cageCombination);
      expect(deduction.placements, isEmpty);
      expect(deduction.eliminations.toSet(), <CellDigit>{
        ..._strikeAllBut(at(0, 0), <int>{1, 2}),
        ..._strikeAllBut(at(0, 1), <int>{1, 2}),
      });
      expect(deduction.witnesses, <int>[at(0, 0), at(0, 1)]);
    });

    test('a three-cell cage of 24 restricts to {7,8,9}', () {
      final cells = <int>[at(4, 3), at(4, 4), at(5, 4)];
      final cages = cagesAround(<Cage>[Cage(cells: cells, sum: 24)]);
      final state = killerPosition(
        cages,
        candidates: <int, List<int>>{for (final cell in cells) cell: _all},
      );
      final deduction = run(Technique.cageCombination, state)!;

      expect(deduction.eliminations.toSet(), <CellDigit>{
        for (final cell in cells) ..._strikeAllBut(cell, <int>{7, 8, 9}),
      });
    });

    test('a placed value narrows the rest of its cage', () {
      // 9 is placed; the other two must make 3, which only 1 and 2 do.
      final cages = cagesAround(<Cage>[
        Cage(cells: <int>[at(0, 0), at(0, 1), at(0, 2)], sum: 12),
      ]);
      final state = killerPosition(
        cages,
        digits: <int, int>{at(0, 0): 9},
        candidates: <int, List<int>>{
          at(0, 1): <int>[1, 2, 3, 4, 5, 6, 7, 8],
          at(0, 2): <int>[1, 2, 3, 4, 5, 6, 7, 8],
        },
      );
      final deduction = run(Technique.cageCombination, state)!;

      expect(deduction.eliminations.toSet(), <CellDigit>{
        for (final cell in <int>[at(0, 1), at(0, 2)])
          for (final digit in <int>[3, 4, 5, 6, 7, 8]) CellDigit(cell, digit),
      });
    });

    test('a combination the candidates cannot seat is not counted', () {
      // 10 in two cells is {1,9}, {2,8}, {3,7} or {4,6}. With one cell holding
      // only 1 or 2, only {1,9} and {2,8} can be seated, so 3 goes from the
      // other cell.
      final cages = cagesAround(<Cage>[
        Cage(cells: <int>[at(0, 0), at(0, 1)], sum: 10),
      ]);
      final state = killerPosition(
        cages,
        candidates: <int, List<int>>{
          at(0, 0): <int>[1, 2],
          at(0, 1): <int>[3, 8, 9],
        },
      );
      final deduction = run(Technique.cageCombination, state)!;

      expect(deduction.eliminations, <CellDigit>[CellDigit(at(0, 1), 3)]);
    });

    test('makes no deduction when every candidate is in some combination', () {
      final cages = cagesAround(<Cage>[
        Cage(cells: <int>[at(0, 0), at(0, 1)], sum: 10),
      ]);
      final state = killerPosition(
        cages,
        candidates: <int, List<int>>{
          at(0, 0): <int>[1, 2, 3, 4, 6, 7, 8, 9],
          at(0, 1): <int>[1, 2, 3, 4, 6, 7, 8, 9],
        },
      );
      expect(run(Technique.cageCombination, state), isNull);
    });

    test('deduces nothing on a classic grid', () {
      expect(run(Technique.cageCombination, stateOf(referenceClues)), isNull);
      expect(run(Technique.cageCombination, stateOf('.' * 81)), isNull);
    });
  });

  // Each shape below is built so that exactly one unit has a single innie or
  // outie, and the rest of the board is covered by cages no unit contains
  // alone. The value placed is read from the reference solution, which the
  // sums were taken from.
  group('the 45 rule', () {
    // Row 1 is two cages of four and one cell whose cage drops into row 2.
    const rowShape =
        'aaaabbbbc'
        'ddddddddc'
        'eeeeeeeee'
        'fffffffff'
        'ggggggggg'
        'hhhhhhhhh'
        'iiiiiiiii'
        'jjjjjjjjj'
        'kkkkkkkkk';

    test('places a single innie of a row', () {
      final cages = cagesFromShape(rowShape, referenceSolution);
      final state = SolverState.fromGrid(Grid.empty, cages: cages);
      final deduction = run(Technique.fortyFiveRule, state)!;

      expect(deduction.technique, Technique.fortyFiveRule);
      // r1c9 is 2: the row's 45 less the 43 its two whole cages hold.
      expect(deduction.placements, <CellDigit>[CellDigit(at(0, 8), 2)]);
      expect(deduction.eliminations, isEmpty);
      expect(deduction.witnesses, contains(at(0, 0)));
    });

    test('places a single outie of a row', () {
      // With r1c9 given, the row has no innie left; its three cages hold one
      // cell outside it, r2c9, which is their sum less 45.
      final cages = cagesFromShape(rowShape, referenceSolution);
      final state = SolverState.fromGrid(
        Grid.empty.withDigit(at(0, 8), 2),
        cages: cages,
      );
      final deduction = run(Technique.fortyFiveRule, state)!;

      expect(deduction.placements, <CellDigit>[CellDigit(at(1, 8), 8)]);
    });

    test('places a single innie of a column', () {
      // The row shape transposed.
      final transposed = <String>[
        for (var cell = 0; cell < 81; cell++)
          rowShape[(cell % 9) * 9 + cell ~/ 9],
      ].join();
      final cages = cagesFromShape(transposed, referenceSolution);
      final state = SolverState.fromGrid(Grid.empty, cages: cages);
      final deduction = run(Technique.fortyFiveRule, state)!;

      expect(deduction.placements, <CellDigit>[CellDigit(at(8, 0), 3)]);
    });

    test('places a single innie of a block', () {
      // Block 1 is two column cages, a pair above r3c3, and r3c3 itself,
      // whose cage runs out into block 2.
      const blockShape =
          'abcfffggg'
          'abcfffggg'
          'abddhhhii'
          'jjjkkklll'
          'jjjkkklll'
          'mmmnnnooo'
          'mmmnnnooo'
          'pppqqqrrr'
          'pppqqqrrr';
      final cages = cagesFromShape(blockShape, referenceSolution);
      final state = SolverState.fromGrid(Grid.empty, cages: cages);
      final deduction = run(Technique.fortyFiveRule, state)!;

      expect(deduction.placements, <CellDigit>[CellDigit(at(2, 2), 8)]);
    });

    test('makes no deduction where no unit has a single innie or outie', () {
      final state = SolverState.fromGrid(
        Grid.empty,
        cages: dominoCages(referenceSolution),
      );
      expect(run(Technique.fortyFiveRule, state), isNull);
    });

    test('deduces nothing on a classic grid', () {
      expect(run(Technique.fortyFiveRule, stateOf(referenceClues)), isNull);
      expect(run(Technique.fortyFiveRule, stateOf('.' * 81)), isNull);
    });
  });
}
