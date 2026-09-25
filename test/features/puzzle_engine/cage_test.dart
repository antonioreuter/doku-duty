import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import 'support/killer.dart';
import 'support/positions.dart';

void main() {
  group('a valid cage set', () {
    test('holds every one of the 81 cells exactly once', () {
      final cages = dominoCages(referenceSolution);
      final seen = <int>[for (final cage in cages.cages) ...cage.cells]..sort();
      expect(seen, List<int>.generate(GridGeometry.cellCount, (i) => i));
    });

    test('answers which cage a cell is in', () {
      final cages = dominoCages(referenceSolution);
      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        expect(cages.cageOf(cell).cells, contains(cell));
      }
      expect(identical(cages.cageOf(0), cages.cageOf(1)), isTrue);
    });

    test('a cage lists its cells ascending, and its head is the first in '
        'reading order', () {
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[10, 1, 9], sum: 6),
        ..._singletonsExcept(const <int>{1, 9, 10}),
      ]);
      final cage = (result as ValidCageSet).cages.cageOf(10);
      expect(cage.cells, <int>[1, 9, 10]);
      expect(cage.head, 1);
    });

    test('its solution sums every cage to its cage sum, repeating nothing', () {
      final cages = dominoCages(referenceSolution);
      expect(cages.isSatisfiedBy(gridOf(referenceSolution)), isTrue);
    });

    test('a digit repeated inside a cage does not satisfy it', () {
      // Cells 0 and 1 hold 5 and 3; a cage of the two summing to 10 is met
      // by 5+5 only, which repeats.
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[0, 1], sum: 10),
        ..._singletonsExcept(const <int>{0, 1}),
      ]);
      final cages = (result as ValidCageSet).cages;
      expect(
        cages.isSatisfiedBy(gridOf('55${referenceSolution.substring(2)}')),
        isFalse,
      );
    });
  });

  group('a malformed cage set is a value, never an exception', () {
    test('a cell in no cage is refused', () {
      final result = CageSet.build(_singletonsExcept(const <int>{40}));
      expect(result, isA<InvalidCageSet>());
      expect((result as InvalidCageSet).problem, CageProblem.cellUncovered);
      expect(result.cell, 40);
    });

    test('a cell in two cages is refused', () {
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[0, 1], sum: 3),
        ..._singletonsExcept(const <int>{0}),
      ]);
      expect(result, isA<InvalidCageSet>());
      expect((result as InvalidCageSet).problem, CageProblem.cellInTwoCages);
      expect(result.cell, 1);
    });

    test('a cage whose cells do not touch is refused', () {
      // 0 and 2 share a row but not an edge.
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[0, 2], sum: 3),
        ..._singletonsExcept(const <int>{0, 2}),
      ]);
      expect(result, isA<InvalidCageSet>());
      expect((result as InvalidCageSet).problem, CageProblem.notConnected);
    });

    test('cells touching only at a corner are not connected', () {
      final result = CageSet.build(<Cage>[
        Cage(cells: <int>[at(0, 0), at(1, 1)], sum: 3),
        ..._singletonsExcept(<int>{at(0, 0), at(1, 1)}),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.notConnected);
    });

    test('a row end does not wrap to the next row', () {
      final result = CageSet.build(<Cage>[
        Cage(cells: <int>[at(0, 8), at(1, 0)], sum: 3),
        ..._singletonsExcept(<int>{at(0, 8), at(1, 0)}),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.notConnected);
    });

    test('a sum below the least its size allows is refused', () {
      // Two distinct digits add up to at least 1+2.
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[0, 1], sum: 2),
        ..._singletonsExcept(const <int>{0, 1}),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.sumOutOfRange);
    });

    test('a sum above the greatest its size allows is refused', () {
      // Three distinct digits add up to at most 9+8+7.
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[0, 1, 2], sum: 25),
        ..._singletonsExcept(const <int>{0, 1, 2}),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.sumOutOfRange);
    });

    test('the extremes themselves are allowed', () {
      for (final sum in const <int>[6, 24]) {
        final result = CageSet.build(<Cage>[
          Cage(cells: const <int>[0, 1, 2], sum: sum),
          ..._singletonsExcept(const <int>{0, 1, 2}),
        ]);
        expect(result, isA<ValidCageSet>(), reason: 'sum $sum');
      }
    });

    test('a cage of more than nine cells is refused', () {
      // Ten cells cannot hold ten distinct digits.
      final ten = <int>[for (var c = 0; c < 9; c++) at(0, c), at(1, 0)];
      final result = CageSet.build(<Cage>[
        Cage(cells: ten, sum: 45),
        ..._singletonsExcept(ten.toSet()),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.tooLarge);
    });

    test('an empty cage is refused', () {
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[], sum: 0),
        ..._singletonsExcept(const <int>{}),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.empty);
    });

    test('a cell off the grid is refused', () {
      final result = CageSet.build(<Cage>[
        Cage(cells: const <int>[81], sum: 5),
        ..._singletonsExcept(const <int>{}),
      ]);
      expect((result as InvalidCageSet).problem, CageProblem.cellOffGrid);
      expect(result.cell, 81);
    });
  });

  test('the least and greatest sums follow from distinct digits', () {
    expect(Cage.leastSum(1), 1);
    expect(Cage.greatestSum(1), 9);
    expect(Cage.leastSum(2), 3);
    expect(Cage.greatestSum(2), 17);
    expect(Cage.leastSum(9), 45);
    expect(Cage.greatestSum(9), 45);
  });
}

/// A single-cell cage for every cell not in [taken], each summing to 5 — any
/// digit from one to nine would do, and the tests here are about shape.
List<Cage> _singletonsExcept(Set<int> taken) => <Cage>[
  for (var cell = 0; cell < GridGeometry.cellCount; cell++)
    if (!taken.contains(cell)) Cage(cells: <int>[cell], sum: 5),
];
