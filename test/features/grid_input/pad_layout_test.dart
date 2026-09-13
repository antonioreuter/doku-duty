import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';

/// The pad's own D-92: it grows with the reader's text size until the row it
/// sits in is full, and then it stops.
///
/// A grid cell is the screen divided by nine and a pad key is the screen
/// divided by five — neither can reflow, so neither can grow without a
/// ceiling. Uncapped, the row of five digits needs 480pt at 2× against a 393pt
/// phone: ordinary "Larger Text", and the row runs off the screen.

/// The widest phone this has to hold on, and a narrow one.
const double _phone = 393;

Future<void> _pump(
  WidgetTester tester, {
  required double scale,
  double width = _phone,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: NumberPad(onKey: (_) {}),
          ),
        ),
      ),
    ),
  );
}

Size _keyBox(WidgetTester tester, String glyph) => tester.getSize(
  find.ancestor(of: find.text(glyph), matching: find.byType(SizedBox)).first,
);

double _glyphSize(WidgetTester tester, String glyph) =>
    tester.widget<Text>(find.text(glyph)).style!.fontSize!;

void main() {
  group('the pad fits the width it is given', () {
    testWidgets('at every text size a reader can ask for', (tester) async {
      for (final scale in <double>[1, 1.5, 2, 3, 5]) {
        await _pump(tester, scale: scale);

        expect(tester.takeException(), isNull, reason: '${scale}x overflowed');
        for (final glyph in const <String>['1', '5', '9', '⌫', '✓']) {
          final rect = tester.getRect(find.text(glyph));
          expect(
            rect.right,
            lessThanOrEqualTo(_phone),
            reason: '$glyph is off the right edge at ${scale}x',
          );
          expect(
            rect.left,
            greaterThanOrEqualTo(0),
            reason: '$glyph at ${scale}x',
          );
        }
      }
    });

    // The floor outranks the cap, and the trade-off is deliberate: below about
    // 260pt five 44pt keys do not fit, and the row is cut rather than the keys
    // shrunk. A key that cannot be hit is worse than a row that has to be cut
    // (D-84), and no phone is that narrow — the smallest is 320pt.
    testWidgets('a pad too narrow for five keys keeps the 44pt floor', (
      tester,
    ) async {
      // Collected rather than left to fail the test: every row this narrow
      // overflows, and that is the decision being asserted, not a defect.
      final overflows = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = overflows.add;
      await _pump(tester, scale: 3, width: 200);
      FlutterError.onError = previous;

      expect(
        _keyBox(tester, '1').shortestSide,
        DokuLayout.minimumTapTarget,
        reason: '200pt cannot hold five 44pt keys, and the key still holds 44',
      );
      expect(overflows, isNotEmpty, reason: 'the row is cut at this width');
      expect(
        overflows.every(
          (error) => error.exception.toString().contains('overflowed'),
        ),
        isTrue,
        reason: 'the only complaint is the cut row',
      );
    });

    testWidgets('every key holds the floor at every size', (tester) async {
      for (final scale in <double>[1, 1.5, 2, 3, 5]) {
        // Phone widths: the pad's bound is the width it is given, and how
        // four rows fit *vertically* is the screen's business, not the pad's.
        for (final width in <double>[320, _phone]) {
          await _pump(tester, scale: scale, width: width);
          expect(
            _keyBox(tester, '7').shortestSide,
            greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
            reason: '${scale}x at ${width}pt',
          );
          expect(
            tester.takeException(),
            isNull,
            reason:
                'a real phone width never overflows: ${scale}x at ${width}pt',
          );
        }
      }
    });
  });

  group('the cap is a ceiling, not a fixed size', () {
    testWidgets('the default scale is untouched', (tester) async {
      await _pump(tester, scale: 1);

      expect(_keyBox(tester, '1').width, DokuLayout.minimumTapTarget);
      expect(_glyphSize(tester, '1'), 22);
    });

    testWidgets('type still grows until it stops fitting', (tester) async {
      await _pump(tester, scale: 1);
      final atOne = _keyBox(tester, '1').width;
      await _pump(tester, scale: 1.3);
      final atMore = _keyBox(tester, '1').width;

      expect(atMore, greaterThan(atOne));
    });

    testWidgets('a narrower pad caps sooner', (tester) async {
      await _pump(tester, scale: 3, width: 800);
      final wide = _keyBox(tester, '1').width;
      await _pump(tester, scale: 3, width: _phone);
      final narrow = _keyBox(tester, '1').width;

      expect(narrow, lessThan(wide));
    });
  });

  // A capped key holding an uncapped glyph is the same overflow one layer in.
  testWidgets('the glyph scales with the key it sits in', (tester) async {
    for (final scale in <double>[1, 2, 3, 5]) {
      await _pump(tester, scale: scale);

      final side = _keyBox(tester, '1').width;
      expect(
        _glyphSize(tester, '1'),
        lessThanOrEqualTo(side),
        reason: 'the glyph is larger than its key at ${scale}x',
      );
      // The same proportion the default has, so a key does not change shape as
      // it caps.
      expect(
        _glyphSize(tester, '1') / side,
        closeTo(22 / DokuLayout.minimumTapTarget, 0.001),
        reason: '${scale}x',
      );
    }
  });
}
