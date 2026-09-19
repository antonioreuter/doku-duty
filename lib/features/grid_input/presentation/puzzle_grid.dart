import 'package:flutter/widgets.dart';

import '../../completion_effects/domain/effect_frame.dart';
import '../../completion_effects/domain/unit_completion.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';
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
    this.completedCells = const <int>{},
    this.freshCells = const <int>{},
    this.showCompletionTints = true,
    this.effects = EffectFrame.empty,
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

  /// Every cell in a complete **unit**, derived from the board.
  final Set<int> completedCells;

  /// The cells still holding the fresh-completion flash.
  final Set<int> freshCells;

  /// Whether the **completion tint** is drawn. The **corner mark**s are drawn
  /// either way (D-50).
  final bool showCompletionTints;

  /// Whatever is celebrating right now, as a snapshot to draw.
  final EffectFrame effects;

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

        return Semantics(
          // Completion has to be readable by someone who cannot see the grid
          // at all, not only by someone who cannot separate the hue from the
          // surface. The tint is colour and the **corner mark** is geometry;
          // this is the third form, and it is the one a screen reader gets.
          //
          // A count rather than a list of which ones. Twenty-seven **unit**
          // names read aloud on every repaint would be unusable, and the fact
          // the player wants is how much of the board is settled.
          label: _completionLabel,
          child: GestureDetector(
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
                completedCells: completedCells,
                freshCells: freshCells,
                showCompletionTints: showCompletionTints,
                effects: effects,
                textScale: textScale,
                colours: resolved,
              ),
            ),
          ),
        );
      },
    );
  }

  /// How much of the board is settled, in words.
  ///
  /// Says nothing about *which* **unit**s, and nothing about correctness. The
  /// same fact the tint and the **corner mark** carry, in the one form that
  /// reaches a player who cannot see either (constraint 5).
  String get _completionLabel {
    // Asked of the board rather than counted off [completedCells]. A cell can
    // be in that set because some *other* **unit** it belongs to is complete,
    // so counting units whose cells all appear there would overstate — three
    // complete rows put every cell of the top-left block in the set whether or
    // not the block itself holds nine distinct digits.
    final complete = GridGeometry.allUnits
        .where((unit) => UnitCompletion.isComplete(board, unit))
        .length;
    if (complete == 0) return 'Sudoku grid';
    if (complete == 1) return 'Sudoku grid, 1 of 27 groups complete';
    return 'Sudoku grid, $complete of 27 groups complete';
  }
}
