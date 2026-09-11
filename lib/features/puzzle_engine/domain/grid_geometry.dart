/// The fixed shape of a sudoku grid: which cells make up which **unit**, and
/// which cells a given cell shares a **unit** with.
///
/// Every table here is the same for every puzzle ever played, so it is built
/// once at first use rather than derived per query. The solver walks these
/// tables tens of thousands of times while grading a single puzzle.
library;

/// The three kinds of **unit** a cell belongs to.
enum UnitKind { row, column, block }

/// One of the twenty-seven **units**: nine cells that must hold each digit once.
final class Unit {
  const Unit({required this.kind, required this.index, required this.cells});

  final UnitKind kind;

  /// Which row, column, or block this is, zero-based.
  final int index;

  /// The nine cells, in flat index order.
  final List<int> cells;

  @override
  String toString() => '${kind.name} $index';
}

/// Cell indices run 0..80, row-major: cell = row * 9 + column.
abstract final class GridGeometry {
  static const int side = 9;
  static const int cellCount = 81;

  /// Digits are 1..9; zero is the engine's blank.
  static const int minDigit = 1;
  static const int maxDigit = 9;

  static int rowOf(int cell) => cell ~/ side;

  static int columnOf(int cell) => cell % side;

  static int blockOf(int cell) => (rowOf(cell) ~/ 3) * 3 + columnOf(cell) ~/ 3;

  static int cellAt({required int row, required int column}) =>
      row * side + column;

  /// All twenty-seven **units**: the nine rows, then the columns, then the
  /// blocks.
  static List<Unit> get allUnits => _allUnits;

  /// The nine **units** of one kind, indexed by their own position.
  static List<Unit> unitsOfKind(UnitKind kind) => _byKind[kind.index];

  /// The three **units** containing [cell]: its row, its column, its block.
  static List<Unit> unitsOf(int cell) => _unitsByCell[cell];

  /// The twenty cells sharing a **unit** with [cell], each listed once and
  /// never including [cell] itself.
  static List<int> peersOf(int cell) => _peersByCell[cell];

  static final List<Unit> _allUnits = List<Unit>.unmodifiable(<Unit>[
    for (var row = 0; row < side; row++)
      Unit(
        kind: UnitKind.row,
        index: row,
        cells: List<int>.unmodifiable(<int>[
          for (var column = 0; column < side; column++)
            cellAt(row: row, column: column),
        ]),
      ),
    for (var column = 0; column < side; column++)
      Unit(
        kind: UnitKind.column,
        index: column,
        cells: List<int>.unmodifiable(<int>[
          for (var row = 0; row < side; row++) cellAt(row: row, column: column),
        ]),
      ),
    for (var block = 0; block < side; block++)
      Unit(
        kind: UnitKind.block,
        index: block,
        cells: List<int>.unmodifiable(<int>[
          for (var offset = 0; offset < side; offset++)
            cellAt(
              row: (block ~/ 3) * 3 + offset ~/ 3,
              column: (block % 3) * 3 + offset % 3,
            ),
        ]),
      ),
  ]);

  static final List<List<Unit>> _byKind =
      List<List<Unit>>.unmodifiable(<List<Unit>>[
        for (final kind in UnitKind.values)
          List<Unit>.unmodifiable(_allUnits.where((unit) => unit.kind == kind)),
      ]);

  static final List<List<Unit>> _unitsByCell = List<List<Unit>>.unmodifiable(
    <List<Unit>>[
      for (var cell = 0; cell < cellCount; cell++)
        List<Unit>.unmodifiable(<Unit>[
          _byKind[UnitKind.row.index][rowOf(cell)],
          _byKind[UnitKind.column.index][columnOf(cell)],
          _byKind[UnitKind.block.index][blockOf(cell)],
        ]),
    ],
  );

  // A set, then sorted: the four cells a row and a block share would otherwise
  // be counted twice, which is the classic way this table comes out at 24.
  static final List<List<int>> _peersByCell = List<List<int>>.unmodifiable(
    <List<int>>[
      for (var cell = 0; cell < cellCount; cell++)
        List<int>.unmodifiable(
          <int>{for (final unit in _unitsByCell[cell]) ...unit.cells}
            ..remove(cell),
        ),
    ],
  );
}
