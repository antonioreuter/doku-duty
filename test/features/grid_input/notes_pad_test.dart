import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';

Future<List<PadKey>> _pump(
  WidgetTester tester, {
  bool notesMode = false,
  bool provisionalInk = false,
}) async {
  final pressed = <PadKey>[];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: NumberPad(
          notesMode: notesMode,
          provisionalInk: provisionalInk,
          onKey: pressed.add,
        ),
      ),
    ),
  );
  return pressed;
}

/// The semantics node a screen reader is handed for the key drawn as [glyph].
SemanticsNode _nodeFor(WidgetTester tester, String glyph) =>
    tester.getSemantics(
      find
          .ancestor(of: find.text(glyph), matching: find.byType(Semantics))
          .first,
    );

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

  // The second ink's three controls. The ink toggle is the axis (D-89); clear
  // and **promote** are the two ways a chain test ends (D-11, D-91).
  group('the provisional controls', () {
    const glyphs = <String, Type>{
      '~': InkToggleKey,
      '✕': ClearProvisionalKey,
      '✓': PromoteProvisionalKey,
    };

    testWidgets('each key fires its own action', (tester) async {
      for (final entry in glyphs.entries) {
        final pressed = await _pump(tester);

        expect(find.text(entry.key), findsOneWidget);
        await tester.tap(find.text(entry.key));
        await tester.pump();

        expect(pressed.single.runtimeType, entry.value);
      }
    });

    testWidgets('each holds the 44pt minimum like every other key', (
      tester,
    ) async {
      await _pump(tester);

      for (final glyph in glyphs.keys) {
        final size = tester.getSize(
          find
              .ancestor(of: find.text(glyph), matching: find.byType(SizedBox))
              .first,
        );
        expect(
          size.width,
          greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
          reason: glyph,
        );
        expect(
          size.height,
          greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
          reason: glyph,
        );
      }
    });

    // Constraint 1: a disabled control is a small failure state. A board with
    // no **provisional note** is the ordinary case for two of these three, and
    // neither may grey out because of it.
    testWidgets('none is ever disabled', (tester) async {
      final pressed = await _pump(tester);

      for (final glyph in glyphs.keys) {
        await tester.tap(find.text(glyph));
        await tester.tap(find.text(glyph));
        await tester.pump();
      }

      expect(pressed, hasLength(glyphs.length * 2));
    });

    // The ink in force has to be readable without marking a digit to find out
    // (constraint 5).
    testWidgets('the ink toggle reports itself selected', (tester) async {
      // Read before re-pumping: a semantics handle does not survive a new tree.
      await _pump(tester, provisionalInk: true);
      final on = tester.getSemantics(find.text('~')).flagsCollection.isSelected;
      final settledToggle = tester
          .getSemantics(find.text('✎'))
          .flagsCollection
          .isSelected;

      await _pump(tester);
      final off = tester
          .getSemantics(find.text('~'))
          .flagsCollection
          .isSelected;

      expect(on, isNot(off));
      // The same "selected" the notes toggle reports when *it* is in force, so
      // the ink is read the way every other held control on the pad is — and
      // it is the ink that is being read, not notes mode, which was off in
      // both pumps.
      expect(settledToggle, off);
    }, semanticsEnabled: true);

    // The two axes are independent (D-89): neither control reports the other's
    // state.
    testWidgets('the ink toggle is not the notes toggle', (tester) async {
      await _pump(tester, notesMode: true);
      final inkOffNotesOn = tester
          .getSemantics(find.text('~'))
          .flagsCollection
          .isSelected;
      final notesOn = tester
          .getSemantics(find.text('✎'))
          .flagsCollection
          .isSelected;

      await _pump(tester, provisionalInk: true);
      final inkOnNotesOff = tester
          .getSemantics(find.text('~'))
          .flagsCollection
          .isSelected;
      final notesOff = tester
          .getSemantics(find.text('✎'))
          .flagsCollection
          .isSelected;

      // Each control reports its own axis and neither reports the other's
      // (D-89).
      expect(inkOffNotesOn, isNot(inkOnNotesOff));
      expect(notesOn, isNot(notesOff));
      expect(inkOffNotesOn, notesOff);
    }, semanticsEnabled: true);

    testWidgets('clear and promote are told apart by name', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      final clear = _nodeFor(tester, '✕');
      final promote = _nodeFor(tester, '✓');

      expect(clear.label, 'Clear provisional notes');
      expect(promote.label, 'Promote provisional notes');
      expect(clear.label, isNot(promote.label));
      expect(_nodeFor(tester, '~').label, 'Provisional ink');

      for (final node in <SemanticsNode>[clear, promote]) {
        // The glyph is decoration: a screen reader reads the name and never
        // the symbol.
        expect(node.label, isNot(contains('✕')));
        expect(node.label, isNot(contains('✓')));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }

      handle.dispose();
    });

    // A mis-tap on clear discards the work the player meant to keep, so it
    // does not sit among the keys a player taps constantly.
    testWidgets('clear and promote sit together, away from the digits', (
      tester,
    ) async {
      await _pump(tester);

      final clear = tester.getCenter(find.text('✕'));
      final promote = tester.getCenter(find.text('✓'));
      expect(clear.dy, promote.dy, reason: 'the two share a row');

      for (final glyph in <String>['1', '9', '⌫', '↶', '✎']) {
        expect(
          tester.getCenter(find.text(glyph)).dy,
          lessThan(clear.dy),
          reason: '\$glyph is tapped constantly and sits above the clear row',
        );
      }
    });
  });
}
