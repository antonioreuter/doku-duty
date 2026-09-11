import 'package:flutter/widgets.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/domain/season_theme.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';
import '../../design_system/domain/note_ink.dart';
import '../domain/board.dart';
import '../domain/note_set.dart';
import 'grid_metrics.dart';

/// The colours the grid draws with, resolved once.
///
/// A value so the painter can compare it in `shouldRepaint`. State colours are
/// fixed across every season (D-55), so only the surfaces move.
final class GridColours {
  const GridColours({
    required this.cell,
    required this.hairline,
    required this.divider,
    required this.given,
    required this.placed,
    required this.focusFill,
    required this.focusLine,
    required this.candidateFill,
    required this.settledNote,
  });

  /// The grid as [palette] paints it.
  ///
  /// Surfaces move with the season; the focus and ink colours do not (D-55).
  /// A season that repainted selection would have players relearning the board
  /// nine times a year.
  factory GridColours.forSeason(SeasonPalette palette) => GridColours(
    cell: palette.colourOf(PaletteToken.bone),
    hairline: palette.paleColourOf(PaletteToken.sand)!,
    divider: DokuColours.duskInk,
    given: DokuColours.duskInk,
    placed: DokuColours.inkSoft,
    focusFill: PaletteToken.badgeGold.paleColour!,
    focusLine: DokuColours.badgeGold,
    candidateFill: PaletteToken.nightIndigo.paleColour!,
    settledNote: NoteInk.settled.token.colour,
  );

  /// The default season's grid.
  factory GridColours.standard() => GridColours(
    cell: DokuColours.bone,
    hairline: DokuColours.hairline,
    divider: DokuColours.duskInk,
    given: DokuColours.duskInk,
    placed: DokuColours.inkSoft,
    // Selection and peer highlighting are two depths of one hue, never two
    // hues (D-53, constraint 4).
    focusFill: PaletteToken.badgeGold.paleColour!,
    focusLine: DokuColours.badgeGold,
    // **Candidate highlighting** is the candidate token paled, the tint
    // `docs/DESIGN.md` §2 already names for it — not a ninth hue
    // (constraint 4).
    candidateFill: PaletteToken.nightIndigo.paleColour!,
    settledNote: NoteInk.settled.token.colour,
  );

  final Color cell;
  final Color hairline;
  final Color divider;
  final Color given;
  final Color placed;
  final Color focusFill;
  final Color focusLine;

  /// The cell behind a digit **candidate highlighting** is lighting.
  ///
  /// Sits below [focusFill] in the D-49 priority order: the player's current
  /// focus always wins where highlights compete.
  final Color candidateFill;

  /// A **settled note**. One ink; the candidate's *position* carries its
  /// identity, so colour is never the only signal (constraint 5).
  final Color settledNote;

  @override
  bool operator ==(Object other) =>
      other is GridColours &&
      other.cell == cell &&
      other.hairline == hairline &&
      other.divider == divider &&
      other.given == given &&
      other.placed == placed &&
      other.focusFill == focusFill &&
      other.focusLine == focusLine &&
      other.candidateFill == candidateFill &&
      other.settledNote == settledNote;

  @override
  int get hashCode => Object.hash(
    cell,
    hairline,
    divider,
    given,
    placed,
    focusFill,
    focusLine,
    candidateFill,
    settledNote,
  );
}

/// Which of the three inks a glyph is drawn in.
enum _InkKind { given, placed, note }

/// Draws the board on one canvas (D-31).
///
/// One painter rather than eighty-one widgets, because a tap has to repaint
/// inside the 100ms budget and rebuilding a tree of eighty-one cells to move a
/// selection does not. The digit painters are laid out once per instance —
/// there are only eighteen of them, nine digits in two weights — so a repaint
/// is drawing, never text layout.
class GridPainter extends CustomPainter {
  GridPainter({
    required this.board,
    required this.selectedCell,
    required this.textScale,
    required this.colours,
    this.highlightedDigit,
  });

  final Board board;

  /// The cell the player has selected, or null for none.
  final int? selectedCell;

  /// The digit **candidate highlighting** is lighting cells for, or null.
  ///
  /// Cells carrying it as a candidate *or* as a value are lit — highlighting
  /// shows where a digit already is, which is what makes a pointing pair
  /// visible rather than deduced by squinting (D-13).
  final int? highlightedDigit;

  final double textScale;
  final GridColours colours;

  /// Givens are drawn heavier than the player's own digits, so the two are
  /// told apart by weight alone and colour is never the only signal
  /// (constraint 5).
  static const FontWeight givenWeight = FontWeight.w600;
  static const FontWeight placedWeight = FontWeight.w400;

  final Map<int, TextPainter> _givenDigits = <int, TextPainter>{};
  final Map<int, TextPainter> _placedDigits = <int, TextPainter>{};
  final Map<int, TextPainter> _noteDigits = <int, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = GridMetrics.fit(size);
    _paintSurface(canvas, metrics);
    _paintHighlight(canvas, metrics);
    _paintFocus(canvas, metrics);
    _paintLines(canvas, metrics);
    _paintNotes(canvas, metrics);
    _paintDigits(canvas, metrics);
    _paintFrame(canvas, metrics);
  }

  void _paintSurface(Canvas canvas, GridMetrics metrics) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        metrics.bounds,
        const Radius.circular(DokuRadius.gridOuter),
      ),
      Paint()..color = colours.cell,
    );
  }

  /// Every cell holding [highlightedDigit], as a candidate or as a value.
  ///
  /// Painted before the focus so the focus lands on top: where the two compete
  /// the player's current selection wins (D-49). Colour is never the only
  /// signal here — a lit cell holds the digit it is lit for, which is the whole
  /// point of lighting it (constraint 5).
  void _paintHighlight(Canvas canvas, GridMetrics metrics) {
    final digit = highlightedDigit;
    if (digit == null) return;

    final fill = Paint()..color = colours.candidateFill;
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final holdsIt =
          board.digitAt(cell) == digit || board.notesAt(cell).contains(digit);
      if (holdsIt) canvas.drawRect(metrics.cellRect(cell), fill);
    }
  }

  /// The selected cell and the cells it shares a **unit** with.
  ///
  /// Both are the same fill; the selected cell is told apart by its border, so
  /// the distinction survives without colour at all (constraint 5).
  void _paintFocus(Canvas canvas, GridMetrics metrics) {
    final selected = selectedCell;
    if (selected == null) return;

    final fill = Paint()..color = colours.focusFill;
    for (final peer in GridGeometry.peersOf(selected)) {
      canvas.drawRect(metrics.cellRect(peer), fill);
    }
    canvas.drawRect(metrics.cellRect(selected), fill);

    canvas.drawRect(
      metrics.cellRect(selected).deflate(DokuStroke.interiorDetail / 2),
      Paint()
        ..color = colours.focusLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = DokuStroke.interiorDetail,
    );
  }

  void _paintLines(Canvas canvas, GridMetrics metrics) {
    final hairline = Paint()
      ..color = colours.hairline
      ..strokeWidth = DokuStroke.gridCellHairline;
    final divider = Paint()
      ..color = colours.divider
      ..strokeWidth = DokuStroke.gridBoxDivider;

    for (var i = 1; i < 9; i++) {
      final offset = i * metrics.cellSize;
      final paint = i % 3 == 0 ? divider : hairline;
      canvas.drawLine(
        Offset(metrics.origin.dx + offset, metrics.origin.dy),
        Offset(metrics.origin.dx + offset, metrics.origin.dy + metrics.side),
        paint,
      );
      canvas.drawLine(
        Offset(metrics.origin.dx, metrics.origin.dy + offset),
        Offset(metrics.origin.dx + metrics.side, metrics.origin.dy + offset),
        paint,
      );
    }
  }

  /// The candidates, each in the slot its digit owns (D-10, constraint 3).
  ///
  /// The slot comes from [NoteSet.slotOf] — a pure function of the digit — so a
  /// candidate cannot move because another was removed, whatever order they
  /// were marked in and however many the cell holds. There is no layout pass
  /// here to get wrong.
  void _paintNotes(Canvas canvas, GridMetrics metrics) {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final notes = board.notesAt(cell);
      if (notes.isEmpty) continue;

      final rect = metrics.cellRect(cell);
      final slot = rect.width / 3;
      for (final digit in notes.digits) {
        final position = NoteSet.slotOf(digit);
        final painter = _digitPainter(_noteDigits, digit, kind: _InkKind.note);
        final centre = Offset(
          rect.left + (position.column + 0.5) * slot,
          rect.top + (position.row + 0.5) * slot,
        );
        painter.paint(
          canvas,
          Offset(centre.dx - painter.width / 2, centre.dy - painter.height / 2),
        );
      }
    }
  }

  void _paintDigits(Canvas canvas, GridMetrics metrics) {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final digit = board.digitAt(cell);
      if (digit == Board.empty) continue;

      final painter = board.isGiven(cell)
          ? _digitPainter(_givenDigits, digit, kind: _InkKind.given)
          : _digitPainter(_placedDigits, digit, kind: _InkKind.placed);
      final rect = metrics.cellRect(cell);
      painter.paint(
        canvas,
        Offset(
          rect.center.dx - painter.width / 2,
          rect.center.dy - painter.height / 2,
        ),
      );
    }
  }

  /// Givens are heavier and darker; placed values are lighter in both.
  ///
  /// Weight carries the distinction on its own, so it survives without colour
  /// (constraint 5). The tone follows it rather than replacing it.
  TextPainter _digitPainter(
    Map<int, TextPainter> cache,
    int digit, {
    required _InkKind kind,
  }) => cache.putIfAbsent(digit, () {
    final role = kind == _InkKind.note ? TypeRole.gridNote : TypeRole.gridValue;
    return TextPainter(
      text: TextSpan(
        text: '$digit',
        style: role
            .scaled(textScale)
            .copyWith(
              color: switch (kind) {
                _InkKind.given => colours.given,
                _InkKind.placed => colours.placed,
                _InkKind.note => colours.settledNote,
              },
              fontWeight: kind == _InkKind.given ? givenWeight : placedWeight,
            ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
  });

  void _paintFrame(Canvas canvas, GridMetrics metrics) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        metrics.bounds.deflate(DokuStroke.outerContour / 2),
        const Radius.circular(DokuRadius.gridOuter),
      ),
      Paint()
        ..color = colours.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = DokuStroke.outerContour,
    );
  }

  /// Repaint only when something visible moved.
  ///
  /// Returning true unconditionally is how the latency budget is lost with
  /// nothing looking wrong: every unrelated rebuild would redraw the board.
  @override
  bool shouldRepaint(GridPainter old) =>
      old.board != board ||
      old.selectedCell != selectedCell ||
      old.highlightedDigit != highlightedDigit ||
      old.textScale != textScale ||
      old.colours != colours;
}
