import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'doku_colours.dart';

/// Paper grain across a surface.
///
/// Flat fill is the fastest way to look cheap, and 4% is the level where the
/// texture is felt rather than seen. Painted procedurally rather than shipped
/// as an image: a tiling PNG large enough not to repeat visibly costs more
/// bytes than this costs frames, and it cannot follow a season's surface.
class PaperGrain extends StatelessWidget {
  const PaperGrain({this.opacity = 0.04, this.child, super.key});

  /// `docs/DESIGN.md` §4. Higher than this and it reads as noise.
  final double opacity;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(opacity: opacity),
      // Grain sits behind content, never over a glyph.
      child: child,
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    // A fixed seed: grain that changes between frames is visible as crawling,
    // which is exactly what paper does not do.
    final random = math.Random(20260905);
    final paint = Paint()
      ..color = DokuColours.duskInk.withValues(alpha: opacity);

    // One speck per 90px² keeps the count in the low thousands on a phone,
    // well under the particle budget the effects layer has to live within.
    final specks = (size.width * size.height / 90).round();
    for (var i = 0; i < specks; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          1,
          1,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
