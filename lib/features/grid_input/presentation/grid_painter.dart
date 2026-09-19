import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../../completion_effects/domain/completion_sequence.dart';
import '../../completion_effects/domain/effect_frame.dart';
import '../../completion_effects/domain/particle_pool.dart';
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
    required this.completionFill,
    required this.freshCompletionFill,
    required this.completionMark,
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
    completionFill: PaletteToken.cactusGreen.paleColour!,
    freshCompletionFill: PaletteToken.badgeGold.paleColour!,
    completionMark: DokuColours.cactusGreen,
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
    // The completion token paled, the tint `docs/DESIGN.md` §1 already names
    // for a settled **unit** — not a ninth hue (constraint 4).
    completionFill: PaletteToken.cactusGreen.paleColour!,
    // `goldPale`, which §1 assigns to the fresh-completion flash as well as to
    // focus. The same derived tint doing a second job for two seconds before it
    // settles, not a new one: a ninth hue is what constraint 4 forbids, and
    // this is neither ninth nor a hue of its own.
    freshCompletionFill: PaletteToken.badgeGold.paleColour!,
    completionMark: DokuColours.cactusGreen,
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

  /// The cell of a complete **unit**.
  ///
  /// Bottom of the D-49 priority order — below [flaggedFill], [candidateFill]
  /// and [focusFill], all of which are painted over it. It is a record of work
  /// already done, and it must never obscure what the player is doing now.
  ///
  /// **One flat level, never additive** (D-48). A cell in three complete
  /// **unit**s takes this colour exactly once, because the painter is handed a
  /// set of cells and a set has nowhere to put a second copy.
  final Color completionFill;

  /// The warmer hold a **unit** takes for two seconds after it completes,
  /// before settling to [completionFill].
  ///
  /// The celebration and the record are different states, and this is the
  /// celebration.
  final Color freshCompletionFill;

  /// The **corner mark** that says a cell's **unit** is complete.
  ///
  /// **This is the signal, and the tint is the convenience** (D-50,
  /// constraint 5). It survives a player who cannot separate the completion hue
  /// from the surface, and it survives the player hiding the tints, which is
  /// the case the tint itself cannot.
  final Color completionMark;

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
      other.completionFill == completionFill &&
      other.freshCompletionFill == freshCompletionFill &&
      other.completionMark == completionMark &&
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
    completionFill,
    freshCompletionFill,
    completionMark,
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
    this.completedCells = const <int>{},
    this.freshCells = const <int>{},
    this.showCompletionTints = true,
    this.effects = EffectFrame.empty,
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

  /// Every cell in a complete **unit**, derived from the board by
  /// `UnitCompletion.tintedCells`.
  ///
  /// A set, and that is D-48 made structural: the painter is told *which* cells
  /// are tinted and never *how many times*, so there is no count it could
  /// stack into mud on a nearly finished board. It could not tint twice if it
  /// tried.
  final Set<int> completedCells;

  /// The cells of a **unit** completed within the last couple of seconds, which
  /// hold the warmer flash before settling.
  ///
  /// A subset of [completedCells] in practice, and painted after it, so a cell
  /// that is both takes the fresh colour.
  final Set<int> freshCells;

  /// Whether the player is letting the tints be drawn.
  ///
  /// The **corner mark**s are not subject to this. Hiding the tint hides a
  /// convenience; hiding the signal would leave completion unreadable, which is
  /// the thing constraint 5 exists to prevent.
  final bool showCompletionTints;

  /// Whatever is celebrating right now.
  ///
  /// A snapshot the painter draws and cannot change. The effect layer produces
  /// frames; it has no route back to the board.
  final EffectFrame effects;

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
    _paintCompletion(canvas, metrics);
    _paintFlags(canvas, metrics);
    _paintHighlight(canvas, metrics);
    _paintFocus(canvas, metrics);
    _paintLines(canvas, metrics);
    _paintEffects(canvas, metrics);
    _paintNotes(canvas, metrics);
    _paintDigits(canvas, metrics);
    _paintCompletionMarks(canvas, metrics);
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

  /// The cells of every complete **unit**.
  ///
  /// **First of the four cell fills, so every other one lands on top** — the
  /// bottom of the D-49 order: selection, then **candidate highlighting**, then
  /// the flag, then this. A completion tint that obscured the selected cell
  /// would make a record of past work outrank the work in hand, which is the
  /// wrong way round.
  ///
  /// One pass over a set, so a cell belonging to three complete **unit**s is
  /// painted once at one opacity (D-48). There is no additive path here to take
  /// by accident.
  void _paintCompletion(Canvas canvas, GridMetrics metrics) {
    if (!showCompletionTints) return;

    final settled = Paint()..color = colours.completionFill;
    for (final cell in completedCells) {
      canvas.drawRect(metrics.cellRect(cell), settled);
    }

    // After the settled tint rather than instead of it: a cell can be fresh in
    // one **unit** and settled in another, and the celebration is the louder of
    // the two facts for as long as it lasts.
    final fresh = Paint()..color = colours.freshCompletionFill;
    for (final cell in freshCells) {
      canvas.drawRect(metrics.cellRect(cell), fresh);
    }
  }

  /// The **corner mark** on every cell of a complete **unit**.
  ///
  /// Drawn whether or not the tints are (D-50): this is the signal, and a
  /// player who hid the tints or cannot separate the hue still reads it.
  ///
  /// It never collides with a candidate, and not by luck — a cell holds a value
  /// or notes and never both, and a **unit** is complete only when all nine of
  /// its cells hold values. A tinted cell therefore has no candidates for a
  /// corner to land on.
  void _paintCompletionMarks(Canvas canvas, GridMetrics metrics) {
    if (completedCells.isEmpty) return;

    final mark = Paint()
      ..color = colours.completionMark
      ..style = PaintingStyle.fill;
    for (final cell in completedCells) {
      final rect = metrics.cellRect(cell);
      // Sized from the cell rather than from a constant, so it holds its
      // proportion at every grid size and every text scale (D-92).
      final side = rect.width * _completionMarkFraction;
      final inset = _markInset(rect, metrics);
      // A filled triangle in the top-right corner: the corner furthest from
      // both the value's centre and the reading eye's path across the row.
      final path = Path()
        ..moveTo(rect.right - inset - side, rect.top + inset)
        ..lineTo(rect.right - inset, rect.top + inset)
        ..lineTo(rect.right - inset, rect.top + inset + side)
        ..close();
      canvas.drawPath(path, mark);
    }
  }

  /// The lasso, the dynamite, and the dust they throw up.
  ///
  /// **Between the lines and the glyphs, and that placement is the rule**
  /// (`docs/DESIGN.md` §6). Above the cells, so an effect is visible; below
  /// every value and candidate, so it can never obscure one. Drawing it after
  /// the digits would put a puff over a number the player is reading, and no
  /// amount of opacity tuning makes that acceptable — the glyph is the content
  /// and the effect is the decoration.
  void _paintEffects(Canvas canvas, GridMetrics metrics) {
    if (effects.isEmpty) return;

    for (final effect in effects.effects) {
      if (effect.isRadial) {
        _paintDynamite(canvas, metrics, effect);
      } else {
        _paintLasso(canvas, metrics, effect);
      }
    }
    _paintParticles(canvas, metrics);

    final sequence = effects.sequence;
    if (sequence != null) _paintSequence(canvas, metrics, sequence);
  }

  /// The puzzle-completion sequence, beat by beat.
  ///
  /// Only the beats that draw something appear here. [CompletionBeat.hoof] and
  /// [CompletionBeat.bow] are Biscuit and Ace, and they belong to
  /// `add-character-system` — the sequence runs through their slots at the
  /// documented speed and draws nothing in them, so filling them in later moves
  /// no timing.
  ///
  /// Nothing is culled here, and nothing needs to be: the board is finished, so
  /// there is no unplaced cell for a scrap to land on.
  void _paintSequence(
    Canvas canvas,
    GridMetrics metrics,
    SequenceFrame sequence,
  ) {
    for (final beat in sequence.running) {
      if (!beat.isDrawn) continue;
      final progress = sequence.progressOf(beat);
      switch (beat) {
        case CompletionBeat.wave:
          _paintWave(canvas, metrics, sequence.origin, progress);
        case CompletionBeat.scraps:
          _paintScraps(canvas, metrics, sequence.origin, progress);
        case CompletionBeat.hoof || CompletionBeat.bow:
          break;
      }
    }
  }

  /// Beat one: a wave crossing the grid from the cell that finished it.
  void _paintWave(
    Canvas canvas,
    GridMetrics metrics,
    int origin,
    double progress,
  ) {
    final from = metrics.cellRect(origin).center;
    final reach = metrics.side * 1.5 * progress;
    canvas.drawCircle(
      from,
      reach,
      Paint()
        ..color = colours.freshCompletionFill.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = metrics.cellSize * _waveWeight,
    );
  }

  /// Beat three: wanted-poster scraps bursting from the stamp point.
  ///
  /// Forty of them, the cap in `docs/DESIGN.md` §6. Placed deterministically so
  /// a golden is reproducible — where a given scrap lands is not what anyone is
  /// looking at.
  void _paintScraps(
    Canvas canvas,
    GridMetrics metrics,
    int origin,
    double progress,
  ) {
    final from = metrics.cellRect(origin).center;
    final paint = Paint()
      ..color = colours.completionMark.withValues(alpha: 1 - progress);

    for (var i = 0; i < ParticleBudget.atPuzzleCompletion; i++) {
      final angle = i * (2 * math.pi / ParticleBudget.atPuzzleCompletion);
      final spread = metrics.side * 0.5 * progress * (0.4 + (i % 7) / 10);
      final drift = metrics.cellSize * progress * progress * 2;
      final centre = Offset(
        from.dx + math.cos(angle) * spread,
        from.dy + math.sin(angle) * spread + drift,
      );
      canvas.drawCircle(centre, metrics.cellSize * _scrapRadius, paint);
    }
  }

  /// The wave's weight, as a fraction of a cell.
  static const double _waveWeight = 0.1;

  /// A scrap's radius, as a fraction of a cell.
  static const double _scrapRadius = 0.07;

  /// A rope running the length of the **unit** from the placed cell.
  ///
  /// Linear and directional, which is what separates it from the block's
  /// radial burst: a player should be able to tell a completed row from a
  /// completed block without reading either.
  void _paintLasso(Canvas canvas, GridMetrics metrics, ActiveEffect effect) {
    final cells = effect.unit.cells;
    final from = metrics.cellRect(effect.origin).center;
    final reached = effect.reach;

    final rope = Paint()
      ..color = colours.freshCompletionFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = metrics.cellSize * _ropeWeight
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < cells.length; i++) {
      final rect = metrics.cellRect(cells[i]);
      // Staggered by distance from the origin rather than by index, so the
      // rope runs outward from where the finger was in both directions.
      final distance = (rect.center - from).distance / metrics.cellSize;
      final sinceReached = reached - distance;
      if (sinceReached < 0) continue;
      canvas.drawLine(from, rect.center, rope);

      // The cell pops as the rope arrives and settles a cell's travel later.
      // Brightest the moment it is gathered, gone by the time the rope is two
      // cells past it — a wash that stayed at full strength behind the whole
      // unit would hide the rope that caused it.
      //
      // Drawn as an inflated rect rather than a transform: the grid is one
      // canvas, and scaling a cell would scale the glyph with it, moving a
      // candidate out of the slot its digit owns (constraint 3).
      final pop = (1 - sinceReached).clamp(0.0, 1.0);
      if (pop <= 0) continue;
      canvas.drawRect(
        rect.inflate(metrics.cellSize * _popInset * pop),
        Paint()..color = colours.freshCompletionFill.withValues(alpha: pop),
      );
    }
  }

  /// The charge going off, radially, from the placed cell.
  ///
  /// Radial and never linear, so a block never reads as a row (D-47's whole
  /// reason for chaining them separately).
  void _paintDynamite(Canvas canvas, GridMetrics metrics, ActiveEffect effect) {
    final from = metrics.cellRect(effect.origin).center;
    final radius = metrics.cellSize * 2.2 * effect.progress;
    canvas.drawCircle(
      from,
      radius,
      Paint()
        ..color = colours.freshCompletionFill.withValues(
          alpha: 1 - effect.progress,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = metrics.cellSize * _ropeWeight,
    );
  }

  /// The dust and the debris.
  ///
  /// Each particle is already known to be over a filled cell — the pool culls
  /// the rest at emission, so nothing here has to decide whether a puff is
  /// allowed to be where it is.
  void _paintParticles(Canvas canvas, GridMetrics metrics) {
    for (final particle in effects.particles) {
      final rect = metrics.cellRect(particle.cell);
      final centre = Offset(
        rect.left + particle.offset.$1 * rect.width,
        rect.top + particle.offset.$2 * rect.height,
      );
      canvas.drawCircle(
        centre,
        metrics.cellSize * _particleRadius * (1 - particle.progress),
        Paint()
          ..color = colours.completionMark.withValues(
            alpha: 1 - particle.progress,
          ),
      );
    }
  }

  /// The rope's weight, as a fraction of a cell.
  static const double _ropeWeight = 0.06;

  /// How far a popping cell swells at the height of its pop.
  static const double _popInset = 0.08;

  /// A dust puff's radius at birth, as a fraction of a cell.
  static const double _particleRadius = 0.09;

  /// The corner mark's side, as a fraction of the cell.
  static const double _completionMarkFraction = 0.18;

  /// How far the mark sits from the cell's edges, as a fraction of the cell.
  static const double _completionMarkInset = 0.06;

  /// How far the mark sits from its cell's top-right corner.
  ///
  /// One cell needs more than the others. The grid's outer contour is rounded
  /// at [DokuRadius.gridOuter], and in the cell at the grid's own top-right
  /// that curve cuts straight through where the mark would go — leaving one of
  /// eighty-one marks visibly sliced, which reads as a rendering fault rather
  /// than as a signal. Pushing that one mark inside the arc costs nothing
  /// anywhere else, and the mark is the cue completion survives on when colour
  /// does not (D-50, constraint 5), so it is not a cue to leave half-drawn.
  static double _markInset(Rect cell, GridMetrics metrics) {
    final base = cell.width * _completionMarkInset;
    final bounds = metrics.bounds;
    final atGridCorner =
        (cell.right - bounds.right).abs() < 0.5 &&
        (cell.top - bounds.top).abs() < 0.5;
    if (!atGridCorner) return base;

    // The mark's right-angle vertex is its outermost point, so keeping that
    // inside the arc keeps the whole triangle inside it. On the diagonal the
    // vertex sits (radius - inset) * √2 from the arc's centre, which gives the
    // inset directly. The margin clears the contour stroke as well as the arc.
    const margin = DokuStroke.outerContour / 2 + 1;
    const needed =
        DokuRadius.gridOuter - (DokuRadius.gridOuter - margin) / math.sqrt2;
    return math.max(base, needed);
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
      !setEquals(old.completedCells, completedCells) ||
      !setEquals(old.freshCells, freshCells) ||
      old.showCompletionTints != showCompletionTints ||
      old.effects != effects ||
      old.textScale != textScale ||
      old.colours != colours;
}
