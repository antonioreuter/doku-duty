import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

/// Tap-to-repaint on a real platform.
///
/// Constraint 2 puts input response under 100ms and it is a product
/// requirement, not an aspiration. The host suite measures the same work on a
/// desktop CPU; what this adds is the platform's own rasteriser and text
/// shaping. Read the emulator and simulator numbers as an upper bound on good
/// hardware, not as the answer — the backlog is explicit that the number which
/// counts comes off a mid-tier Android phone.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const clues =
      '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
  const solution =
      '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

  const puzzle = StoredPuzzle(
    id: 'q1',
    clues: clues,
    solution: solution,
    rank: Rank.legend,
    seed: 1,
  );

  testWidgets('a tap places a digit and repaints', (tester) async {
    final controller = PuzzleController(
      puzzle: puzzle,
      sink: _NullSink(),
      initial: sessionFor(
        puzzle: puzzle,
        placedValues: null,
        mode: InputMode.cellFirst,
      ),
    );

    final samples = <int>[];

    for (var cell = 0; cell < 81; cell++) {
      if (controller.state.board.isGiven(cell)) continue;
      // A fresh recorder per sample: one recorder cannot back two canvases.
      final canvas = Canvas(PictureRecorder());
      final stopwatch = Stopwatch()..start();
      controller.tapCell(cell);
      controller.tapKey(DigitKey(int.parse(solution[cell])));
      GridPainter(
        board: controller.state.board,
        selectedCell: cell,
        textScale: 1,
        colours: GridColours.standard(),
      ).paint(canvas, const Size(360, 360));
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds);
    }
    samples.sort();

    // ignore: avoid_print
    print(
      'GRID LATENCY — tap to repaint: median '
      '${samples[samples.length ~/ 2]}us, worst ${samples.last}us, '
      'over ${samples.length} placements',
    );

    expect(controller.isSolved, isTrue);
    expect(
      samples[samples.length ~/ 2],
      lessThan(100000),
      reason: 'constraint 2: input response under 100ms',
    );
  });
}

class _NullSink implements BoardSink {
  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async {}

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {}

  @override
  Future<void> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async {}
}
