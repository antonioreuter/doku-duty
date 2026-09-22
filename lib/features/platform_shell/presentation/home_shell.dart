import 'package:flutter/material.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../grid_input/presentation/free_play_screen.dart';
import '../../season_map/presentation/trail_screen.dart';

/// The two routes into a puzzle, side by side.
///
/// **Trail** is the spine — an ordered **season** with somewhere to get to.
/// **Free play** is where the ladder stays open: any **rank**, any time, no
/// position required (D-111).
///
/// Daily and Cabinet belong here too and are deliberately absent rather than
/// stubbed. `add-daily-challenge` and `add-trophy-cabinet` own them, and a
/// placeholder tab would be guessing at their arguments — the same reason the
/// router carried no season-map route until this change.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Both stay built, so switching back does not re-read the database and
      // does not lose the player's scroll position on a 42-**node** trail.
      body: IndexedStack(
        index: _index,
        children: const <Widget>[TrailScreen(), FreePlayScreen()],
      ),
      bottomNavigationBar: _HomeNav(
        index: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

/// Two destinations, sized to the player's text.
///
/// **Material's `NavigationBar` is deliberately not used here.** Its height is
/// fixed, so at the accessibility text sizes it overflows — 139 pixels at 4x
/// and 381 at 5x, which a test caught the moment this shell landed. That is the
/// same failure the **tools row** was created to fix on the pad (D-100), and
/// this takes the same answer: the control grows with the text rather than the
/// text being clamped to fit the control, and the label wraps instead of
/// truncating. A destination reading "Free pl…" would be a control whose name
/// cannot be read.
class _HomeNav extends StatelessWidget {
  const _HomeNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.maybeTextScalerOf(context)?.scale(1) ?? 1.0;

    return Material(
      color: PaletteToken.sand.colour,
      child: SafeArea(
        top: false,
        child: Row(
          key: const ValueKey<String>('home-nav'),
          children: <Widget>[
            Expanded(
              child: _NavEntry(
                entryKey: const ValueKey<String>('nav-trail'),
                icon: index == 0 ? Icons.map : Icons.map_outlined,
                label: 'Trail',
                isSelected: index == 0,
                scale: scale,
                onTap: () => onSelected(0),
              ),
            ),
            Expanded(
              child: _NavEntry(
                entryKey: const ValueKey<String>('nav-free-play'),
                icon: index == 1 ? Icons.grid_on : Icons.grid_on_outlined,
                label: 'Free play',
                isSelected: index == 1,
                scale: scale,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.entryKey,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.scale,
    required this.onTap,
  });

  final Key entryKey;
  final IconData icon;
  final String label;
  final bool isSelected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The glyph grows with the text, but only until it has doubled. Past that
    // it is an icon beside a word rather than a picture of one, and the word is
    // what the player is reading at 5x.
    final iconScale = scale.clamp(1.0, 2.0);

    return Semantics(
      button: true,
      // `selected` carries the on state, so which tab is open is readable
      // without seeing which one is painted differently (constraint 5).
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: entryKey,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: DokuLayout.minimumTapTarget * (scale < 1 ? 1 : scale),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 24 * iconScale,
                  color: isSelected
                      ? PaletteToken.badgeGold.colour
                      : DokuColours.duskInk,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  // Wraps rather than truncating, for the reason the tools row
                  // does: a destination reading "Free pl…" is a control whose
                  // name cannot be read.
                  style: TypeRole.label
                      .scaled(scale)
                      .copyWith(color: DokuColours.duskInk),
                  // The scale is already in the style. Left on, the ambient
                  // scaler would apply it a second time.
                  textScaler: TextScaler.noScaling,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
