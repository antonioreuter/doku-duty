import 'package:flutter/animation.dart';

/// Motion curves from `docs/DESIGN.md` §4.
///
/// Nothing fades in. Things pop, drop, or slide from where they logically came
/// from, and anything appearing overshoots — that overshoot is most of the
/// difference between an interface that is correct and one that is a game.
abstract final class DokuCurves {
  /// Roughly 15% overshoot, for anything appearing.
  ///
  /// Flutter's own `Curves.easeOutBack` peaks near 10%, which reads as a
  /// hesitation rather than a pop, so the final control point is pushed out.
  static const Curve overshoot = Cubic(0.175, 0.885, 0.32, 1.45);

  /// For anything moving without arriving — a value settling, a colour
  /// changing. No overshoot, because there is nothing to land.
  static const Curve standard = Curves.easeOutCubic;

  /// For anything leaving. Departures do not bounce; only arrivals do.
  static const Curve exit = Curves.easeInCubic;
}
