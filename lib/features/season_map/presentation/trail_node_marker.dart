import 'package:flutter/material.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../domain/node_type.dart';
import '../domain/trail_progress.dart';

/// One **node** on the **trail**.
///
/// **Every state is carried twice** (constraint 5). Colour is the fast signal;
/// the glyph, the size, and the label beneath are what survive colour vision
/// deficiency, a greyscale screenshot, and a screen reader.
///
/// The colours come from the design tokens by their documented jobs
/// (`docs/DESIGN.md` §1), not from the mockup's artwork:
///
/// - **completed** — `cactusGreen`, whose job is completion
/// - **current** and **chest** — `badgeGold`, whose job is "selection, focus,
///   reward, progress". They share a hue and are told apart by size and glyph,
///   which is what `docs/pages/screens.html` §4 asks for anyway: *the current
///   node is larger, not just redder*
/// - **boss** — `sunsetRed`, whose job is "errors, duplicates, **Ace**". A
///   **boss node** is Ace, so this is the documented job rather than a second
///   one
/// - **not yet reached** — a `bone` surface behind a `duskInk` outline
///
/// The mockup draws the current node in `sunsetRed`. That was drawn before the
/// palette's jobs were fixed at eight tokens (D-71), and following it would
/// give `sunsetRed` a second job — which constraint 4 forbids.
class TrailNodeMarker extends StatelessWidget {
  const TrailNodeMarker({
    required this.position,
    required this.type,
    required this.state,
    required this.isAbovePlayerRank,
    this.onTap,
    super.key,
  });

  final int position;
  final NodeType type;

  /// Null until progress has been read.
  ///
  /// It has its own appearance rather than borrowing one: defaulting to
  /// **not yet reached** would draw all 42 **node**s as unreached on the first
  /// frame and then flip them a moment later, which reads as the trail being
  /// taken away and given back. A **node** with no state yet shows its type and
  /// no state glyph, so what changes when progress lands is an addition.
  final NodeState? state;

  /// Whether this **node**'s **rank** is harder than the player's own.
  ///
  /// A label and nothing more (D-103), exactly as on a **free play** row. It
  /// changes no behaviour here: the tap, the target size, and the route are
  /// identical either way.
  final bool isAbovePlayerRank;

  /// Null where the **node** is **not yet reached**.
  final VoidCallback? onTap;

  /// The **current node** is drawn larger, and that is the primary signal
  /// rather than a flourish: someone returning after three days finds their
  /// place without reading anything (`docs/pages/screens.html` §4).
  static const double _currentDiameter = 60;
  static const double _diameter = 44;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == NodeState.current;
    final diameter = isCurrent ? _currentDiameter : _diameter;

    return Semantics(
      button: onTap != null,
      // The whole state in words, in the order a player would say it. This is
      // the only route a screen reader has to any of it.
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: _fill,
                shape: BoxShape.circle,
                border: Border.all(color: DokuColours.duskInk, width: 3),
              ),
              child: Center(
                child: Icon(_glyph, size: diameter * 0.45, color: _onFill),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Node $position',
              style: TypeRole.label.style,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// What a screen reader reads, and what the golden test checks the words of.
  ///
  /// **"Not yet reached", never "locked"** (D-108). A test asserts no
  /// player-facing string in this feature says otherwise.
  String get semanticLabel {
    final parts = <String>[
      'Node $position',
      _typeWord,
      if (state != null) state!.label,
      if (isAbovePlayerRank) 'Above your rank',
    ];
    return parts.join(', ');
  }

  String get _typeWord => switch (type) {
    NodeType.puzzle => 'Puzzle',
    NodeType.variant => 'Variant puzzle',
    NodeType.chest => 'Chest',
    NodeType.boss => 'Boss',
  };

  /// A **chest node** and a **boss node** keep their own colour in every state,
  /// so the player can see where the **season**'s rewards fall from across the
  /// whole trail — which is the point of front-loading them (D-19).
  Color get _fill => switch (type) {
    NodeType.chest => PaletteToken.badgeGold.colour,
    NodeType.boss => PaletteToken.sunsetRed.colour,
    _ => switch (state) {
      NodeState.completed => PaletteToken.cactusGreen.colour,
      NodeState.current => PaletteToken.badgeGold.colour,
      // Not yet reached, and not yet known, share a surface. Neither is a
      // state the player has to act on.
      NodeState.notYetReached || null => PaletteToken.bone.colour,
    },
  };

  Color get _onFill =>
      state == NodeState.completed || state == NodeState.current
      ? DokuColours.duskInk
      : DokuColours.inkSoft;

  /// The non-colour half of every state, and of every type.
  ///
  /// A completed **chest node** shows as an opened chest rather than a check,
  /// because the type is the thing worth seeing there — the check is already
  /// implied by everything behind it on the trail.
  IconData get _glyph {
    // The padlock the mockup draws. The *glyph* is a padlock; the *words* are
    // "Not yet reached", never "locked" (D-108) — a test asserts the copy.
    if (state == NodeState.notYetReached) return Icons.lock_outline;
    if (state == null) return _typeGlyph;
    return switch (type) {
      NodeType.chest =>
        state == NodeState.completed ? Icons.inventory_2 : Icons.card_giftcard,
      NodeType.boss => Icons.local_police_outlined,
      NodeType.variant =>
        state == NodeState.completed ? Icons.check : Icons.auto_awesome,
      NodeType.puzzle =>
        state == NodeState.completed ? Icons.check : Icons.grid_on,
    };
  }

  /// The type alone, with nothing said about state.
  IconData get _typeGlyph => switch (type) {
    NodeType.chest => Icons.card_giftcard,
    NodeType.boss => Icons.local_police_outlined,
    NodeType.variant => Icons.auto_awesome,
    NodeType.puzzle => Icons.grid_on,
  };
}
