import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_curves.dart';

double _peak(Curve curve) {
  var peak = 0.0;
  for (var i = 0; i <= 1000; i++) {
    final v = curve.transform(i / 1000);
    if (v > peak) peak = v;
  }
  return peak;
}

void main() {
  group('the overshoot curve', () {
    // "easeOutBack, roughly 15% overshoot, on anything appearing. Nothing fades
    // in — things pop, drop, or slide." (docs/DESIGN.md §4)
    test('overshoots by roughly 15%', () {
      final peak = _peak(DokuCurves.overshoot);
      expect(
        peak - 1.0,
        closeTo(0.15, 0.02),
        reason: 'peak was ${peak.toStringAsFixed(4)}',
      );
    });

    test('starts at 0 and ends at 1', () {
      expect(DokuCurves.overshoot.transform(0.0), closeTo(0.0, 1e-6));
      expect(DokuCurves.overshoot.transform(1.0), closeTo(1.0, 1e-6));
    });

    test('actually overshoots rather than easing flat', () {
      expect(_peak(DokuCurves.overshoot), greaterThan(1.0));
    });
  });

  group('the other curves', () {
    test('the standard ease never overshoots', () {
      expect(_peak(DokuCurves.standard), closeTo(1.0, 1e-6));
    });

    // Reduced motion resolves to the end state; a curve is never the thing
    // that has to be switched off, the duration is.
    test('exit does not overshoot — things leave, they do not bounce out', () {
      expect(_peak(DokuCurves.exit), closeTo(1.0, 1e-6));
    });
  });
}
