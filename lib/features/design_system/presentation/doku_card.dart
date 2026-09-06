import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../domain/palette.dart';
import '../domain/shape.dart';
import 'doku_colours.dart';

/// A card with depth and a slight tilt.
///
/// Chrome only, like every depth treatment: it never wraps a grid cell. Thick
/// borders and shadows on nine columns destroy readability, which is why
/// `docs/DESIGN.md` §4 carves the grid out of the rule.
///
/// Nothing in the interface is perfectly aligned — cards and speech bubbles sit
/// between 0.5° and 2° off square, because perfect alignment reads machine-made.
/// The tilt is derived from [tiltSeed] rather than rolled, so a card does not
/// twitch every time unrelated state rebuilds it.
class DokuCard extends StatelessWidget {
  const DokuCard({
    required this.child,
    required this.tiltSeed,
    this.token = PaletteToken.bone,
    this.padding = const EdgeInsets.all(16),
    this.depth = DokuDepth.rest,
    super.key,
  });

  final Widget child;

  /// Something durable about this card — an index, an id hash. Not a random
  /// number, and not the build count.
  final int tiltSeed;

  final PaletteToken token;
  final EdgeInsets padding;
  final double depth;

  @override
  Widget build(BuildContext context) {
    final depthShade = token.depthColour ?? DokuColours.duskInk;

    return Transform.rotate(
      angle: DokuTilt.forSeed(tiltSeed) * math.pi / 180,
      child: Container(
        // Solid offset shadow: the depth shade shows below the face. No blur.
        padding: EdgeInsets.only(bottom: depth),
        decoration: BoxDecoration(
          color: depthShade,
          borderRadius: BorderRadius.circular(DokuRadius.card),
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: token.colour,
            borderRadius: BorderRadius.circular(DokuRadius.card),
          ),
          child: child,
        ),
      ),
    );
  }
}
