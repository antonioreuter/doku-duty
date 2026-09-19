import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/pad_tools.dart';

/// The digits and the tools together, the way the puzzle screen builds them.
Future<List<PadKey>> _pump(
  WidgetTester tester, {
  bool notesMode = false,
  bool provisionalInk = false,
  bool hasProvisionalNotes = false,
}) async {
  final pressed = <PadKey>[];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            NumberPad(onKey: pressed.add),
            PadTools(
              notesMode: notesMode,
              provisionalInk: provisionalInk,
              hasProvisionalNotes: hasProvisionalNotes,
              onKey: pressed.add,
            ),
          ],
        ),
      ),
    ),
  );
  return pressed;
}

/// The semantics node a screen reader is handed for the control labelled
/// [label].
SemanticsNode _nodeFor(WidgetTester tester, String label) =>
    tester.getSemantics(
      find
          .ancestor(of: find.text(label), matching: find.byType(Semantics))
          .first,
    );

/// The tappable box behind the control labelled [label].
Size _chipSize(WidgetTester tester, String label) => tester.getSize(
  find
      .ancestor(of: find.text(label), matching: find.byType(ConstrainedBox))
      .first,
);

void main() {
  group('the tools are named, not drawn', () {
    testWidgets('every tool carries its name in words', (tester) async {
      await _pump(tester, notesMode: true, hasProvisionalNotes: true);

      for (final label in const <String>[
        'Notes',
        'Test',
        'Fill notes',
        'Undo',
        'Discard test',
        'Keep test',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    // The symbols these replaced. `~` for which ink a note is written in and
    // `⁙` for filling the board are not guessable by anyone who has not read
    // the source, and `✕` beside `✓` reads as cancel beside confirm — which
    // advertises the answer-checking this product does not do (D-04).
    testWidgets('no tool is a bare symbol', (tester) async {
      await _pump(tester, notesMode: true, hasProvisionalNotes: true);

      for (final glyph in const <String>['✎', '~', '⁙', '↶', '✕', '✓']) {
        expect(find.text(glyph), findsNothing, reason: glyph);
      }
    });

    testWidgets('the label a player reads is the name a reader hears', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, notesMode: true, hasProvisionalNotes: true);

      for (final label in const <String>[
        'Notes',
        'Test',
        'Fill notes',
        'Undo',
        'Discard test',
        'Keep test',
      ]) {
        final node = _nodeFor(tester, label);
        expect(
          node.label,
          label,
          reason: '$label is announced as its own name',
        );
        expect(node.flagsCollection.isButton, isTrue);
        // Naming a button a screen reader cannot press is the worse bug, so
        // the tap action has to survive the glyph's exclusion.
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      }

      handle.dispose();
    });
  });

  group('what is on screen, and when', () {
    testWidgets('a player who has not turned notes on sees three tools', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Fill notes'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(
        find.text('Test'),
        findsNothing,
        reason:
            'the ink decides what the next note is written in, and in '
            'value mode there is no next note',
      );
      expect(find.text('Discard test'), findsNothing);
      expect(find.text('Keep test'), findsNothing);
    });

    testWidgets('turning notes on brings the ink control', (tester) async {
      await _pump(tester);
      expect(find.text('Test'), findsNothing);

      await _pump(tester, notesMode: true);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('turning notes off takes it away again', (tester) async {
      await _pump(tester, notesMode: true, provisionalInk: true);
      expect(find.text('Test'), findsOneWidget);

      await _pump(tester, provisionalInk: true);
      expect(
        find.text('Test'),
        findsNothing,
        reason: 'the ink is remembered by the session, not by the control',
      );
    });

    testWidgets('the chain-test controls arrive with the first provisional '
        'note', (tester) async {
      await _pump(tester, notesMode: true);
      expect(find.text('Discard test'), findsNothing);
      expect(find.text('Keep test'), findsNothing);

      await _pump(tester, notesMode: true, hasProvisionalNotes: true);
      expect(find.text('Discard test'), findsOneWidget);
      expect(find.text('Keep test'), findsOneWidget);
    });

    testWidgets('and leave with the last one', (tester) async {
      await _pump(tester, hasProvisionalNotes: true);
      expect(find.text('Discard test'), findsOneWidget);

      await _pump(tester);
      expect(
        find.text('Discard test'),
        findsNothing,
        reason: 'there is nothing left to discard',
      );
    });

    // They are shown whether or not notes mode is on: a hypothesis on the
    // board is a hypothesis on the board, and the player may want to end it
    // while placing values.
    testWidgets('they do not depend on notes mode', (tester) async {
      await _pump(tester, hasProvisionalNotes: true);

      expect(find.text('Discard test'), findsOneWidget);
      expect(find.text('Keep test'), findsOneWidget);
    });
  });

  group('pressing', () {
    testWidgets('each tool fires its own action', (tester) async {
      final pressed = await _pump(
        tester,
        notesMode: true,
        hasProvisionalNotes: true,
      );

      for (final label in const <String>[
        'Notes',
        'Test',
        'Fill notes',
        'Undo',
        'Discard test',
        'Keep test',
      ]) {
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect(pressed[0], isA<NotesToggleKey>());
      expect(pressed[1], isA<InkToggleKey>());
      expect(pressed[2], isA<AutoNotesKey>());
      expect(pressed[3], isA<UndoKey>());
      expect(pressed[4], isA<ClearProvisionalKey>());
      expect(pressed[5], isA<PromoteProvisionalKey>());
    });

    // Constraint 1: a disabled control is a small failure state, and this
    // product does not have those. A tool with no work to do is absent, which
    // is a different thing.
    testWidgets('nothing on screen ever refuses a press', (tester) async {
      final pressed = await _pump(
        tester,
        notesMode: true,
        hasProvisionalNotes: true,
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Notes'));
        await tester.tap(find.text('Discard test'));
        await tester.pump();
      }
      expect(pressed, hasLength(6));
    });
  });

  group('the mode in force is readable', () {
    testWidgets('the notes tool reports itself selected', (tester) async {
      await _pump(tester, notesMode: true);
      final on = _nodeFor(tester, 'Notes').flagsCollection.isSelected;

      await _pump(tester);
      final off = _nodeFor(tester, 'Notes').flagsCollection.isSelected;

      expect(on, isNot(off));
    }, semanticsEnabled: true);

    testWidgets('the ink tool reports itself selected', (tester) async {
      await _pump(tester, notesMode: true, provisionalInk: true);
      final on = _nodeFor(tester, 'Test').flagsCollection.isSelected;

      await _pump(tester, notesMode: true);
      final off = _nodeFor(tester, 'Test').flagsCollection.isSelected;

      expect(on, isNot(off));
    }, semanticsEnabled: true);

    // Two axes, not one (D-89). Notes mode says whether a digit writes a note;
    // the ink says which kind. Neither is the other.
    testWidgets('the ink tool is not the notes tool', (tester) async {
      final pressed = await _pump(tester, notesMode: true);

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(pressed.single, isA<InkToggleKey>());
      expect(pressed.whereType<NotesToggleKey>(), isEmpty);
    });
  });

  group('the digits still behave', () {
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

    // Only a digit has an opposite-mode entry to make. Holding erase is
    // treated as pressing it, rather than as a gesture that does nothing.
    testWidgets('holding erase just presses it', (tester) async {
      final pressed = await _pump(tester);

      await tester.longPress(find.text('⌫'));
      await tester.pump();

      expect(pressed.single, isA<EraseKey>());
      expect(pressed.whereType<DigitLongPressKey>(), isEmpty);
    });
  });

  group('the tap target', () {
    testWidgets('every tool holds the 44pt minimum', (tester) async {
      await _pump(tester, notesMode: true, hasProvisionalNotes: true);

      for (final label in const <String>[
        'Notes',
        'Test',
        'Fill notes',
        'Undo',
        'Discard test',
        'Keep test',
      ]) {
        expect(
          _chipSize(tester, label).height,
          greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
          reason: '$label is too short to hit',
        );
      }
    });
  });
}
