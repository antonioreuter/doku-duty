import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';

void main() {
  group('corner radii', () {
    test('match docs/DESIGN.md §3', () {
      expect(DokuRadius.card, 20.0);
      expect(DokuRadius.button, 18.0);
      expect(DokuRadius.gridOuter, 14.0);
    });
  });

  group('stroke weights', () {
    test('match docs/DESIGN.md §3', () {
      expect(DokuStroke.outerContour, 3.0);
      expect(DokuStroke.interiorDetail, 2.0);
      expect(DokuStroke.gridBoxDivider, 2.5);
      expect(DokuStroke.gridCellHairline, 1.0);
    });

    // The thick-outside/thin-inside relationship is what reads as cartoon
    // rather than diagram. Uniform stroke weight is the tell of lifeless
    // vector art, so the ordering is asserted rather than left to taste.
    test('get thinner from the outer contour inward', () {
      expect(DokuStroke.outerContour, greaterThan(DokuStroke.gridBoxDivider));
      expect(DokuStroke.gridBoxDivider, greaterThan(DokuStroke.interiorDetail));
      expect(
        DokuStroke.interiorDetail,
        greaterThan(DokuStroke.gridCellHairline),
      );
    });
  });

  group('depth', () {
    test('rest and pressed depths match docs/DESIGN.md §4', () {
      expect(DokuDepth.rest, 5.0);
      expect(DokuDepth.restMinimum, 4.0);
      expect(DokuDepth.pressed, 1.0);
      expect(DokuDepth.pressTranslation, 4.0);
    });

    // "8px of total travel" — the downward move plus the depth it loses. The
    // documented range is 4–5px rest, and only 5 produces 8px of travel, so the
    // sum is what pins the value down.
    test('total travel is 8px', () {
      expect(
        DokuDepth.pressTranslation + (DokuDepth.rest - DokuDepth.pressed),
        8.0,
      );
    });
  });

  group('tilt', () {
    // Nothing is perfectly aligned — 0.5° to 2°. Perfect alignment reads
    // machine-made.
    test('stays inside the documented range', () {
      expect(DokuTilt.minimumDegrees, 0.5);
      expect(DokuTilt.maximumDegrees, 2.0);
    });

    test('is stable for a given seed rather than re-rolled per rebuild', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(
          DokuTilt.forSeed(seed),
          DokuTilt.forSeed(seed),
          reason: 'seed $seed',
        );
      }
    });

    test('every seed lands inside the range, in either direction', () {
      for (var seed = 0; seed < 200; seed++) {
        final degrees = DokuTilt.forSeed(seed).abs();
        expect(degrees, greaterThanOrEqualTo(DokuTilt.minimumDegrees));
        expect(degrees, lessThanOrEqualTo(DokuTilt.maximumDegrees));
      }
    });

    test('produces tilts in both directions across seeds', () {
      final tilts = <double>[for (var s = 0; s < 40; s++) DokuTilt.forSeed(s)];
      expect(tilts.any((t) => t > 0), isTrue);
      expect(tilts.any((t) => t < 0), isTrue);
    });
  });

  group('grid layout', () {
    test('the minimum cell tap target is 44pt', () {
      expect(DokuLayout.minimumTapTarget, 44.0);
    });

    // Five columns, not nine. Nine keys in a row cannot carry the depth
    // treatment and are worse for thumbs regardless (docs/DESIGN.md §8).
    test('the number pad is five columns', () {
      expect(DokuLayout.numberPadColumns, 5);
    });
  });
}
