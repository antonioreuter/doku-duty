import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/pad_tools.dart';

/// The pad on a real platform, at the real text sizes a reader can ask for.
///
/// Host tests lay this out with Flutter's own test surface and the bundled
/// font. What this adds is the platform's text shaping: a label that fits in a
/// chip on macOS and wraps to three lines on a phone would pass every host test
/// and still push the pad off the screen.
///
/// Haptics are not covered here and cannot be. A simulator reports success for
/// a haptic it never played, so telling the light impact from the medium one
/// stays a manual check on real hardware.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester, {
    required double scale,
    required bool notesMode,
    required bool hasProvisionalNotes,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  NumberPad(onKey: (_) {}),
                  PadTools(
                    notesMode: notesMode,
                    provisionalInk: false,
                    hasProvisionalNotes: hasProvisionalNotes,
                    onKey: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('every tool is named and inside the pad on this platform', (
    tester,
  ) async {
    for (final scale in <double>[1, 1.3, 2, 3]) {
      await pump(
        tester,
        scale: scale,
        notesMode: true,
        hasProvisionalNotes: true,
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'the pad overflowed at ${scale}x on this platform',
      );

      for (final label in const <String>[
        'Notes',
        'Test',
        'Fill notes',
        'Undo',
        'Discard test',
        'Keep test',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label at ${scale}x');

        final rect = tester.getRect(find.text(label));
        expect(
          rect.left,
          greaterThanOrEqualTo(-0.5),
          reason: '$label runs off the left at ${scale}x',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(320.5),
          reason:
              '$label runs off the right at ${scale}x — the platform '
              'shaped this label wider than the host did',
        );
      }
    }
  });

  testWidgets('every chip is big enough to hit on this platform', (
    tester,
  ) async {
    await pump(tester, scale: 1, notesMode: true, hasProvisionalNotes: true);

    for (final label in const <String>[
      'Notes',
      'Test',
      'Fill notes',
      'Undo',
      'Discard test',
      'Keep test',
    ]) {
      final chip = find
          .ancestor(of: find.text(label), matching: find.byType(ConstrainedBox))
          .first;
      final size = tester.getSize(chip);
      expect(
        size.height,
        greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
        reason: '$label is too short to hit',
      );
      expect(size.width, greaterThan(0), reason: '$label has no width to hit');
    }
  });

  testWidgets('the default pad shows three tools and no more', (tester) async {
    await pump(tester, scale: 1, notesMode: false, hasProvisionalNotes: false);

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Fill notes'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Test'), findsNothing);
    expect(find.text('Discard test'), findsNothing);
    expect(find.text('Keep test'), findsNothing);
  });
}
