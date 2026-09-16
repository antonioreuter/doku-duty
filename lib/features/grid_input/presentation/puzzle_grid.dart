import 'package:flutter/widgets.dart';

import '../domain/board.dart';
import 'grid_metrics.dart';
import 'grid_painter.dart';

/// The board, drawn and tappable.
///
/// The only widget in the grid. Hit-testing is arithmetic on the tap offset
/// against the same [GridMetrics] the painter drew with, so the two cannot
/// disagree about where a cell is.
class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({
    required this.board,
    required this.onCellTapped,
    this.selectedCell,
    this.highlightedDigit,
    this.flaggedCells = const <int>{},
    this.colours,
    super.key,
  });

  final Board board;

  /// The cell the player has selected, or null.
  final int? selectedCell;

  /// The digit **candidate highlighting** is lighting cells for, or null.
  final int? highlightedDigit;

  /// The cells **strict mode** has flagged, or empty when stakes are off.
  final Set<int> flaggedCells;

  /// Called with the cell under the tap. A tap outside the grid calls nothing.
  final ValueChanged<int> onCellTapped;

  /// Overridden by tests and by a season that repaints surfaces.
  final GridColours? colours;

  @override
  Widget build(BuildContext context) {
    final resolved = colours ?? GridColours.standard();
    final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final metrics = GridMetrics.fit(size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // onTapUp rather than onTap: the cell is decided from where the
          // finger was, and waiting for the tap to be recognised as distinct
          // from a double tap would cost the budget in constraint 2.
          onTapUp: (details) {
            final cell = metrics.cellAt(details.localPosition);
            if (cell != null) onCellTapped(cell);
          },
          child: CustomPaint(
            size: size,
            painter: GridPainter(
              board: board,
              selectedCell: selectedCell,
              highlightedDigit: highlightedDigit,
              flaggedCells: flaggedCells,
              textScale: textScale,
              colours: resolved,
            ),
          ),
        );
      },
    );
  }
}
