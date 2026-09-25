import 'dart:ui';

import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/dashed_path.dart';
import '../../puzzle_engine/domain/cage.dart';

/// Every **cage** of [cages] as one dashed path, inset inside its cells
/// (D-129).
///
/// One definition of the outline, shared by the board and the **lesson** grid,
/// so a **lesson** points at the same shape the player will meet.
///
/// Each cell edge on a **cage**'s boundary becomes a run inset by
/// [DokuStroke.cageInset]: pulled in at a convex corner, carried to the cell
/// edge where the run continues next door, and pushed out at a concave corner
/// to meet the run it turns into. The head cell's top and left runs stop short
/// of its **cage sum** by [headClearance].
Path cageOutline(
  CageSet cages, {
  required Rect Function(int cell) cellRect,
  required ({double left, double top}) Function(int head) headClearance,
}) {
  final runs = Path();
  const inset = DokuStroke.cageInset;
  for (final cage in cages.cages) {
    final members = cage.cells.toSet();
    bool inCage(int row, int column) =>
        row >= 0 &&
        row < 9 &&
        column >= 0 &&
        column < 9 &&
        members.contains(row * 9 + column);
    double reach(bool along, bool diagonal) =>
        !along ? inset : (diagonal ? -inset : 0);

    for (final cell in cage.cells) {
      final row = cell ~/ 9;
      final column = cell % 9;
      final rect = cellRect(cell);
      final clearance = cell == cage.head ? headClearance(cell) : null;

      if (!inCage(row - 1, column)) {
        final start = clearance != null
            ? rect.left + clearance.left
            : rect.left +
                  reach(inCage(row, column - 1), inCage(row - 1, column - 1));
        final end =
            rect.right -
            reach(inCage(row, column + 1), inCage(row - 1, column + 1));
        final y = rect.top + inset;
        if (end > start) {
          runs
            ..moveTo(start, y)
            ..lineTo(end, y);
        }
      }
      if (!inCage(row + 1, column)) {
        final y = rect.bottom - inset;
        runs
          ..moveTo(
            rect.left +
                reach(inCage(row, column - 1), inCage(row + 1, column - 1)),
            y,
          )
          ..lineTo(
            rect.right -
                reach(inCage(row, column + 1), inCage(row + 1, column + 1)),
            y,
          );
      }
      if (!inCage(row, column - 1)) {
        final start = clearance != null
            ? rect.top + clearance.top
            : rect.top +
                  reach(inCage(row - 1, column), inCage(row - 1, column - 1));
        final end =
            rect.bottom -
            reach(inCage(row + 1, column), inCage(row + 1, column - 1));
        final x = rect.left + inset;
        if (end > start) {
          runs
            ..moveTo(x, start)
            ..lineTo(x, end);
        }
      }
      if (!inCage(row, column + 1)) {
        final x = rect.right - inset;
        runs
          ..moveTo(
            x,
            rect.top +
                reach(inCage(row - 1, column), inCage(row - 1, column + 1)),
          )
          ..lineTo(
            x,
            rect.bottom -
                reach(inCage(row + 1, column), inCage(row + 1, column + 1)),
          );
      }
    }
  }
  return dashedPath(
    runs,
    on: DokuStroke.cageDashOn,
    off: DokuStroke.cageDashOff,
  );
}
