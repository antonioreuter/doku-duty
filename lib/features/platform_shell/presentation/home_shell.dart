import 'package:flutter/material.dart';

import '../../daily_challenge/presentation/daily_screen.dart';
import '../../design_system/domain/palette.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../grid_input/presentation/free_play_screen.dart';
import '../../season_map/presentation/trail_screen.dart';

/// The three routes into a puzzle, side by side.
///
/// **Trail** is the spine — an ordered **season** with somewhere to get to.
/// **Daily** is the habit layer, the third of D-17's three and the reason to
/// open the app on a day the **season** is not calling. **Free play** is where
/// the ladder stays open: any **rank**, any time, no position required (D-111).
///
/// Cabinet belongs here too and is deliberately absent rather than stubbed.
/// `add-trophy-cabinet` owns it, and a placeholder tab would be guessing at its
/// arguments — the same reason this shell carried no Daily tab until
/// `add-daily-challenge`.
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
      // All three stay built, so switching back does not re-read the database
      // and does not lose the player's scroll position on a 42-**node** trail.
      // Each screen is responsible for not reading anything before the first
      // frame, because building is exactly what they all do on launch.
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          TrailScreen(),
          DailyScreen(),
          FreePlayScreen(),
        ],
      ),
      bottomNavigationBar: _HomeNav(
        index: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

/// Three destinations, sized to the player's text.
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

    // Above 3x the destinations stack instead of sitting side by side.
    //
    // Three of them rather than two gives each label a third of the width, and
    // on the smallest phone the app targets (D-84) that is about 100 logical
    // pixels — enough for "Free play" to wrap to four lines at 5x and for the
    // bar to overflow the screen it is meant to sit under. A test caught it
    // the day Daily was added. Stacked, each label has the full width and fits
    // on one line: it costs vertical space and never truncates a name, which
    // is the same trade the **tools row** made (D-100).
    final stacked = scale > 3;

    final entries = <Widget>[
      _NavEntry(
        entryKey: const ValueKey<String>('nav-trail'),
        icon: index == 0 ? Icons.map : Icons.map_outlined,
        label: 'Trail',
        isSelected: index == 0,
        scale: scale,
        stacked: stacked,
        onTap: () => onSelected(0),
      ),
      _NavEntry(
        entryKey: const ValueKey<String>('nav-daily'),
        icon: index == 1 ? Icons.calendar_month : Icons.calendar_month_outlined,
        label: 'Daily',
        isSelected: index == 1,
        scale: scale,
        stacked: stacked,
        onTap: () => onSelected(1),
      ),
      _NavEntry(
        entryKey: const ValueKey<String>('nav-free-play'),
        icon: index == 2 ? Icons.grid_on : Icons.grid_on_outlined,
        label: 'Free play',
        isSelected: index == 2,
        scale: scale,
        stacked: stacked,
        onTap: () => onSelected(2),
      ),
    ];

    return Material(
      color: PaletteToken.sand.colour,
      child: SafeArea(
        top: false,
        child: stacked
            ? Column(
                key: const ValueKey<String>('home-nav'),
                mainAxisSize: MainAxisSize.min,
                children: entries,
              )
            : Row(
                key: const ValueKey<String>('home-nav'),
                children: <Widget>[
                  for (final entry in entries) Expanded(child: entry),
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
    required this.stacked,
    required this.onTap,
  });

  final Key entryKey;
  final IconData icon;
  final String label;
  final bool isSelected;
  final double scale;

  /// Whether the bar has gone vertical, in which case the glyph sits beside the
  /// word rather than above it and there is room for both.
  final bool stacked;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The glyph grows with the text, but only until it has doubled. Past that
    // it is an icon beside a word rather than a picture of one, and the word is
    // what the player is reading at 5x.
    final iconScale = scale.clamp(1.0, 2.0);

    final glyph = Icon(
      icon,
      size: 24 * iconScale,
      color: isSelected ? PaletteToken.badgeGold.colour : DokuColours.duskInk,
    );

    final text = Text(
      label,
      textAlign: stacked ? TextAlign.start : TextAlign.center,
      // Wraps rather than truncating, for the reason the tools row does: a
      // destination reading "Free pl…" is a control whose name cannot be read.
      style: TypeRole.label.scaled(scale).copyWith(color: DokuColours.duskInk),
      // The scale is already in the style. Left on, the ambient scaler would
      // apply it a second time.
      textScaler: TextScaler.noScaling,
    );

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
            // Side by side there is one row, so letting it grow with the text
            // costs one row's height and keeps the target comfortable. Stacked
            // there are three, and multiplying by the scale would ask for
            // 48 × 5 × 3 = 720 pixels of navigation on a 568-pixel screen. The
            // floor is what accessibility actually requires; the multiplier was
            // only ever a comfort, and it is the half that has to give.
            minHeight: stacked
                ? DokuLayout.minimumTapTarget
                : DokuLayout.minimumTapTarget * (scale < 1 ? 1 : scale),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: stacked
                ? Row(
                    children: <Widget>[
                      glyph,
                      const SizedBox(width: 8),
                      Expanded(child: text),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[glyph, const SizedBox(height: 2), text],
                  ),
          ),
        ),
      ),
    );
  }
}
