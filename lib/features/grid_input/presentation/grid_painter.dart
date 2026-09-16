import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
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
    required this.flaggedFill,
    required this.errorMark,
    required this.settledNote,
    required this.provisionalNote,
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
    flaggedFill: PaletteToken.sunsetRed.paleColour!,
    errorMark: DokuColours.sunsetRed,
    settledNote: NoteInk.settled.token.colour,
    provisionalNote: NoteInk.provisional.token.colour,
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
    // The tint `docs/DESIGN.md` §2 already names for a flagged cell, and the
    // error token beside it — not a ninth hue (constraint 4).
    flaggedFill: PaletteToken.sunsetRed.paleColour!,
    errorMark: DokuColours.sunsetRed,
    settledNote: NoteInk.settled.token.colour,
    provisionalNote: NoteInk.provisional.token.colour,
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

  /// The cell behind a value **strict mode** has flagged as disagreeing with
  /// the solution.
  ///
  /// Sits *below* [candidateFill] and [focusFill] in the D-49 priority order:
  /// selection, then **candidate highlighting**, then this.
  final Color flaggedFill;

  /// The strike drawn through a flagged value.
  ///
  /// Never the only signal. The fill beside it says the same thing in colour,
  /// and this says it in geometry — a player who cannot separate the error hue
  /// from the ink reads the strike (constraint 5).
  final Color errorMark;

  /// A **settled note**. The candidate's *position* carries its identity, so
  /// colour is never the only signal (constraint 5).
  final Color settledNote;

  /// A **provisional note** — a hypothesis under test (D-11).
  ///
  /// Never drawn alone. The two note inks sit 1.33:1 apart in normal vision and
  /// **1.07:1 under deuteranopia**, so for roughly one man in twelve they are
  /// the same mark and this colour says nothing. The underline beside it is
  /// what actually carries the distinction (D-73).
  final Color provisionalNote;

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
      other.flaggedFill == flaggedFill &&
      other.errorMark == errorMark &&
      other.settledNote == settledNote &&
      other.provisionalNote == provisionalNote;

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
    flaggedFill,
    errorMark,
    settledNote,
    provisionalNote,
  );
}

/// Which of the three inks a glyph is drawn in.
enum _InkKind { given, placed, note, provisionalNote }

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
    this.flaggedCells = const <int>{},
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

  /// The cells **strict mode** has flagged as disagreeing with the solution.
  ///
  /// Empty whenever stakes are off, which is what makes a wrong digit look
  /// exactly like a right one by default (D-04). The painter is told which
  /// cells rather than the solution: what a digit *should* be is not something
  /// the renderer is allowed to know.
  final Set<int> flaggedCells;

  final double textScale;
  final GridColours colours;

  /// Givens are drawn heavier than the player's own digits, so the two are
  /// told apart by weight alone and colour is never the only signal
  /// (constraint 5).
  static const FontWeight givenWeight = FontWeight.w600;
  static const FontWeight placedWeight = FontWeight.w400;

  /// The grid size the caches were laid out for.
  ///
  /// The cap depends on the cell, so a resize without a rebuild — a rotation,
  /// a split-screen drag — has to throw the glyphs away rather than keep ones
  /// measured against a box that no longer exists.
  Size? _laidOutFor;

  final Map<int, TextPainter> _givenDigits = <int, TextPainter>{};
  final Map<int, TextPainter> _placedDigits = <int, TextPainter>{};
  final Map<int, TextPainter> _noteDigits = <int, TextPainter>{};
  final Map<int, TextPainter> _provisionalDigits = <int, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = GridMetrics.fit(size);
    if (_laidOutFor != size) {
      _givenDigits.clear();
      _placedDigits.clear();
      _noteDigits.clear();
      _provisionalDigits.clear();
      _laidOutFor = size;
    }
    _paintSurface(canvas, metrics);
    _paintFlags(canvas, metrics);
    _paintHighlight(canvas, metrics);
    _paintFocus(canvas, metrics);
    _paintLines(canvas, metrics);
    _paintNotes(canvas, metrics);
    _paintDigits(canvas, metrics);
    _paintStrikes(canvas, metrics);
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

  /// The cells **strict mode** has flagged.
  ///
  /// Painted before the highlight and the focus so both land on top of it:
  /// selection, then **candidate highlighting**, then this (D-49). A player
  /// moving around the board sees where they are before they see what is
  /// wrong, which is the right way round — the flag is not going anywhere.
  void _paintFlags(Canvas canvas, GridMetrics metrics) {
    if (flaggedCells.isEmpty) return;

    final fill = Paint()..color = colours.flaggedFill;
    for (final cell in flaggedCells) {
      canvas.drawRect(metrics.cellRect(cell), fill);
    }
  }

  /// A strike through each flagged value.
  ///
  /// **This is the signal, and the colour is the convenience** (constraint 5).
  /// Painted after the digits so it lies over the glyph, and sized from the
  /// cell rather than from a constant so it holds at every text size (D-92).
  void _paintStrikes(Canvas canvas, GridMetrics metrics) {
    if (flaggedCells.isEmpty) return;

    final stroke = Paint()
      ..color = colours.errorMark
      ..strokeWidth = DokuStroke.interiorDetail
      ..strokeCap = StrokeCap.round;
    for (final cell in flaggedCells) {
      final rect = metrics.cellRect(cell);
      final inset = rect.width / 4;
      canvas.drawLine(
        Offset(rect.left + inset, rect.center.dy),
        Offset(rect.right - inset, rect.center.dy),
        stroke,
      );
    }
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
        final isProvisional = notes.isProvisional(digit);
        final painter = isProvisional
            ? _digitPainter(
                _provisionalDigits,
                digit,
                kind: _InkKind.provisionalNote,
                box: slot,
              )
            : _digitPainter(_noteDigits, digit, kind: _InkKind.note, box: slot);
        final centre = Offset(
          rect.left + (position.column + 0.5) * slot,
          rect.top + (position.row + 0.5) * slot,
        );
        final origin = Offset(
          centre.dx - painter.width / 2,
          centre.dy - painter.height / 2,
        );
        painter.paint(canvas, origin);

        if (isProvisional) {
          _paintUnderline(
            canvas,
            painter,
            origin,
            Rect.fromLTWH(
              rect.left + position.column * slot,
              rect.top + position.row * slot,
              slot,
              slot,
            ),
          );
        }
      }
    }
  }

  /// The rule that separates the two note inks without using colour (D-73).
  ///
  /// The hue cannot carry this on its own: dark enough to be legible at 11px,
  /// `turquoise` lands 1.07:1 from `nightIndigo` under deuteranopia. The rule
  /// is the signal, and constraint 5 is why it exists rather than a second,
  /// lighter hue.
  ///
  /// Drawn *below* the glyph's baseline and clamped inside the candidate's own
  /// third of the cell, so the digit occupies the slot its digit owns whichever
  /// ink it is in and a re-inking moves nothing (D-10, constraint 3).
  void _paintUnderline(
    Canvas canvas,
    TextPainter painter,
    Offset origin,
    Rect slotRect,
  ) {
    final y = math.min(
      origin.dy + painter.height + provisionalUnderlineOffset,
      slotRect.bottom - provisionalUnderlineWeight,
    );
    // Clamped to the slot in both directions, not only downward. At the largest
    // dynamic type the glyph itself is wider than its slot — a defect that
    // predates this change and belongs to the grid, not the rule — and an
    // unclamped rule would follow it out and start reading as belonging to the
    // candidate next door.
    final left = math.max(origin.dx, slotRect.left);
    final right = math.min(origin.dx + painter.width, slotRect.right);
    if (right <= left) return;

    canvas.drawLine(
      Offset(left, y),
      Offset(right, y),
      Paint()
        ..color = colours.provisionalNote
        ..strokeWidth = provisionalUnderlineWeight,
    );
  }

  void _paintDigits(Canvas canvas, GridMetrics metrics) {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final digit = board.digitAt(cell);
      if (digit == Board.empty) continue;

      final rect = metrics.cellRect(cell);
      final painter = board.isGiven(cell)
          ? _digitPainter(
              _givenDigits,
              digit,
              kind: _InkKind.given,
              box: rect.width,
            )
          : _digitPainter(
              _placedDigits,
              digit,
              kind: _InkKind.placed,
              box: rect.width,
            );
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
  ///
  /// **Capped to [box].** Dynamic type is respected everywhere
  /// (`docs/DESIGN.md` §2) and nothing here pins a size — but a sudoku grid
  /// cannot reflow, so the glyph grows with the setting only until it fills the
  /// cell or the slot it sits in, and then stops (D-92).
  TextPainter _digitPainter(
    Map<int, TextPainter> cache,
    int digit, {
    required _InkKind kind,
    required double box,
  }) => cache.putIfAbsent(digit, () {
    final role = switch (kind) {
      _InkKind.note || _InkKind.provisionalNote => TypeRole.gridNote,
      _InkKind.given || _InkKind.placed => TypeRole.gridValue,
    };
    final style = role
        .scaled(textScale)
        .copyWith(
          color: switch (kind) {
            _InkKind.given => colours.given,
            _InkKind.placed => colours.placed,
            _InkKind.note => colours.settledNote,
            _InkKind.provisionalNote => colours.provisionalNote,
          },
          fontWeight: kind == _InkKind.given ? givenWeight : placedWeight,
        );

    TextPainter laidOut(TextStyle style) => TextPainter(
      text: TextSpan(text: '$digit', style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final painter = laidOut(style);

    // Width is measured; height is the em box, not `painter.height`.
    //
    // A laid-out line is about 1.36em tall in Nunito and most of the extra is
    // empty leading above and below the digit's ink — at the default scale a
    // note's line box is already 15px in a 13.3px slot while the digit inside
    // it sits comfortably. Capping on that number shrinks type that visibly
    // fits. The em box bounds the ink from above (a digit has cap height and
    // no descender, so its ink is always shorter than its em) without
    // depending on any one face's metrics, which a tuned constant would
    // (D-74).
    final overflow = math.max(painter.width, style.fontSize!) / box;
    if (overflow <= 1) return painter;

    return laidOut(style.copyWith(fontSize: style.fontSize! / overflow));
  });

  /// What a **settled note** glyph actually occupies: its measured width and
  /// its em box. Tests only.
  ///
  /// The em rather than `TextPainter.height`, for the reason [_digitPainter]
  /// caps on: the laid-out line is mostly empty leading, so its height is not
  /// what a reader sees and not what has to fit.
  @visibleForTesting
  ({double width, double em}) debugNoteGlyphBox(int digit) =>
      _boxOf(_noteDigits[digit]!);

  /// The same, for a **provisional note**'s glyph. Tests only.
  ///
  /// A separate cache from [debugNoteGlyphBox]'s: the two inks are laid out
  /// independently, so a cap proved on one says nothing about the other.
  @visibleForTesting
  ({double width, double em}) debugProvisionalGlyphBox(int digit) =>
      _boxOf(_provisionalDigits[digit]!);

  /// The same, for a given's glyph. Tests only.
  @visibleForTesting
  ({double width, double em}) debugValueGlyphBox(int digit) =>
      _boxOf(_givenDigits[digit]!);

  ({double width, double em}) _boxOf(TextPainter painter) =>
      (width: painter.width, em: (painter.text! as TextSpan).style!.fontSize!);

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
      !setEquals(old.flaggedCells, flaggedCells) ||
      old.textScale != textScale ||
      old.colours != colours;
}
