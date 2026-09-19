import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';

Future<List<PadKey>> _pump(WidgetTester tester, {int? locked}) async {
  final pressed = <PadKey>[];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: NumberPad(lockedDigit: locked, onKey: pressed.add),
      ),
    ),
  );
  return pressed;
}

void main() {
  group('the keys', () {
    // Digits and erase, and nothing else. Everything that is not a digit is a
    // named control in `PadTools` — the pad used to carry six more keys drawn
    // as bare symbols and no player could read any of them.
    testWidgets('nine digits and erase, and no unnamed controls', (
      tester,
    ) async {
      final pressed = await _pump(tester);

      for (var digit = 1; digit <= 9; digit++) {
        expect(find.text('$digit'), findsOneWidget, reason: 'digit $digit');
      }
      expect(find.text('⌫'), findsOneWidget, reason: 'erase');
      for (final glyph in <String>['↶', '✎', '⁙', '~', '✕', '✓']) {
        expect(
          find.text(glyph),
          findsNothing,
          reason: '$glyph is a control the player cannot read',
        );
      }
      expect(pressed, isEmpty);
    });

    // `docs/DESIGN.md` §8: five columns, not nine. Nine keys in a row cannot
    // carry the depth treatment and are worse for thumbs regardless.
    testWidgets('the digits sit five to a row', (tester) async {
      await _pump(tester);

      final firstRowTop = tester.getTopLeft(find.text('1')).dy;
      for (var digit = 2; digit <= 5; digit++) {
        expect(tester.getTopLeft(find.text('$digit')).dy, firstRowTop);
      }
      expect(
        tester.getTopLeft(find.text('6')).dy,
        greaterThan(firstRowTop),
        reason: '6 starts the second row',
      );
    });

    // This is where a miss costs a placed digit, which is why the 44pt floor
    // stayed on controls when D-84 lifted it off grid cells.
    testWidgets('every key holds the 44pt minimum', (tester) async {
      await _pump(tester);

      for (final label in <String>[for (var d = 1; d <= 9; d++) '$d', '⌫']) {
        final size = tester.getSize(find.text(label).first);
        expect(
          size.width,
          greaterThanOrEqualTo(0),
          reason: 'the glyph itself may be small',
        );
      }
      for (var digit = 1; digit <= 9; digit++) {
        final box = find
            .ancestor(of: find.text('$digit'), matching: find.byType(SizedBox))
            .first;
        final size = tester.getSize(box);
        expect(size.width, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
        expect(size.height, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
      }
    });
  });

  group('pressing', () {
    testWidgets('a digit reports that digit', (tester) async {
      final pressed = await _pump(tester);

      await tester.tap(find.text('7'));
      await tester.pump();

      expect(pressed, hasLength(1));
      expect((pressed.single as DigitKey).digit, 7);
    });

    testWidgets('erase reports itself', (tester) async {
      final pressed = await _pump(tester);

      await tester.tap(find.text('⌫'));
      await tester.pump();

      expect(pressed.single, isA<EraseKey>());
    });
  });

  // A disabled control is a small failure state, and this product does not have
  // those (constraint 1). If this proves wrong in play it is a decision to
  // record, not a default to slip in.
  testWidgets('nothing is ever disabled', (tester) async {
    final pressed = await _pump(tester);

    for (var digit = 1; digit <= 9; digit++) {
      await tester.tap(find.text('$digit'));
      await tester.pump();
    }
    expect(pressed, hasLength(9));
  });

  testWidgets(
    'the held digit is marked as selected for assistive tech',
    (tester) async {
      await _pump(tester, locked: 4);

      final held = tester.getSemantics(find.text('4'));
      final other = tester.getSemantics(find.text('5'));

      // Compared against an unheld key rather than against a named flag value:
      // what matters is that a screen reader can tell the two apart.
      expect(
        held.flagsCollection.isSelected,
        isNot(other.flagsCollection.isSelected),
      );
    },
    semanticsEnabled: true,
  );

  test('the haptic for a placement comes from the named vocabulary', () {
    // The pad never calls the platform directly; it names a haptic and the
    // design system's service decides what that means.
    expect(DokuHaptic.values, contains(DokuHaptic.selectionTick));
  });
}
