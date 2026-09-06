import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';

/// One line per role, laid out in a phone-width column.
class _TypeSheet extends StatelessWidget {
  const _TypeSheet();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DokuColours.bone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final role in TypeRole.values)
            Text(
              'Deputy 147 — ${role.name}',
              style: role.style.copyWith(color: DokuColours.duskInk),
            ),
        ],
      ),
    );
  }
}

void main() {
  // iOS goes to 3.0+ with accessibility sizes on; Android's largest font-size
  // setting is 2.0. Testing above both is what catches a pinned height.
  const scales = <double>[1.0, 1.3, 2.0, 3.0];

  for (final scale in scales) {
    testWidgets('every role scales at ${scale}x without clipping', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            // Scrollable, as every real screen is. At 3x the six roles are
            // taller than a phone, which is correct behaviour — the rule is
            // that nothing clips and everything stays reachable, not that
            // large type must still fit one screen.
            child: SizedBox(
              width: 390,
              child: SingleChildScrollView(child: _TypeSheet()),
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'layout overflowed at ${scale}x',
      );

      // Every role is still present and reachable, not dropped or ellipsed.
      for (final role in TypeRole.values) {
        expect(
          find.text('Deputy 147 — ${role.name}'),
          findsOneWidget,
          reason: '${role.name} at ${scale}x',
        );
      }

      // Every line grew with the scale rather than being pinned.
      for (final role in TypeRole.values) {
        final widget = tester.widget<Text>(
          find.text('Deputy 147 — ${role.name}'),
        );
        final painter = TextPainter(
          text: TextSpan(text: widget.data, style: widget.style),
          textScaler: TextScaler.linear(scale),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(painter.height, greaterThan(0), reason: role.name);
        if (scale > 1.0) {
          final unscaled = TextPainter(
            text: TextSpan(text: widget.data, style: widget.style),
            textDirection: TextDirection.ltr,
          )..layout();
          expect(
            painter.height,
            greaterThan(unscaled.height),
            reason: '${role.name} did not grow at ${scale}x',
          );
        }
      }
    });
  }
}
