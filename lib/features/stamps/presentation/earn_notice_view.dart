import 'package:flutter/material.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';

/// "+5 Stamps", once, after the celebration (D-134).
///
/// **It takes nothing from the player.** Pointer events pass straight through
/// it, so the tap after a solve still reaches whatever is under it
/// (constraint 2); it is not a dialog, has no button, and offers nothing for
/// sale (D-66, constraint 10). It says what was earned and goes away.
///
/// Ink on the paper surface, with the words carrying the meaning — no hue of
/// its own (constraints 4 and 5). A screen reader hears it as it appears.
class EarnNoticeView extends StatelessWidget {
  const EarnNoticeView({
    required this.total,
    required this.reduceMotion,
    super.key,
  });

  /// The **stamp**s to announce, or null for no notice.
  final int? total;

  final bool reduceMotion;

  static const Duration _fade = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final total = this.total;
    final notice = total == null
        ? const SizedBox.shrink(key: ValueKey<String>('earn-notice-none'))
        : Container(
            key: const ValueKey<String>('earn-notice'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: PaletteToken.bone.colour,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: DokuColours.duskInk, width: 2),
            ),
            child: Text('+$total Stamps', style: TypeRole.body.style),
          );

    // The words for a screen reader sit outside the pointer barrier: ignoring
    // taps must not also mean going unheard.
    return Semantics(
      liveRegion: total != null,
      label: total == null ? null : '$total stamps earned',
      excludeSemantics: true,
      child: IgnorePointer(
        child: reduceMotion
            ? notice
            : AnimatedSwitcher(duration: _fade, child: notice),
      ),
    );
  }
}
