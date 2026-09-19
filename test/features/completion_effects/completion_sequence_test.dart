import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/application/completion_effects_controller.dart';
import 'package:doku_duty/features/completion_effects/domain/completion_sequence.dart';
import 'package:doku_duty/features/completion_effects/domain/effect_event.dart';
import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/design_system/domain/motion.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

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

final class _Harness {
  _Harness({bool reduceMotion = false})
    : board = Board.forPuzzle(givens: _grid(_solution)) {
    controller = CompletionEffectsController(
      vsync: const TestVSync(),
      cellIsFilled: (cell) => !board.isEmptyAt(cell),
      fireHaptic: haptics.add,
      reduceMotion: reduceMotion,
    );
  }

  final List<DokuHaptic> haptics = <DokuHaptic>[];
  final Board board;
  late final CompletionEffectsController controller;

  void dispose() => controller.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the sequence is four named beats', () {
    test('they run in order and cover the whole 1400ms', () {
      expect(CompletionSequence.beats, <CompletionBeat>[
        CompletionBeat.wave,
        CompletionBeat.hoof,
        CompletionBeat.scraps,
        CompletionBeat.bow,
      ]);

      expect(CompletionSequence.beats.first.starts, Duration.zero);
      expect(CompletionSequence.beats.last.ends, CompletionSequence.duration);
      expect(CompletionSequence.duration.inMilliseconds, 1400);
      expect(DokuMotion.puzzleComplete.isRecordedException, isTrue);
    });

    test('no beat leaves a gap or overlaps its neighbour', () {
      for (var i = 1; i < CompletionSequence.beats.length; i++) {
        expect(
          CompletionSequence.beats[i].starts,
          CompletionSequence.beats[i - 1].ends,
          reason:
              'beat ${CompletionSequence.beats[i].name} does not begin '
              'where the one before it ended',
        );
      }
    });

    test('the beats waiting for characters are named, not missing', () {
      expect(CompletionSequence.empty, <CompletionBeat>[
        CompletionBeat.hoof,
        CompletionBeat.bow,
      ]);
      expect(CompletionSequence.drawn, <CompletionBeat>[
        CompletionBeat.wave,
        CompletionBeat.scraps,
      ]);
    });

    test('an empty beat still holds its place on the timeline', () {
      // 300ms is inside the hoof beat. The sequence is running, it just draws
      // nothing — which is how `add-character-system` fills a slot without
      // moving a single timing.
      final running = CompletionSequence.runningAt(
        const Duration(milliseconds: 400),
      );

      expect(running, <CompletionBeat>[CompletionBeat.hoof]);
      expect(running.single.isDrawn, isFalse);
      expect(
        CompletionBeat.hoof.duration.inMilliseconds,
        400,
        reason: 'the slot has the length the finished beat will need',
      );
    });

    test('every moment of the sequence has exactly one beat', () {
      for (var ms = 0; ms < 1400; ms += 25) {
        expect(
          CompletionSequence.runningAt(Duration(milliseconds: ms)),
          hasLength(1),
          reason: 'nothing is running at ${ms}ms',
        );
      }
      expect(
        CompletionSequence.runningAt(const Duration(milliseconds: 1400)),
        isEmpty,
      );
    });
  });

  group('finishing the board', () {
    testWidgets('plays the sequence from the final cell', (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.controller.handle(const BoardCompleted(origin: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final sequence = harness.controller.frame.sequence;
      expect(sequence, isNotNull);
      expect(sequence!.origin, 40);
      expect(sequence.running, <CompletionBeat>[CompletionBeat.wave]);

      harness.controller.skip();
    });

    testWidgets('runs through the empty beats without stalling', (
      tester,
    ) async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.controller.handle(const BoardCompleted(origin: 40));
      await tester.pump();

      final seen = <CompletionBeat>{};
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        seen.addAll(harness.controller.frame.sequence?.running ?? const []);
      }

      expect(
        seen,
        containsAll(CompletionSequence.beats),
        reason:
            'all four beats were reached, including the two that draw '
            'nothing yet',
      );
    });

    testWidgets('ends, and does not leave the ticker running', (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.controller.handle(const BoardCompleted(origin: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(harness.controller.frame.sequence, isNull);
    });

    testWidgets('fires the success pattern once', (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.controller.handle(const BoardCompleted(origin: 40));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }

      expect(harness.haptics, <DokuHaptic>[DokuHaptic.success]);
    });

    testWidgets('tapping away ends it', (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.controller.handle(const BoardCompleted(origin: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(harness.controller.frame.sequence, isNotNull);

      harness.controller.skip();

      expect(
        harness.controller.frame.sequence,
        isNull,
        reason:
            'the celebration is something the player passes through, never '
            'something they wait out (D-46)',
      );
    });

    testWidgets('reduced motion plays no sequence at all', (tester) async {
      final harness = _Harness(reduceMotion: true);
      addTearDown(harness.dispose);

      harness.controller.handle(const BoardCompleted(origin: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(harness.controller.frame.sequence, isNull);
      expect(harness.haptics, isEmpty);
    });
  });

  group('a full board that repeats a digit is not finished', () {
    test('nothing is announced and nothing is flagged', () {
      // Row 0 is 534678912. Overwrite the 3 with a second 5: every cell holds
      // a value, and the board is not complete.
      final holed = Board.forPuzzle(givens: _grid(_withHoles(<int>[1])));
      final full = (holed.place(1, 5) as EditApplied).board;

      expect(full.filledCount, 81);
      expect(UnitCompletion.isBoardComplete(full), isFalse);
      expect(
        UnitCompletion.isComplete(
          full,
          GridGeometry.unitsOfKind(UnitKind.row)[0],
        ),
        isFalse,
        reason:
            'row 0 is full and repeats a digit, so it is not celebrated — '
            'and nothing says which of its cells is the wrong one',
      );
    });

    test('saying which cell is wrong is not this capability\'s job', () {
      final holed = Board.forPuzzle(givens: _grid(_withHoles(<int>[1])));
      final full = (holed.place(1, 5) as EditApplied).board;

      // The only thing reported is completeness. Nothing here knows the
      // solution, so nothing here can point at a cell (constraint 1).
      expect(UnitCompletion.isBoardComplete(full), isFalse);
      expect(
        UnitCompletion.forChange(before: holed, after: full, cell: 1).isEmpty,
        isTrue,
      );
    });
  });
}
