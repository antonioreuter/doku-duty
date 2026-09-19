import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/completion_effects/application/completion_effects_controller.dart';
import 'package:doku_duty/features/completion_effects/domain/completion_schedule.dart';
import 'package:doku_duty/features/completion_effects/domain/effect_frame.dart';
import 'package:doku_duty/features/completion_effects/domain/particle_pool.dart';
import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/grid_painter.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

import '../grid_input/support/recording_canvas.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

String _withHoles(Iterable<int> cells) {
  final digits = _solution.split('');
  for (final cell in cells) {
    digits[cell] = '.';
  }
  return digits.join();
}

class _NullSink implements BoardSink {
  @override
  Future<void> write(String id, Board board, {required int mistakes}) async {}

  @override
  Future<void> writeNotes(String id, Map<int, NoteSet> byCell) async {}

  @override
  Future<void> complete(
    String id, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async {}
}

/// A controller and an effect layer, wired the way the screen wires them.
final class _Harness {
  _Harness(Iterable<int> holes) {
    final clues = _withHoles(holes);
    final puzzle = StoredPuzzle(
      id: 'q1',
      clues: clues,
      solution: _solution,
      rank: Rank.legend,
      seed: 1,
    );
    controller = PuzzleController(
      puzzle: puzzle,
      sink: _NullSink(),
      initial: PuzzleSession.start(
        solution: _grid(_solution),
        attempt: const Attempt(mistakes: 0),
        board: Board.forPuzzle(givens: _grid(clues)),
        mode: InputMode.cellFirst,
      ),
    );
    effects = CompletionEffectsController(
      vsync: const TestVSync(),
      cellIsFilled: (cell) => !controller.state.board.isEmptyAt(cell),
      fireHaptic: haptics.add,
    );
    subscription = driveEffects(controller.effects, effects);
  }

  final List<DokuHaptic> haptics = <DokuHaptic>[];
  late final PuzzleController controller;
  late final CompletionEffectsController effects;
  late final Object subscription;

  /// What the screen does on a tap: skip whatever is celebrating, then handle
  /// the tap as the tap it was.
  void tapCell(int cell) {
    effects.skip();
    controller.tapCell(cell);
  }

  void tapKey(PadKey key) {
    effects.skip();
    controller.tapKey(key);
  }

  void dispose() {
    effects.dispose();
    controller.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a tap ends the effect and is still the tap it was', () {
    testWidgets('the cell is selected as well as the effect skipped', (
      tester,
    ) async {
      final harness = _Harness(<int>[4, 13]);
      addTearDown(harness.dispose);

      harness.tapCell(4);
      harness.tapKey(const DigitKey(7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(harness.effects.frame.isNotEmpty, isTrue);

      harness.tapCell(40);

      expect(harness.effects.frame.isEmpty, isTrue, reason: 'the effect ended');
      expect(
        harness.controller.state.selectedCell,
        40,
        reason:
            'and the tap was still a tap — a gesture that only dismissed a '
            'celebration would make the player tap twice',
      );
    });

    testWidgets('the record the effect was announcing survives the skip', (
      tester,
    ) async {
      final harness = _Harness(<int>[4, 13]);
      addTearDown(harness.dispose);

      harness.tapCell(4);
      harness.tapKey(const DigitKey(7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      harness.tapCell(40);

      expect(
        UnitCompletion.tintedCells(harness.controller.state.board),
        isNotEmpty,
        reason:
            'the tint is derived from the board, so skipping the '
            'celebration cannot skip the record',
      );
    });
  });

  group('placements outrun the effects without piling up', () {
    testWidgets('every placement lands, however fast they come', (
      tester,
    ) async {
      // Eight holes down column 0, each completing nothing until the last.
      final holes = <int>[0, 9, 18, 27, 36, 45, 54, 63, 72];
      final harness = _Harness(holes);
      addTearDown(harness.dispose);

      final solution = _grid(_solution);
      for (final cell in holes) {
        harness.tapCell(cell);
        harness.tapKey(DigitKey(solution.digitAt(cell)));
        // No pump between them: the placements arrive faster than any frame.
      }

      for (final cell in holes) {
        expect(
          harness.controller.state.board.digitAt(cell),
          solution.digitAt(cell),
          reason: 'cell $cell was placed while effects were in flight',
        );
      }
      expect(
        UnitCompletion.isBoardComplete(harness.controller.state.board),
        isTrue,
      );

      // The events reach the effect layer on a microtask, so the pump is what
      // lets them arrive before the effect is stopped for teardown.
      await tester.pump();
      harness.effects.skip();
    });

    testWidgets('effects do not accumulate as a backlog', (tester) async {
      final holes = <int>[0, 9, 18, 27, 36, 45, 54, 63, 72];
      final harness = _Harness(holes);
      addTearDown(harness.dispose);

      final solution = _grid(_solution);
      for (final cell in holes) {
        harness.tapCell(cell);
        harness.tapKey(DigitKey(solution.digitAt(cell)));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Whatever completed along the way, only the most recent placement is
      // celebrating. Nine queued cascades would take four and a half seconds
      // to drain, over a board the player has already finished.
      expect(
        harness.effects.frame.effects.length,
        lessThanOrEqualTo(3),
        reason: 'at most one placement\'s worth of steps is ever in flight',
      );

      await tester.pump();
      harness.effects.skip();
    });

    testWidgets('a placement mid-cascade is accepted on the same frame', (
      tester,
    ) async {
      final harness = _Harness(<int>[4, 40]);
      addTearDown(harness.dispose);

      harness.tapCell(4);
      harness.tapKey(const DigitKey(7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));

      final board = harness.controller.state.board;
      harness.tapCell(40);
      harness.tapKey(const DigitKey(3));

      expect(
        harness.controller.state.board,
        isNot(board),
        reason:
            'the board moved on the tap, not on the next frame — nothing '
            'waits on an effect (constraint 2)',
      );
      expect(harness.controller.state.board.digitAt(40), 3);

      await tester.pump();
      harness.effects.skip();
    });
  });

  _latencyUnderCascade();

  group('the schedule never exceeds what a step can carry', () {
    test('no single step runs past the 400ms ceiling', () {
      final before = Board.forPuzzle(givens: _grid(_withHoles(<int>[4])));
      final after = (before.place(4, 7) as EditApplied).board;
      final steps = CompletionSchedule.forChange(
        UnitCompletion.forChange(before: before, after: after, cell: 4),
        origin: 4,
      );

      for (final step in steps) {
        expect(
          step.duration.inMilliseconds,
          lessThanOrEqualTo(400),
          reason: 'the cascade is the exception, not any step within it',
        );
      }
    });
  });
}

/// The measurement task 7.3 records, taken on whatever host runs the suite.
///
/// **This is not the number the backlog is waiting for.** That one is a
/// physical mid-tier Android phone, and a host measurement cannot stand in for
/// it — a desktop CPU flatters the arithmetic and says nothing about the GPU.
/// What this catches is a regression of an order of magnitude, and it catches
/// it on every run rather than once on someone's desk.
void _latencyUnderCascade() {
  group('input latency with a cascade in flight', () {
    test('a tap still repaints inside the budget while three effects run', () {
      const size = Size(360, 360);
      final samples = <Duration>[];

      for (var run = 0; run < 40; run++) {
        // A board one cell from a three-unit cascade, rebuilt each run so the
        // measurement is of the same work every time.
        final before = Board.forPuzzle(givens: _grid(_withHoles(<int>[4, 40])));
        final steps = CompletionSchedule.forChange(
          UnitCompletion.forChange(
            before: before,
            after: (before.place(4, 7) as EditApplied).board,
            cell: 4,
          ),
          origin: 4,
        );
        final frame = EffectFrame(
          effects: <ActiveEffect>[
            for (final step in steps)
              ActiveEffect(unit: step.unit, origin: step.origin, progress: 0.5),
          ],
          particles: <Particle>[
            for (var i = 0; i < ParticleBudget.onScreen; i++)
              Particle(
                cell: i % 81,
                offset: (0.4, 0.6),
                age: const Duration(milliseconds: 80),
                lifetime: const Duration(milliseconds: 260),
              ),
          ],
        );

        final board = (before.place(4, 7) as EditApplied).board;
        final stopwatch = Stopwatch()..start();
        GridPainter(
          board: board,
          selectedCell: 40,
          completedCells: UnitCompletion.tintedCells(board),
          freshCells: frame.litCells,
          effects: frame,
          textScale: 1,
          colours: GridColours.standard(),
        ).paint(RecordingCanvas(), size);
        stopwatch.stop();
        samples.add(stopwatch.elapsed);
      }

      samples.sort();
      final median = samples[samples.length ~/ 2];
      // ignore: avoid_print
      print(
        'repaint under a full cascade, host: median '
        '${median.inMicroseconds}us, worst ${samples.last.inMicroseconds}us',
      );
      expect(median, lessThan(const Duration(milliseconds: 100)));
    });

    test('the particle count under a cascade stays within the budget', () {
      final frame = EffectFrame(
        effects: const <ActiveEffect>[],
        particles: <Particle>[
          for (var i = 0; i < ParticleBudget.onScreen; i++)
            Particle(
              cell: i % 81,
              offset: (0.5, 0.5),
              age: Duration.zero,
              lifetime: const Duration(milliseconds: 260),
            ),
        ],
      );

      expect(frame.particles.length, ParticleBudget.onScreen);
    });
  });
}
