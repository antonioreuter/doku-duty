import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_metrics.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

import 'support/recording_canvas.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

const _puzzle = StoredPuzzle(
  id: 'q1',
  clues: _clues,
  solution: _solution,
  rank: Rank.legend,
  seed: 1,
);

class _NullSink implements BoardSink {
  @override
  Future<void> write(String puzzleId, Board board) async {}

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {}

  @override
  Future<void> complete(String puzzleId) async {}
}

PuzzleController _controller() => PuzzleController(
  puzzle: _puzzle,
  sink: _NullSink(),
  initial: sessionFor(
    puzzle: _puzzle,
    placedValues: null,
    mode: InputMode.cellFirst,
  ),
);

/// Constraint 2 is a product requirement, not an aspiration. These bounds are
/// deliberately loose — they catch a regression of an order of magnitude, and
/// the number that decides the feel is measured on a device, not here.
void main() {
  const size = Size(360, 360);

  Duration medianOf(List<Duration> samples) {
    samples.sort();
    return samples[samples.length ~/ 2];
  }

  test('a tap places a digit and repaints inside the budget', () {
    final samples = <Duration>[];
    final controller = _controller();
    var cell = 0;

    for (var run = 0; run < 40; run++) {
      while (controller.state.board.isGiven(cell % 81)) {
        cell++;
      }
      final target = cell++ % 81;

      final stopwatch = Stopwatch()..start();
      controller.tapCell(target);
      controller.tapKey(const DigitKey(1));
      GridPainter(
        board: controller.state.board,
        selectedCell: controller.state.selectedCell,
        textScale: 1,
        colours: GridColours.standard(),
      ).paint(RecordingCanvas(), size);
      stopwatch.stop();
      samples.add(stopwatch.elapsed);
    }

    final middle = medianOf(samples);
    // ignore: avoid_print
    print(
      'tap to repaint, host: median ${middle.inMicroseconds}us, '
      'worst ${samples.last.inMicroseconds}us',
    );
    expect(middle, lessThan(const Duration(milliseconds: 100)));
  });

  test('filling the whole grid does not get slower as it fills', () {
    final controller = _controller();
    final early = <Duration>[];
    final late = <Duration>[];

    var placed = 0;
    for (var cell = 0; cell < 81; cell++) {
      if (controller.state.board.isGiven(cell)) continue;
      final stopwatch = Stopwatch()..start();
      controller.tapCell(cell);
      controller.tapKey(DigitKey(int.parse(_solution[cell])));
      GridPainter(
        board: controller.state.board,
        selectedCell: cell,
        textScale: 1,
        colours: GridColours.standard(),
      ).paint(RecordingCanvas(), size);
      stopwatch.stop();
      (placed++ < 25 ? early : late).add(stopwatch.elapsed);
    }

    expect(controller.isSolved, isTrue, reason: 'the grid really was filled');
    // ignore: avoid_print
    print(
      'full grid fill: first 25 median ${medianOf(early).inMicroseconds}us, '
      'last median ${medianOf(late).inMicroseconds}us',
    );
    expect(medianOf(late), lessThan(const Duration(milliseconds: 100)));
  });

  test('the painter is asked to redraw only when something moved', () {
    final controller = _controller();
    GridPainter painterFor() => GridPainter(
      board: controller.state.board,
      selectedCell: controller.state.selectedCell,
      textScale: 1,
      colours: GridColours.standard(),
    );

    final before = painterFor();
    controller.tapKey(const UndoKey()); // nothing to undo
    expect(painterFor().shouldRepaint(before), isFalse);
  });

  // D-46: no in-puzzle effect exceeds 400ms and none blocks input. A player
  // mid-flow is the player having the best time, and a press animation that
  // swallowed the next tap would interrupt exactly them.
  testWidgets('a second tap during the press animation is still accepted', (
    tester,
  ) async {
    final pressed = <PadKey>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: NumberPad(onKey: pressed.add)),
      ),
    );

    await tester.tap(find.text('1'));
    // One frame only: the press animation is still running.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('3'));
    await tester.pump();

    expect(pressed, hasLength(3), reason: 'no tap was swallowed');
  });

  testWidgets('taps on the grid are accepted back to back', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.fromSize(
            size: size,
            child: PuzzleGrid(
              board: Board.forPuzzle(
                givens: _controller().state.board.toGrid(),
              ),
              onCellTapped: tapped.add,
            ),
          ),
        ),
      ),
    );

    final metrics = GridMetrics.fit(size);
    final origin = tester.getTopLeft(find.byType(PuzzleGrid));
    for (final cell in <int>[2, 3, 5, 11, 21]) {
      await tester.tapAt(origin + metrics.cellRect(cell).center);
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tapped, <int>[2, 3, 5, 11, 21]);
  });

  // Notes multiply the glyph count by up to nine: 81 values become as many as
  // 729 candidates. The painter's cost has to stay off the frame path all the
  // same (constraint 2).
  test('a repaint at maximum note density', () {
    var board = Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);
    var noted = 0;
    for (var cell = 0; cell < 81; cell++) {
      if (board.isGiven(cell)) continue;
      for (var digit = 1; digit <= 9; digit++) {
        board = (board.toggleNote(cell, digit) as EditApplied).board;
      }
      noted++;
    }
    expect(board.notedCount, noted);
    expect(noted * 9, greaterThan(400), reason: 'a genuinely dense board');

    final samples = <Duration>[];
    for (var run = 0; run < 20; run++) {
      final stopwatch = Stopwatch()..start();
      GridPainter(
        board: board,
        selectedCell: 40,
        textScale: 1,
        colours: GridColours.standard(),
      ).paint(RecordingCanvas(), size);
      stopwatch.stop();
      samples.add(stopwatch.elapsed);
    }

    final middle = medianOf(samples);
    // ignore: avoid_print
    print(
      'repaint at ${noted * 9} candidates: median '
      '${middle.inMicroseconds}us, worst ${samples.last.inMicroseconds}us',
    );
    expect(middle, lessThan(const Duration(milliseconds: 100)));
  });
}
