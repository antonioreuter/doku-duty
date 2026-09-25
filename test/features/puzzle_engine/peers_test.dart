import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/cage.dart';
import 'package:doku_duty/features/puzzle_engine/domain/candidates.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';
import 'package:doku_duty/features/puzzle_engine/domain/peers.dart';

import 'support/killer.dart';
import 'support/positions.dart';

void main() {
  test('a classic puzzle\'s peers are exactly the unit table, for all 81 '
      'cells', () {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      expect(Peers.classic.of(cell), GridGeometry.peersOf(cell));
      expect(Peers.of(null).of(cell), GridGeometry.peersOf(cell));
    }
  });

  test('a killer puzzle\'s peers are the twenty plus every cage mate, each '
      'listed once', () {
    // A cage bending across a block boundary: r1c3, r1c4, r2c4. r2c4 shares no
    // unit with r1c3, so only the cage makes them peers.
    final bend = <int>[at(0, 2), at(0, 3), at(1, 3)];
    final result = CageSet.build(<Cage>[
      Cage(cells: bend, sum: 6),
      for (var cell = 0; cell < GridGeometry.cellCount; cell++)
        if (!bend.contains(cell)) Cage(cells: <int>[cell], sum: 5),
    ]);
    final peers = Peers.of((result as ValidCageSet).cages);

    final corner = peers.of(at(0, 2));
    expect(corner.toSet(), <int>{...GridGeometry.peersOf(at(0, 2)), at(1, 3)});
    expect(corner, hasLength(21));
    expect(corner.toSet(), hasLength(corner.length), reason: 'no duplicates');
    expect(corner, isNot(contains(at(0, 2))));

    // r1c4 already shares its row with r1c3 and its block with r2c4.
    expect(peers.of(at(0, 3)), hasLength(20));
    // A cell in no multi-cell cage keeps exactly its twenty.
    expect(peers.of(at(8, 8)).toSet(), GridGeometry.peersOf(at(8, 8)).toSet());
  });

  test('killer peers are symmetric and never include the cell', () {
    final peers = Peers.of(dominoCages(referenceSolution));
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final mine = peers.of(cell);
      expect(mine, isNot(contains(cell)));
      for (final peer in mine) {
        expect(peers.of(peer), contains(cell));
      }
    }
  });

  test('a cage mate\'s value is not a candidate', () {
    final bend = <int>[at(0, 2), at(0, 3), at(1, 3)];
    final result = CageSet.build(<Cage>[
      Cage(cells: bend, sum: 15),
      for (var cell = 0; cell < GridGeometry.cellCount; cell++)
        if (!bend.contains(cell)) Cage(cells: <int>[cell], sum: 5),
    ]);
    final peers = Peers.of((result as ValidCageSet).cages);
    final grid = Grid.empty.withDigit(at(1, 3), 7);

    expect(grid.candidatesAt(at(0, 2), peers: peers).contains(7), isFalse);
    // Classic reading of the same grid: r2c4 is no peer of r1c3.
    expect(grid.candidatesAt(at(0, 2)).contains(7), isTrue);
  });

  test('candidates never exclude a digit by arithmetic', () {
    // A two-cell cage of 3 can only be {1,2}; that is a deduction, not a
    // legal-move check, so all nine stay.
    final result = CageSet.build(<Cage>[
      Cage(cells: const <int>[0, 1], sum: 3),
      for (var cell = 2; cell < GridGeometry.cellCount; cell++)
        Cage(cells: <int>[cell], sum: 5),
    ]);
    final peers = Peers.of((result as ValidCageSet).cages);
    expect(Grid.empty.candidatesAt(0, peers: peers), Candidates.all);
  });

  test('the same table is handed out every time rather than rebuilt', () {
    final peers = Peers.of(dominoCages(referenceSolution));
    expect(identical(peers.of(17), peers.of(17)), isTrue);
  });
}
