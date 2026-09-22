import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/season_map/presentation/trail_path_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the painter draws, so geometry can be asserted without a
/// golden. A golden says the picture changed; this says *where the line went*.
class _RecordingCanvas implements Canvas {
  final List<Path> paths = <Path>[];
  final List<Paint> paints = <Paint>[];

  @override
  void drawPath(Path path, Paint paint) {
    paths.add(path);
    paints.add(paint);
  }

  @override
  void noSuchMethod(Invocation invocation) {}
}

const Size _row = Size(400, 84);

_RecordingCanvas _paint(TrailPathPainter painter, {Size size = _row}) {
  final canvas = _RecordingCanvas();
  painter.paint(canvas, size);
  return canvas;
}

/// Where the line crosses a given height, to the nearest tenth of a pixel.
///
/// Read off the path's own metrics rather than recomputed from the painter's
/// arithmetic, so the test fails if the curve is rewired even when the formula
/// still looks right.
double _xAt(Path path, double t) {
  final metric = path.computeMetrics().first;
  return metric.getTangentForOffset(metric.length * t)!.position.dx;
}

void main() {
  const double leftAnchor =
      TrailPathPainter.rowInset + TrailPathPainter.anchorWidth / 2;

  group('anchors', () {
    test('a left node anchors a fixed inset from the left edge', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: false, isLast: false),
      );

      // The curve ends at the marker; the stub starts there and runs down.
      final bounds = canvas.paths.single.getBounds();
      expect(bounds.left, closeTo(leftAnchor, 0.01));
    });

    test('a right node anchors the same inset from the right edge', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: false, isFirst: false, isLast: false),
      );

      final bounds = canvas.paths.single.getBounds();
      expect(bounds.right, closeTo(_row.width - leftAnchor, 0.01));
    });

    test('the anchor is the anchor box centre, not the circle centre', () {
      // 44px and 60px circles hang off the same line. The painter is never
      // told which it is (D-113), so the terminus is the anchor box's centre
      // and stays put as the current node moves along the trail.
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: true, isLast: false),
      );

      expect(
        canvas.paths.single.getBounds().top,
        closeTo(
          TrailPathPainter.rowVerticalPad + TrailPathPainter.anchorWidth / 2,
          0.01,
        ),
      );
    });
  });

  group('continuity', () {
    test('an incoming curve starts at the opposite side, at the top edge', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: false, isLast: true),
      );

      final path = canvas.paths.single;
      expect(_xAt(path, 0), closeTo(_row.width - leftAnchor, 0.01));
      expect(path.getBounds().top, closeTo(0, 0.01));
    });

    test(
      'an outgoing stub reaches the bottom edge so the next row meets it',
      () {
        final canvas = _paint(
          const TrailPathPainter(isLeft: true, isFirst: true, isLast: false),
        );

        expect(
          canvas.paths.single.getBounds().bottom,
          closeTo(_row.height, 0.01),
        );
      },
    );

    test('the first node draws no incoming curve', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: true, isLast: false),
      );

      // Only the stub: it starts at the marker, not at the top edge.
      final bounds = canvas.paths.single.getBounds();
      expect(
        bounds.top,
        closeTo(
          TrailPathPainter.rowVerticalPad + TrailPathPainter.anchorWidth / 2,
          0.01,
        ),
      );
    });

    test('the last node draws no outgoing stub', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: false, isLast: true),
      );

      expect(
        canvas.paths.single.getBounds().bottom,
        closeTo(
          TrailPathPainter.rowVerticalPad + TrailPathPainter.anchorWidth / 2,
          0.01,
        ),
      );
    });

    test('a lone node draws nothing at all', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: true, isLast: true),
      );

      expect(canvas.paths.single.computeMetrics().isEmpty, isTrue);
    });
  });

  group('the line carries no state', () {
    test('it is drawn in inkSoft, never a state colour', () {
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: false, isLast: false),
      );

      // Compared as ARGB rather than as `Color`: a colour round-tripped
      // through `Paint` is not `==` to the one it was built from.
      expect(
        canvas.paints.single.color.toARGB32(),
        DokuColours.inkSoft.toARGB32(),
      );
    });

    test('hairline would be invisible on the page it is drawn on', () {
      // The trap D-113 exists to stop. `hairline` is the obvious token for a
      // line and measures 1.07:1 against the trail's own background, so
      // choosing it would erase the line with no test failing and nothing to
      // see in the diff — unless a test says so, which is this one.
      expect(_contrast(DokuColours.hairline, DokuColours.sand), lessThan(1.5));
      expect(
        _contrast(DokuColours.inkSoft, DokuColours.sand),
        greaterThan(4.5),
      );
    });

    test('it is drawn subordinate to the marker contour', () {
      // `docs/DESIGN.md` §3: interior detail is 2, the marker's own contour is
      // 3. Thinner is the point — a connector as heavy as the markers turns
      // the trail into a diagram.
      final canvas = _paint(
        const TrailPathPainter(isLeft: true, isFirst: false, isLast: false),
      );

      expect(canvas.paints.single.strokeWidth, TrailPathPainter.strokeWidth);
      expect(canvas.paints.single.strokeWidth, lessThan(3));
      expect(canvas.paints.single.style, PaintingStyle.stroke);
    });
  });

  group('repaint', () {
    test('identical geometry does not repaint while the trail scrolls', () {
      const a = TrailPathPainter(isLeft: true, isFirst: false, isLast: false);
      const b = TrailPathPainter(isLeft: true, isFirst: false, isLast: false);

      expect(a.shouldRepaint(b), isFalse);
    });

    test('only the two end flags and the side can ever repaint it', () {
      const middle = TrailPathPainter(
        isLeft: true,
        isFirst: false,
        isLast: false,
      );

      expect(
        middle.shouldRepaint(
          const TrailPathPainter(isLeft: false, isFirst: false, isLast: false),
        ),
        isTrue,
      );
      expect(
        middle.shouldRepaint(
          const TrailPathPainter(isLeft: true, isFirst: true, isLast: false),
        ),
        isTrue,
      );
    });
  });
}

double _luminance(Color c) => c.computeLuminance();

double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
