import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/pad_tools.dart';

/// The narrowest phone the app targets (D-84).
const double _phone = 320;

Future<void> _pump(
  WidgetTester tester, {
  double scale = 1,
  double width = _phone,
  bool notesMode = false,
  bool hasProvisionalNotes = false,
}) async {
  // Top-left rather than centred, so a rect read back is the offset inside the
  // pad rather than the offset inside the test surface. Tall, because the point
  // here is horizontal fit and the reader's largest text size makes any pad
  // tall — how it is given vertical room is the screen's problem and is
  // covered where the screen is tested.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
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
}

/// The tappable box behind the digit or erase key drawn as [face].
Finder _keyOf(String face) =>
    find.ancestor(of: find.text(face), matching: find.byType(SizedBox)).first;

/// The chip behind [label] — the thing that is laid out, as opposed to the
/// text inside it, which is centred and moves when a label wraps.
Finder _chip(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(ConstrainedBox))
    .first;

void main() {
  group('a label never overflows its chip', () {
    // The longest labels are the two that end a chain test, and they are the
    // ones a truncation would hurt most: "Discard te…" and "Discard" are the
    // same control saying two different things.
    testWidgets('at every text size a reader can ask for', (tester) async {
      for (final scale in <double>[1, 1.3, 2, 3, 5]) {
        await _pump(
          tester,
          scale: scale,
          notesMode: true,
          hasProvisionalNotes: true,
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'the tools overflowed at ${scale}x',
        );

        for (final label in const <String>[
          'Notes',
          'Test',
          'Fill notes',
          'Undo',
          'Discard test',
          'Keep test',
        ]) {
          final rect = tester.getRect(find.text(label));
          expect(
            rect.left,
            greaterThanOrEqualTo(0),
            reason: '$label runs off the left at ${scale}x',
          );
          expect(
            rect.right,
            lessThanOrEqualTo(_phone),
            reason: '$label runs off the right at ${scale}x',
          );
        }
      }
    });

    testWidgets('every chip holds the 44pt floor at every size', (
      tester,
    ) async {
      for (final scale in <double>[1, 1.3, 2, 3]) {
        await _pump(
          tester,
          scale: scale,
          notesMode: true,
          hasProvisionalNotes: true,
        );

        for (final label in const <String>['Notes', 'Discard test']) {
          expect(
            tester.getSize(_chip(label)).height,
            greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
            reason: '$label at ${scale}x',
          );
        }
      }
    });
  });

  group('the default is three rows', () {
    // Four ragged rows is what this change exists to remove. The digits take
    // two and the tools take one, and the tools row only grows when the player
    // has started a chain test.
    testWidgets('digits on two rows, tools on one', (tester) async {
      await _pump(tester);

      final firstDigitRow = tester.getTopLeft(find.text('1')).dy;
      final secondDigitRow = tester.getTopLeft(find.text('6')).dy;
      final toolRow = tester.getTopLeft(_chip('Notes')).dy;

      expect(secondDigitRow, greaterThan(firstDigitRow));
      expect(toolRow, greaterThan(secondDigitRow));

      // The chips, not the words inside them: a label that wraps to two lines
      // is centred lower in a chip that is still on the same row.
      for (final label in const <String>['Fill notes', 'Undo']) {
        expect(
          tester.getTopLeft(_chip(label)).dy,
          toolRow,
          reason: '$label shares the tools row',
        );
      }
    });

    testWidgets('a chain test adds a fourth row, and only then', (
      tester,
    ) async {
      await _pump(tester, hasProvisionalNotes: true);

      final toolRow = tester.getTopLeft(_chip('Notes')).dy;
      expect(
        tester.getTopLeft(_chip('Discard test')).dy,
        greaterThan(toolRow),
        reason: 'the two ways a test ends sit together, below the rest',
      );
      expect(
        tester.getTopLeft(_chip('Keep test')).dy,
        tester.getTopLeft(_chip('Discard test')).dy,
      );
    });
  });

  group('the tools line up with the digits', () {
    // The old chrome rows were left-aligned and ragged — four keys then two,
    // each stopping short of the edge, which read as unfinished rather than
    // laid out. The tools now take exactly the width of the digit block above
    // them, so the pad is one shape.
    testWidgets('a tools row spans the digit block, edge to edge', (
      tester,
    ) async {
      await _pump(tester, hasProvisionalNotes: true);

      // Inner boxes on both sides: a digit key and a tool chip each sit inside
      // the same gutter, so comparing a key's box against a tool's slot would
      // be one gutter out and prove nothing.
      expect(
        tester.getRect(_chip('Notes')).left,
        moreOrLessEquals(tester.getRect(_keyOf('1')).left, epsilon: 0.5),
        reason: 'the first tool starts where the first digit does',
      );
      expect(
        tester.getRect(_chip('Undo')).right,
        moreOrLessEquals(tester.getRect(_keyOf('⌫')).right, epsilon: 0.5),
        reason: 'the last tool ends where the last key does',
      );
    });

    testWidgets('the chain-test row spans the same width', (tester) async {
      await _pump(tester, hasProvisionalNotes: true);

      expect(
        tester.getRect(_chip('Discard test')).left,
        moreOrLessEquals(tester.getRect(_chip('Notes')).left, epsilon: 0.5),
      );
      expect(
        tester.getRect(_chip('Keep test')).right,
        moreOrLessEquals(tester.getRect(_chip('Undo')).right, epsilon: 0.5),
      );
    });

    // A label that wraps must not leave its neighbours looking short.
    testWidgets('chips on a line are the same height', (tester) async {
      await _pump(tester, notesMode: true);

      final heights = <double>[
        for (final label in const <String>[
          'Notes',
          'Test',
          'Fill notes',
          'Undo',
        ])
          tester.getSize(_chip(label)).height,
      ];

      for (final height in heights) {
        expect(height, moreOrLessEquals(heights.first, epsilon: 0.5));
      }
    });
  });
}
