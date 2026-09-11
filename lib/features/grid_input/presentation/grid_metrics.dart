import 'dart:ui';

/// Where the grid sits and how big a cell is.
///
/// Split out of the painter so hit-testing and painting agree by construction:
/// a tap is turned into a cell by the same arithmetic that drew it, rather than
/// by a second copy of the layout that can drift.
final class GridMetrics {
  const GridMetrics({required this.origin, required this.side});

  /// The largest square that fits [size], centred in it.
  ///
  /// The grid takes the width it is given (D-84). Nine 44pt cells would need
  /// 396pt before any gutter, which most phones do not have.
  factory GridMetrics.fit(Size size) {
    final side = size.shortestSide;
    return GridMetrics(
      origin: Offset((size.width - side) / 2, (size.height - side) / 2),
      side: side,
    );
  }

  /// Top-left of the square.
  final Offset origin;

  /// Length of one edge.
  final double side;

  double get cellSize => side / 9;

  Rect get bounds => Rect.fromLTWH(origin.dx, origin.dy, side, side);

  Rect cellRect(int cell) => Rect.fromLTWH(
    origin.dx + (cell % 9) * cellSize,
    origin.dy + (cell ~/ 9) * cellSize,
    cellSize,
    cellSize,
  );

  /// The cell under [position], or null when it falls outside the grid.
  ///
  /// Arithmetic on the offset, not eighty-one hit-test regions: this runs on
  /// every tap and the whole change is measured against constraint 2.
  int? cellAt(Offset position) {
    if (!bounds.contains(position)) return null;
    final column = ((position.dx - origin.dx) / cellSize).floor().clamp(0, 8);
    final row = ((position.dy - origin.dy) / cellSize).floor().clamp(0, 8);
    return row * 9 + column;
  }

  @override
  bool operator ==(Object other) =>
      other is GridMetrics && other.origin == origin && other.side == side;

  @override
  int get hashCode => Object.hash(origin, side);
}
