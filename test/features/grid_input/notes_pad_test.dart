import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';

Future<List<PadKey>> _pump(
  WidgetTester tester, {
  bool notesMode = false,
}) async {
  final pressed = <PadKey>[];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: NumberPad(notesMode: notesMode, onKey: pressed.add),
      ),
    ),
  );
  return pressed;
}

void main() {
  testWidgets('the pad carries a notes toggle', (tester) async {
    final pressed = await _pump(tester);

    expect(find.text('✎'), findsOneWidget);
    await tester.tap(find.text('✎'));
    await tester.pump();

    expect(pressed.single, isA<NotesToggleKey>());
  });

  testWidgets('the toggle holds the 44pt minimum like every other key', (
    tester,
  ) async {
    await _pump(tester);

    final box = find
        .ancestor(of: find.text('✎'), matching: find.byType(SizedBox))
        .first;
    final size = tester.getSize(box);
    expect(size.width, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
    expect(size.height, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
  });

  // Constraint 1 applies to controls: nothing is disabled, ever.
  testWidgets('the toggle never refuses a press', (tester) async {
    final pressed = await _pump(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('✎'));
      await tester.pump();
    }
    expect(pressed, hasLength(4));
  });

  testWidgets('the toggle shows which mode is in force', (tester) async {
    // Read before re-pumping: a semantics handle does not survive a new tree.
    await _pump(tester, notesMode: true);
    final on = tester.getSemantics(find.text('✎')).flagsCollection.isSelected;

    await _pump(tester);
    final off = tester.getSemantics(find.text('✎')).flagsCollection.isSelected;

    expect(on, isNot(off));
  }, semanticsEnabled: true);

  testWidgets('long-pressing a digit reports it as the other mode', (
    tester,
  ) async {
    final pressed = await _pump(tester);

    await tester.longPress(find.text('7'));
    await tester.pump();

    expect(pressed.single, isA<DigitLongPressKey>());
    expect((pressed.single as DigitLongPressKey).digit, 7);
  });

  testWidgets('a short press is still an ordinary digit', (tester) async {
    final pressed = await _pump(tester);

    await tester.tap(find.text('7'));
    await tester.pump();

    expect(pressed.single, isA<DigitKey>());
  });

  // Only a digit has an opposite-mode entry to make. Holding erase or undo is
  // treated as pressing it, rather than as a gesture that does nothing — a
  // control that ignores a deliberate press is a small failure state.
  testWidgets('holding erase or undo just presses it', (tester) async {
    final pressed = await _pump(tester);

    await tester.longPress(find.text('⌫'));
    await tester.pump();
    await tester.longPress(find.text('↶'));
    await tester.pump();

    expect(pressed, hasLength(2));
    expect(pressed[0], isA<EraseKey>());
    expect(pressed[1], isA<UndoKey>());
    expect(
      pressed.whereType<DigitLongPressKey>(),
      isEmpty,
      reason: 'only digits carry an opposite-mode entry',
    );
  });

  // The control for **auto-notes**. Free and unmetered here — the charge is
  // `add-perks` (change 19).
  group('the auto-notes key', () {
    testWidgets('the pad carries it', (tester) async {
      final pressed = await _pump(tester);

      expect(find.text('⁙'), findsOneWidget);
      await tester.tap(find.text('⁙'));
      await tester.pump();

      expect(pressed.single, isA<AutoNotesKey>());
    });

    testWidgets('it holds the 44pt minimum like every other key', (
      tester,
    ) async {
      await _pump(tester);

      final box = find
          .ancestor(of: find.text('⁙'), matching: find.byType(SizedBox))
          .first;
      final size = tester.getSize(box);
      expect(size.width, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
      expect(size.height, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
    });

    testWidgets('it carries a label a screen reader can read', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      // What a screen reader is actually handed for that key, not what the
      // widget was asked for: the glyph alone says nothing.
      final node = tester.getSemantics(
        find
            .ancestor(of: find.text('⁙'), matching: find.byType(Semantics))
            .first,
      );
      // The label and nothing else. The glyph is decoration and is excluded,
      // so a screen reader never reads the symbol aloud.
      expect(node.label, 'Fill notes');
      expect(node.flagsCollection.isButton, isTrue);
      // Naming a button a screen reader cannot press would be the worse bug,
      // so the tap action has to survive the exclusion.
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      // The same shape the notes toggle has, so this key is not a special
      // case a screen reader meets differently.
      final toggle = tester.getSemantics(
        find
            .ancestor(of: find.text('✎'), matching: find.byType(Semantics))
            .first,
      );
      expect(toggle.label, 'Notes');

      handle.dispose();
    });

    testWidgets('it is never disabled', (tester) async {
      // Constraint 1: a disabled control is a small failure state, and this
      // product does not have those.
      final pressed = await _pump(tester);

      await tester.tap(find.text('⁙'));
      await tester.tap(find.text('⁙'));
      await tester.pump();

      expect(pressed, hasLength(2));
    });

    testWidgets('it is not the notes toggle', (tester) async {
      final pressed = await _pump(tester, notesMode: true);

      await tester.tap(find.text('⁙'));
      await tester.pump();

      // The toggle changes what a digit press writes; this fills the board.
      expect(pressed.single, isA<AutoNotesKey>());
      expect(pressed.single, isNot(isA<NotesToggleKey>()));
    });
  });
}
