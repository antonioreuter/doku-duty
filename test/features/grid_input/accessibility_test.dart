import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

import 'support/recording_canvas.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

Widget _host(Widget child, {double textScale = 1}) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  group('dynamic type', () {
    // The grid is a fixed nine-by-nine: type that grows must stay inside a
    // cell rather than pushing the board around.
    testWidgets('the grid holds its shape at the largest type', (tester) async {
      for (final scale in <double>[1, 1.5, 2, 3]) {
        await tester.pumpWidget(
          _host(
            Center(
              child: SizedBox(
                width: 360,
                height: 360,
                child: PuzzleGrid(board: _board(), onCellTapped: (_) {}),
              ),
            ),
            textScale: scale,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'at ${scale}x');
        expect(
          tester.getSize(find.byType(PuzzleGrid)),
          const Size(360, 360),
          reason: 'the board does not grow with the type at ${scale}x',
        );
      }
    });

    testWidgets('the pad targets grow with the type, never shrink', (
      tester,
    ) async {
      var previous = 0.0;
      for (final scale in <double>[0.8, 1, 1.5, 2]) {
        await tester.pumpWidget(
          _host(
            Center(child: NumberPad(onKey: (_) {})),
            textScale: scale,
          ),
        );
        await tester.pump();

        final box = find
            .ancestor(of: find.text('1'), matching: find.byType(SizedBox))
            .first;
        final side = tester.getSize(box).width;

        expect(
          side,
          greaterThanOrEqualTo(DokuLayout.minimumTapTarget),
          reason: 'below the floor at ${scale}x',
        );
        expect(side, greaterThanOrEqualTo(previous), reason: 'at ${scale}x');
        previous = side;
      }
    });
  });

  // Constraint 5. A player who cannot separate the two hues must still be able
  // to see which cell is selected.
  test('the selected cell is identifiable without colour', () {
    final canvas = RecordingCanvas();
    GridPainter(
      board: _board(),
      selectedCell: 40,
      textScale: 1,
      colours: GridColours.standard(),
    ).paint(canvas, const Size(360, 360));

    final metrics = GridMetrics.fit(const Size(360, 360));
    final outlined = canvas.strokedWith(GridColours.standard().focusLine);

    expect(outlined, hasLength(1), reason: 'exactly the selected cell');
    expect(
      (outlined.single.center - metrics.cellRect(40).center).distance,
      lessThan(0.01),
    );
  });

  group('reduce effects', () {
    testWidgets('the pad still works with motion switched off', (tester) async {
      final pressed = <PadKey>[];
      await tester.pumpWidget(
        _host(Center(child: NumberPad(reduceMotion: true, onKey: pressed.add))),
      );

      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('⌫'));
      await tester.pump();

      expect(pressed, hasLength(2));
      expect(tester.takeException(), isNull);
    });

    test('the puzzle screen passes the setting to the pad and the haptics', () {
      // Wired rather than defaulted: a player who asked for less motion asked
      // for less of all of it, and a pad that kept animating would be the one
      // place the switch did not reach.
      final source = File(
        'lib/features/grid_input/presentation/puzzle_screen.dart',
      ).readAsStringSync();
      expect(source, contains('reduceMotion: widget.reduceMotion'));
      expect(source, contains('isEnabled: !widget.reduceMotion'));
      expect(source, contains('reduceEffectsProvider'));
      expect(source, contains('disableAnimationsOf'));
    });
  });

  // What `add-note-automation` added, checked against constraint 5 and the
  // 44pt floor.
  group('note automation', () {
    testWidgets('the auto-notes key meets the tap target and is labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Center(child: NumberPad(onKey: (_) {}))));

      final box = find
          .ancestor(of: find.text('⁙'), matching: find.byType(SizedBox))
          .first;
      final size = tester.getSize(box);
      expect(size.width, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));
      expect(size.height, greaterThanOrEqualTo(DokuLayout.minimumTapTarget));

      final node = tester.getSemantics(
        find
            .ancestor(of: find.text('⁙'), matching: find.byType(Semantics))
            .first,
      );
      expect(node.label, 'Fill notes');

      handle.dispose();
    });

    // Constraint 5. A lit cell holds the digit it is lit for, so the state is
    // readable without seeing the tint at all.
    test('a highlighted cell carries the digit, not only the colour', () {
      var board = Board.forPuzzle(
        givens: (Grid.parse(_clues) as ValidGrid).grid,
      );
      board = (board.toggleNote(2, 4) as EditApplied).board;

      final painter = GridPainter(
        board: board,
        selectedCell: null,
        highlightedDigit: 4,
        textScale: 1,
        colours: GridColours.standard(),
      );
      final canvas = RecordingCanvas();
      painter.paint(canvas, const Size(360, 360));

      final metrics = GridMetrics.fit(const Size(360, 360));
      final lit = canvas.filledWith(GridColours.standard().candidateFill);

      // Every cell that got the tint holds the digit that earned it.
      for (final rect in lit) {
        final cell = metrics.cellAt(rect.center);
        expect(cell, isNotNull, reason: 'a tint landed outside the grid');
        expect(
          board.digitAt(cell!) == 4 || board.notesAt(cell).contains(4),
          isTrue,
          reason: 'cell $cell is lit but holds no 4',
        );
      }
      expect(lit, isNotEmpty);
    });

    // **Candidate highlighting** is a state, not an animation, so nothing
    // about it moves with the reduce-effects setting.
    test('highlighting is unaffected by reduce effects', () {
      final source = File(
        'lib/features/grid_input/presentation/grid_painter.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('reduceMotion')));
      expect(source, isNot(contains('reduceEffects')));
    });
  });

  // Every key on the pad, so the glyph cannot creep back into an announcement
  // one key at a time. The symbols here — ⌫, ↶, ✎, ⁙ — are decoration; read
  // aloud they are noise at best and unreadable at worst.
  group('the pad announces names, never glyphs', () {
    testWidgets('each key reads as its label and is pressable', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Center(child: NumberPad(onKey: (_) {}))));

      const expected = <String, String>{
        '1': '1',
        '5': '5',
        '9': '9',
        '⌫': 'Erase',
        '↶': 'Undo',
        '✎': 'Notes',
        '⁙': 'Fill notes',
      };

      for (final entry in expected.entries) {
        final node = tester.getSemantics(
          find
              .ancestor(
                of: find.text(entry.key),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(node.label, entry.value, reason: 'the ${entry.key} key');
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: 'the ${entry.key} key is named but cannot be pressed',
        );
      }

      handle.dispose();
    });

    // Constraint 5 on the pad: the mode is readable without seeing which key
    // is painted differently.
    testWidgets('a held key and the notes mode report as selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Center(
            child: NumberPad(lockedDigit: 4, notesMode: true, onKey: (_) {}),
          ),
        ),
      );

      SemanticsNode nodeFor(String glyph) => tester.getSemantics(
        find
            .ancestor(of: find.text(glyph), matching: find.byType(Semantics))
            .first,
      );

      expect(nodeFor('4').flagsCollection.isSelected, Tristate.isTrue);
      expect(nodeFor('✎').flagsCollection.isSelected, Tristate.isTrue);
      expect(nodeFor('5').flagsCollection.isSelected, Tristate.isFalse);

      handle.dispose();
    });
  });
}
