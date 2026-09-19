import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/completion_effects/application/completion_effects_controller.dart';
import 'package:doku_duty/features/completion_effects/domain/completion_schedule.dart';
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

/// The controller, wired over a board with [holes] still empty.
///
/// Driven by `tester.pump(duration)`: a real ticker on the test binding's
/// clock, so timing is asserted in milliseconds rather than waited out.
final class _Harness {
  _Harness({bool reduceMotion = false, Iterable<int> holes = const <int>[]})
    : board = Board.forPuzzle(givens: _grid(_withHoles(holes))) {
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

CompletionChange _change({
  required Iterable<int> holes,
  required int cell,
  required int digit,
}) {
  final before = Board.forPuzzle(givens: _grid(_withHoles(holes)));
  final after = (before.place(cell, digit) as EditApplied).board;
  return UnitCompletion.forChange(before: before, after: after, cell: cell);
}

UnitsCompleted _event({
  required Iterable<int> holes,
  required int cell,
  required int digit,
}) {
  final change = _change(holes: holes, cell: cell, digit: digit);
  return UnitsCompleted(
    origin: cell,
    steps: CompletionSchedule.forChange(change, origin: cell),
  );
}

void main() {
  // The controller needs a binding for its ticker.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the durations are the documented ones', () {
    test('the lasso runs 260ms and the dynamite 340ms', () {
      final steps = _event(holes: <int>[4], cell: 4, digit: 7).steps;

      expect(
        steps.firstWhere((s) => s.unit.kind == UnitKind.row).motion,
        DokuMotion.unitComplete,
      );
      expect(
        steps.firstWhere((s) => s.unit.kind == UnitKind.column).motion,
        DokuMotion.unitComplete,
      );
      expect(
        steps.firstWhere((s) => s.unit.kind == UnitKind.block).motion,
        DokuMotion.blockComplete,
      );
      expect(DokuMotion.unitComplete.duration.inMilliseconds, 260);
      expect(DokuMotion.blockComplete.duration.inMilliseconds, 340);
    });

    test('the lasso is a light impact and the dynamite a medium one', () {
      expect(DokuMotion.unitComplete.haptic, DokuHaptic.lightImpact);
      expect(DokuMotion.blockComplete.haptic, DokuHaptic.mediumImpact);
    });

    test('neither exceeds the 400ms ceiling', () {
      for (final motion in <DokuMotion>[
        DokuMotion.unitComplete,
        DokuMotion.blockComplete,
      ]) {
        expect(motion.isRecordedException, isFalse);
        expect(motion.duration.inMilliseconds, lessThanOrEqualTo(400));
      }
    });

    test('the fresh hold is a state duration, not in-puzzle motion', () {
      expect(DokuMotion.completionTintHold.duration.inMilliseconds, 2000);
      expect(
        DokuMotion.completionTintHold.isInPuzzle,
        isFalse,
        reason:
            'a hold on a colour that is already correct blocks nothing, so '
            'it is not a third exception to the 400ms ceiling',
      );
      expect(
        DokuMotion.completionTintHold.isRecordedException,
        isFalse,
        reason: 'only the cascade and the completion sequence are exceptions',
      );
    });

    test('the two recorded exceptions are the only ones', () {
      final exceptions = DokuMotion.values
          .where((m) => m.isInPuzzle && m.duration.inMilliseconds > 400)
          .toList();

      expect(exceptions.toSet(), <DokuMotion>{
        DokuMotion.cascade,
        DokuMotion.puzzleComplete,
      });
      for (final motion in exceptions) {
        expect(motion.isRecordedException, isTrue);
      }
    });
  });

  group('completing nothing celebrates nothing', () {
    test('a placement into an already-complete unit schedules no step', () {
      final finished = Board.forPuzzle(givens: _grid(_solution));

      final change = UnitCompletion.forChange(
        before: finished,
        after: finished,
        cell: 4,
      );
      expect(CompletionSchedule.forChange(change, origin: 4), isEmpty);
    });

    test('an erase schedules no step', () {
      final filled = Board.forPuzzle(givens: _grid(_solution));
      final erased = Board.forPuzzle(givens: _grid(_withHoles(<int>[4])));

      final change = UnitCompletion.forChange(
        before: filled,
        after: erased,
        cell: 4,
      );
      expect(change.broken, isNotEmpty);
      expect(
        CompletionSchedule.forChange(change, origin: 4),
        isEmpty,
        reason: 'breaking a unit is not a celebration',
      );
    });
  });

  group('a cascade fires one haptic per step', () {
    testWidgets('three steps, three haptics, in their own order', (
      tester,
    ) async {
      final harness = _Harness(holes: <int>[4]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4], cell: 4, digit: 7));
      await tester.pump();

      // Step one only: the other two have not started yet.
      await tester.pump(const Duration(milliseconds: 10));
      expect(harness.haptics, <DokuHaptic>[DokuHaptic.lightImpact]);

      await tester.pump(const Duration(milliseconds: 90));
      expect(harness.haptics, <DokuHaptic>[
        DokuHaptic.lightImpact,
        DokuHaptic.lightImpact,
      ]);

      await tester.pump(const Duration(milliseconds: 90));
      expect(harness.haptics, <DokuHaptic>[
        DokuHaptic.lightImpact,
        DokuHaptic.lightImpact,
        DokuHaptic.mediumImpact,
      ], reason: 'the dynamite lands heavier than the two lassos');

      harness.controller.skip();
    });

    testWidgets('a haptic fires once per step, not once per frame', (
      tester,
    ) async {
      final harness = _Harness(holes: <int>[4, 13]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4, 13], cell: 4, digit: 7));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(harness.haptics, hasLength(1));

      harness.controller.skip();
    });

    testWidgets('the steps overlap on screen but never start together', (
      tester,
    ) async {
      final harness = _Harness(holes: <int>[4]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4], cell: 4, digit: 7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(harness.controller.frame.effects, hasLength(1));

      await tester.pump(const Duration(milliseconds: 90));
      expect(
        harness.controller.frame.effects,
        hasLength(2),
        reason:
            'the first is still running when the second starts — chained '
            'is not sequential, it is offset',
      );

      harness.controller.skip();
    });
  });

  group('the fresh hold', () {
    testWidgets('a completed unit holds the flash, then settles', (
      tester,
    ) async {
      final harness = _Harness(holes: <int>[4, 13]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4, 13], cell: 4, digit: 7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        harness.controller.freshCells,
        containsAll(GridGeometry.unitsOfKind(UnitKind.row)[0].cells),
      );

      await tester.pump(const Duration(milliseconds: 2100));
      expect(
        harness.controller.freshCells,
        isEmpty,
        reason: 'the celebration and the record are different states',
      );
    });

    testWidgets(
      'a second placement during the hold neither waits nor restarts it',
      (tester) async {
        final harness = _Harness(holes: <int>[4, 13]);
        addTearDown(harness.dispose);

        harness.controller.handle(
          _event(holes: <int>[4, 13], cell: 4, digit: 7),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        final row = GridGeometry.unitsOfKind(UnitKind.row)[0].cells.toSet();
        expect(harness.controller.freshCells, containsAll(row));

        // A second, unrelated completion arrives mid-hold — row 1, which shares
        // no cell with row 0. It is accepted immediately and the first unit's
        // hold keeps its own clock.
        harness.controller.handle(_event(holes: <int>[13], cell: 13, digit: 9));
        await tester.pump(const Duration(milliseconds: 16));

        await tester.pump(const Duration(milliseconds: 1100));
        expect(
          harness.controller.freshCells.containsAll(row),
          isFalse,
          reason:
              'the first hold ran out on its own schedule rather than being '
              'restarted by the second',
        );
        expect(
          harness.controller.freshCells,
          containsAll(GridGeometry.unitsOfKind(UnitKind.row)[1].cells),
          reason: 'the second unit is holding its own flash on its own clock',
        );

        harness.controller.skip();
      },
    );
  });

  group('every effect is skippable (D-46)', () {
    testWidgets('a tap ends the effect and leaves the record', (tester) async {
      final harness = _Harness(holes: <int>[4]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4], cell: 4, digit: 7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(harness.controller.frame.isNotEmpty, isTrue);

      harness.controller.skip();
      expect(harness.controller.frame.isEmpty, isTrue);
      expect(harness.controller.freshCells, isEmpty);

      // The tint survives, because it is derived from the board and was never
      // the effect's to give or take away.
      final finished = Board.forPuzzle(givens: _grid(_solution));
      expect(UnitCompletion.tintedCells(finished), isNotEmpty);
    });

    testWidgets('skipping with nothing running is harmless', (tester) async {
      final harness = _Harness();
      addTearDown(harness.dispose);

      expect(harness.controller.skip, returnsNormally);
    });
  });

  group('asking for less motion silences all of it', () {
    testWidgets('no motion, no particle, no haptic', (tester) async {
      final harness = _Harness(reduceMotion: true, holes: <int>[4]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4], cell: 4, digit: 7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(harness.controller.frame.isEmpty, isTrue);
      expect(harness.controller.frame.effects, isEmpty);
      expect(harness.controller.frame.particles, isEmpty);
      expect(harness.haptics, isEmpty);
    });

    testWidgets('the tint arrives directly in its settled state', (
      tester,
    ) async {
      final harness = _Harness(reduceMotion: true, holes: <int>[4]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4], cell: 4, digit: 7));
      await tester.pump();

      expect(
        harness.controller.freshCells,
        isEmpty,
        reason: 'a flash the player asked not to see is still a flash',
      );
      // Nothing is lost: which units are complete is still readable, because
      // the tint and the corner mark come from the board.
      expect(
        UnitCompletion.tintedCells(Board.forPuzzle(givens: _grid(_solution))),
        isNotEmpty,
      );
    });

    testWidgets('turning it on mid-effect ends what is running', (
      tester,
    ) async {
      final harness = _Harness(holes: <int>[4]);
      addTearDown(harness.dispose);

      harness.controller.handle(_event(holes: <int>[4], cell: 4, digit: 7));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(harness.controller.frame.isNotEmpty, isTrue);

      harness.controller.reduceMotion = true;
      expect(
        harness.controller.frame.isEmpty,
        isTrue,
        reason: 'a player who asked for less asked for less now',
      );
    });
  });

  group("Biscuit's slot on the third step", () {
    test('is empty, and does not change the timing', () {
      final steps = _event(holes: <int>[4], cell: 4, digit: 7).steps;

      // `add-character-system` hangs Biscuit's stamp off the third step. The
      // step exists and carries its own timing; nothing draws a character yet,
      // and filling that in later must not move the 520ms.
      expect(steps, hasLength(3));
      expect(steps.last.unit.kind, UnitKind.block);
      expect(
        CompletionSchedule.totalOf(steps),
        DokuMotion.cascade.duration,
        reason:
            'the slot is named by the step, not by a gap reserved in the '
            'timeline',
      );
    });
  });
}
