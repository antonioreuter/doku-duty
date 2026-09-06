import 'package:flutter/widgets.dart';

import '../domain/motion.dart';
import '../domain/palette.dart';
import '../domain/shape.dart';
import 'doku_colours.dart';
import 'doku_curves.dart';

/// A surface with depth that can be pressed.
///
/// The depth treatment is a solid offset rectangle, never a blurred shadow.
/// Blur reads corporate; solid offset reads toy — and the offset is also the
/// cheaper of the two to paint.
///
/// **Chrome only.** `docs/DESIGN.md` §4 is explicit that depth never touches
/// grid cells: thick borders and shadows on nine columns destroy readability.
/// Nothing here should end up inside the grid painter.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onPressed,
    this.token = PaletteToken.badgeGold,
    this.radius = DokuRadius.button,
    this.depth = DokuDepth.rest,
    this.reduceMotion = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;

  /// Which token this surface is painted in. Its depth shade comes from the
  /// same token, so the shadow is always the same family as the face.
  final PaletteToken token;

  final double radius;

  /// Resting depth. 5px gives the documented 8px of travel; [DokuDepth]
  /// explains why that is the value rather than the 4 at the other end of the
  /// range.
  final double depth;

  final bool reduceMotion;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null;

  /// Depth is lost while held, and the surface moves down by the same amount it
  /// would have to fall — which is what makes it read as being pushed rather
  /// than shrinking.
  double get _currentDepth => _isPressed ? DokuDepth.pressed : widget.depth;

  double get _currentOffset => _isPressed ? DokuDepth.pressTranslation : 0.0;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final face = widget.token.colour;
    final depthShade = widget.token.depthColour ?? DokuColours.duskInk;

    // The press animation never gates the callback: onTapDown fires the visual
    // change and onTap fires the action, so a fast player is never waiting for
    // a rebound to finish (constraint 2).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _isEnabled ? (_) => _setPressed(true) : null,
      onTapUp: _isEnabled ? (_) => _setPressed(false) : null,
      onTapCancel: _isEnabled ? () => _setPressed(false) : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: DokuMotion.keyPressed.resolve(
          reduceMotion: widget.reduceMotion,
        ),
        curve: DokuCurves.standard,
        transform: Matrix4.translationValues(0, _currentOffset, 0),
        // The solid offset shadow: a second rectangle behind the face, moved
        // down by the current depth. No blur radius anywhere.
        padding: EdgeInsets.only(bottom: _currentDepth),
        decoration: BoxDecoration(
          color: depthShade,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
