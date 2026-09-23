import 'package:flutter/material.dart';

import '../../daily_challenge/presentation/daily_screen.dart';
import '../../design_system/domain/palette.dart';
import '../../design_system/domain/shape.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../../grid_input/presentation/free_play_screen.dart';
import '../../season_map/presentation/trail_screen.dart';
import '../../trophy_cabinet/presentation/cabinet_screen.dart';

/// The four destinations, side by side.
///
/// **Trail** is the spine — an ordered **season** with somewhere to get to.
/// **Daily** is the habit layer, the third of D-17's three and the reason to
/// open the app on a day the **season** is not calling. **Free play** is where
/// the ladder stays open: any **rank**, any time, no position required (D-111).
///
/// **Cabinet** is the permanent layer and the last of D-17's three to arrive.
/// It is the only destination that is not a route into a puzzle: the map
/// creates urgency, and the cabinet creates the sunk cost (`docs/SPEC.md`
/// §5.1).
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
          CabinetScreen(),
        ],
      ),
      bottomNavigationBar: _HomeNav(
        index: _index,
        onSelected: (index) => setState(() => _index = index),
      ),
    );
  }
}

/// Four destinations, sized to the player's text.
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

    // Above 2x the destinations stack instead of sitting side by side.
    //
    // The threshold moved from 3 to 2 when the **cabinet** made it four: a
    // quarter of the smallest screen the app targets (D-84) is about 75
    // logical pixels, and "Free play" no longer fits on one line there even at
    // 3x. Stacked, each label has the full width: it costs vertical space and
    // never truncates a name, which is the same trade the **tools row** made
    // (D-100).
    final stacked = scale > 2;

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
      _NavEntry(
        entryKey: const ValueKey<String>('nav-cabinet'),
        icon: index == 3 ? Icons.inventory_2 : Icons.inventory_2_outlined,
        label: 'Cabinet',
        isSelected: index == 3,
        scale: scale,
        stacked: stacked,
        onTap: () => onSelected(3),
      ),
    ];

    return Material(
      color: PaletteToken.sand.colour,
      child: SafeArea(
        top: false,
        child: stacked
            // Bounded, and scrollable inside that bound.
            //
            // Four destinations stacked at 5x want more than half the screen,
            // and the body still has to be usable underneath — 184 pixels'
            // worth of overflow, which a test caught the day the **cabinet**
            // was added. Capping the bar and letting it scroll keeps every
            // name whole, which is the rule that matters (D-100): a
            // destination reading "Free pl…" is a control whose name cannot be
            // read, and one the player has to scroll two lines to reach is
            // merely inconvenient.
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
            // Tighter when stacked. Four rows at 5x on the smallest screen the
            // app targets came to twelve pixels over; halving the vertical
            // padding reclaims thirty-two and leaves the tap target on its own
            // floor, which is what accessibility actually requires.
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: stacked ? 4 : 8,
            ),
            child: stacked
                // **No glyph when stacked.** Four destinations each need a
                // full row, and the icon is the half that can go: the label
                // already carries the meaning and the semantics never
                // mentioned the icon at all. Dropping it is what keeps four
                // rows inside the screen at 5x without truncating a name.
                ? Align(alignment: Alignment.centerLeft, child: text)
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
