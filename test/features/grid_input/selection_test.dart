import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import 'support/recording_canvas.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

const Size _size = Size(360, 360);

RecordingCanvas _paint({int? selected}) {
  final canvas = RecordingCanvas();
  GridPainter(
    board: _board(),
    selectedCell: selected,
    textScale: 1,
    colours: GridColours.standard(),
  ).paint(canvas, _size);
  return canvas;
}

void main() {
  final colours = GridColours.standard();

  group('a tap selects the cell under it', () {
    testWidgets('the cell reported is the one that was touched', (
      tester,
    ) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox.fromSize(
              size: _size,
              child: PuzzleGrid(board: _board(), onCellTapped: tapped.add),
            ),
          ),
        ),
      );

      final metrics = GridMetrics.fit(_size);
      final origin = tester.getTopLeft(find.byType(PuzzleGrid));
      for (final cell in <int>[0, 4, 40, 44, 80]) {
        await tester.tapAt(origin + metrics.cellRect(cell).center);
        await tester.pump();
      }
      expect(tapped, <int>[0, 4, 40, 44, 80]);
    });

    testWidgets('a tap outside the grid reports nothing', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              // Wider than tall, so there is dead space either side.
              width: 500,
              height: 300,
              child: PuzzleGrid(board: _board(), onCellTapped: tapped.add),
            ),
          ),
        ),
      );

      final origin = tester.getTopLeft(find.byType(PuzzleGrid));
      await tester.tapAt(origin + const Offset(10, 150));
      await tester.pump();
      expect(tapped, isEmpty);
    });
  });

  group('peer highlighting', () {
    test('selecting a cell marks its twenty peers and itself', () {
      final canvas = _paint(selected: 40);
      final marked = canvas.filledWith(colours.focusFill);

      expect(marked, hasLength(21), reason: '20 peers plus the selected cell');

      final metrics = GridMetrics.fit(_size);
      final expected = <Rect>{
        metrics.cellRect(40),
        for (final peer in GridGeometry.peersOf(40)) metrics.cellRect(peer),
      };
      expect(marked.toSet(), expected);
    });

    test('the selected cell stays distinguishable from its peers', () {
      final canvas = _paint(selected: 40);
      final metrics = GridMetrics.fit(_size);

      final outlined = canvas.strokedWith(colours.focusLine);
      expect(outlined, hasLength(1));
      expect(
        outlined.single.center,
        _closeToOffset(metrics.cellRect(40).center),
      );
    });

    test('moving the selection marks the new cell and not the old one', () {
      final metrics = GridMetrics.fit(_size);
      final before = _paint(selected: 0).filledWith(colours.focusFill).toSet();
      final after = _paint(selected: 80).filledWith(colours.focusFill).toSet();

      expect(before, contains(metrics.cellRect(0)));
      expect(after, isNot(contains(metrics.cellRect(0))));
      expect(after, contains(metrics.cellRect(80)));
    });

    test('nothing is marked when nothing is selected', () {
      expect(_paint().filledWith(colours.focusFill), isEmpty);
    });

    test('a corner cell has the same twenty peers as a centre one', () {
      for (final cell in <int>[0, 8, 40, 72, 80]) {
        expect(
          _paint(selected: cell).filledWith(colours.focusFill),
          hasLength(21),
          reason: 'cell $cell',
        );
      }
    });
  });
}

Matcher _closeToOffset(Offset expected) => predicate<Offset>(
  (actual) => (actual - expected).distance < 0.01,
  'within 0.01 of $expected',
);
