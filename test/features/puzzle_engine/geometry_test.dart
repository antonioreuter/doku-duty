import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

void main() {
  test('a cell belongs to exactly three units, each holding nine cells', () {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final units = GridGeometry.unitsOf(cell);
      expect(units, hasLength(3));
      expect(units.map((unit) => unit.kind), <UnitKind>[
        UnitKind.row,
        UnitKind.column,
        UnitKind.block,
      ]);
      for (final unit in units) {
        expect(unit.cells, hasLength(9));
        expect(unit.cells, contains(cell));
      }
    }
  });

  test(
    'there are twenty-seven units, and every cell appears once in each kind',
    () {
      expect(GridGeometry.allUnits, hasLength(27));
      for (final kind in UnitKind.values) {
        final ofKind = GridGeometry.allUnits.where((u) => u.kind == kind);
        expect(ofKind, hasLength(9));
        final seen = ofKind.expand((u) => u.cells).toList()..sort();
        expect(seen, List<int>.generate(GridGeometry.cellCount, (i) => i));
      }
    },
  );

  // The classic off-by-one is counting the cell itself, or counting the four
  // cells shared by the row and the block twice.
  test('a cell has exactly twenty peers, each listed once', () {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final peers = GridGeometry.peersOf(cell);
      expect(peers, hasLength(20), reason: 'cell $cell');
      expect(
        peers.toSet(),
        hasLength(20),
        reason: 'cell $cell has a duplicate',
      );
      expect(peers, isNot(contains(cell)));
      for (final peer in peers) {
        expect(GridGeometry.peersOf(peer), contains(cell));
      }
    }
  });

  test('peers are exactly the cells sharing a unit', () {
    const cell = 40; // the centre cell
    final sharing = <int>{
      for (final unit in GridGeometry.unitsOf(cell)) ...unit.cells,
    }..remove(cell);
    expect(GridGeometry.peersOf(cell).toSet(), sharing);
  });

  test('row, column, and block indices agree with the flat cell index', () {
    expect(GridGeometry.rowOf(0), 0);
    expect(GridGeometry.columnOf(0), 0);
    expect(GridGeometry.blockOf(0), 0);
    expect(GridGeometry.rowOf(80), 8);
    expect(GridGeometry.columnOf(80), 8);
    expect(GridGeometry.blockOf(80), 8);
    expect(GridGeometry.blockOf(30), 4);
    expect(GridGeometry.cellAt(row: 3, column: 3), 30);
  });

  test('the same tables are handed out every time rather than rebuilt', () {
    expect(
      identical(GridGeometry.peersOf(17), GridGeometry.peersOf(17)),
      isTrue,
    );
    expect(
      identical(GridGeometry.unitsOf(17), GridGeometry.unitsOf(17)),
      isTrue,
    );
  });
}
