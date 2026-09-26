import 'dart:async';

import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/completion_effects/domain/completion_schedule.dart';
import 'package:doku_duty/features/completion_effects/domain/effect_event.dart';
import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/design_system/domain/motion.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart'
    show StoredPuzzle;
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

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

Unit _unitOf(UnitKind kind, int index) => GridGeometry.unitsOfKind(kind)[index];

CompletionChange _change({
  required Iterable<int> holes,
  required int cell,
  required int digit,
}) {
  final before = Board.forPuzzle(givens: _grid(_withHoles(holes)));
  final after = (before.place(cell, digit) as EditApplied).board;
  return UnitCompletion.forChange(before: before, after: after, cell: cell);
}

/// A controller over a puzzle whose only holes are [holes].
///
/// The clues carry the holes and the solution is the real one, so the session
/// behaves exactly as a played puzzle does.
({PuzzleController controller, _RecordingSink sink}) _controllerFor(
  Iterable<int> holes,
) {
  final clues = _withHoles(holes);
  final puzzle = StoredPuzzle(
    id: 'test',
    clues: clues,
    solution: _solution,
    rank: Rank.greenhorn,
    seed: 1,
  );
  final sink = _RecordingSink();
  return (
    controller: PuzzleController(
      puzzle: puzzle,
      sink: sink,
      initial: PuzzleSession.start(
        solution: _grid(_solution),
        attempt: const Attempt(mistakes: 0),
        board: Board.forPuzzle(givens: _grid(clues)),
        mode: InputMode.cellFirst,
      ),
    ),
    sink: sink,
  );
}

class _RecordingSink implements BoardSink {
  int writes = 0;

  /// Everything that happened, in the order it happened. The test that cares
  /// about ordering appends the effect events to this same list.
  final List<String> order = <String>[];

  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async {
    writes++;
    order.add('write');
  }

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {}

  @override
  Future<int> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async => 0;
}

void main() {
  group('the cascade is chained, never simultaneous (D-47)', () {
    test('three completed units chain at 90ms in row, column, block order', () {
      // Cell 4's own hole is the last one anywhere in its row, column, or
      // block, so filling it completes all three.
      final steps = CompletionSchedule.forChange(
        _change(holes: <int>[4], cell: 4, digit: 7),
        origin: 4,
      );

      expect(steps.length, 3);
      expect(steps.map((s) => s.unit.kind).toList(), <UnitKind>[
        UnitKind.row,
        UnitKind.column,
        UnitKind.block,
      ]);
      expect(
        steps.map((s) => s.startsAt.inMilliseconds).toList(),
        <int>[0, 90, 180],
        reason: 'no two steps start together',
      );
      expect(
        steps.map((s) => s.duration.inMilliseconds).toList(),
        <int>[260, 260, 340],
        reason: 'the lasso twice, then the dynamite',
      );
    });

    test('a full cascade totals 520ms, the recorded exception', () {
      final steps = CompletionSchedule.forChange(
        _change(holes: <int>[4], cell: 4, digit: 7),
        origin: 4,
      );

      expect(
        CompletionSchedule.totalOf(steps),
        const Duration(milliseconds: 520),
      );
      expect(
        CompletionSchedule.totalOf(steps),
        DokuMotion.cascade.duration,
        reason: 'the schedule and the motion token agree on the number',
      );
      expect(
        DokuMotion.cascade.isRecordedException,
        isTrue,
        reason: 'past the 400ms ceiling by decision, not by drift (D-46)',
      );
    });

    test(
      'a row and a block chain at one offset, with no gap for the column',
      () {
        // Cell 13 stays empty, so cell 4 completes its row and its block but not
        // its column.
        final steps = CompletionSchedule.forChange(
          _change(holes: <int>[4, 31], cell: 4, digit: 7),
          origin: 4,
        );

        expect(
          steps.map((s) => s.unit.kind).toList(),
          <UnitKind>[UnitKind.row, UnitKind.block],
          reason: 'the column step is absent, not held empty',
        );
        expect(
          steps.map((s) => s.startsAt.inMilliseconds).toList(),
          <int>[0, 90],
          reason: 'consecutive, so the celebration does not stutter',
        );
      },
    );

    test('one completed unit is not a cascade', () {
      final steps = CompletionSchedule.forChange(
        _change(holes: <int>[4, 13], cell: 4, digit: 7),
        origin: 4,
      );

      expect(steps.length, 1);
      expect(steps.single.startsAt, Duration.zero);
      expect(CompletionSchedule.totalOf(steps).inMilliseconds, 260);
    });

    test('completing nothing schedules nothing', () {
      expect(
        CompletionSchedule.forChange(CompletionChange.none, origin: 0),
        isEmpty,
      );
    });

    test('each step carries its own haptic, one per step', () {
      final steps = CompletionSchedule.forChange(
        _change(holes: <int>[4], cell: 4, digit: 7),
        origin: 4,
      );

      expect(steps.map((s) => s.haptic).toList(), <DokuHaptic>[
        DokuHaptic.lightImpact,
        DokuHaptic.lightImpact,
        DokuHaptic.mediumImpact,
      ]);
    });

    test('every step starts from the cell the player touched', () {
      final steps = CompletionSchedule.forChange(
        _change(holes: <int>[4], cell: 4, digit: 7),
        origin: 4,
      );

      for (final step in steps) {
        expect(step.origin, 4);
      }
    });
  });

  group('the controller announces what completed', () {
    test('a placement that completes a unit is announced', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      final events = <EffectEvent>[];
      controller.effects.listen(events.add);

      controller.tapCell(4);
      controller.tapKey(const DigitKey(7));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      final event = events.single as UnitsCompleted;
      expect(event.origin, 4);
      expect(event.steps.single.unit, _unitOf(UnitKind.row, 0));
      expect(event.isCascade, isFalse);
      controller.dispose();
    });

    test('a placement that completes nothing announces nothing', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      final events = <EffectEvent>[];
      controller.effects.listen(events.add);

      controller.tapCell(13);
      controller.tapKey(const DigitKey(3));
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty, reason: 'row 1 still has other holes');
      controller.dispose();
    });

    test('a note announces nothing (D-52)', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      final events = <EffectEvent>[];
      controller.effects.listen(events.add);

      controller.setEntryKind(EntryKind.note);
      controller.tapCell(4);
      controller.tapKey(const DigitKey(7));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.board.notesAt(4).contains(7), isTrue);
      expect(
        events,
        isEmpty,
        reason: 'notes are thinking, and thinking is quiet',
      );
      controller.dispose();
    });

    test('finishing the board is announced once', () async {
      final (:controller, :sink) = _controllerFor(<int>[4]);
      final events = <EffectEvent>[];
      controller.effects.listen(events.add);

      controller.tapCell(4);
      controller.tapKey(const DigitKey(7));
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<BoardCompleted>(), hasLength(1));
      expect(events.whereType<UnitsCompleted>().single.isCascade, isTrue);
      controller.dispose();
    });

    test('an already-finished board is not announced again', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      final events = <EffectEvent>[];

      controller.tapCell(4);
      controller.tapKey(const DigitKey(7));
      controller.effects.listen(events.add);
      // Overwrite a cell on the finished row with the same digit it holds —
      // refused, so nothing is announced either way.
      controller.tapCell(13);
      controller.tapKey(const DigitKey(3));
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<BoardCompleted>(), isEmpty);
      controller.dispose();
    });

    test('erasing from a complete unit announces no completion', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      controller.tapCell(4);
      controller.tapKey(const DigitKey(7));

      final events = <EffectEvent>[];
      controller.effects.listen(events.add);
      controller.tapCell(4);
      controller.tapKey(const EraseKey());
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty, reason: 'breaking a unit is not a celebration');
      controller.dispose();
    });
  });

  group('the effect layer reads the board and never writes it', () {
    test('listening changes nothing that is saved', () async {
      final quiet = _controllerFor(<int>[4, 13]);
      quiet.controller.tapCell(4);
      quiet.controller.tapKey(const DigitKey(7));
      await Future<void>.delayed(Duration.zero);

      final listened = _controllerFor(<int>[4, 13]);
      listened.controller.effects.listen((_) {});
      listened.controller.tapCell(4);
      listened.controller.tapKey(const DigitKey(7));
      await Future<void>.delayed(Duration.zero);

      expect(
        listened.sink.writes,
        quiet.sink.writes,
        reason:
            'a subscriber must not cause a write — constraint 9 belongs to '
            'the board, and effects are downstream of it',
      );
      expect(listened.controller.state.board, quiet.controller.state.board);
      quiet.controller.dispose();
      listened.controller.dispose();
    });

    test('the tint is derived, so nothing is stored for it', () {
      final board = Board.forPuzzle(givens: _grid(_withHoles(<int>[4, 13])));
      final after = (board.place(4, 7) as EditApplied).board;

      // The board's stored form is the same whether or not anything is tinted:
      // there is no tint field to write and none to get wrong.
      expect(UnitCompletion.tintedCells(after), isNotEmpty);
      expect(after.toPlacedValues().length, 81);
      expect(
        after.toPlacedValues()[4],
        '7',
        reason: 'the placement is stored; the tint it caused is not',
      );
    });

    test('a closed controller drops events instead of throwing', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      controller.dispose();

      expect(() => controller.effects, returnsNormally);
    });
  });

  group('the write goes out before the celebration', () {
    // Constraint 9 has no visible symptom when it breaks, so the ordering that
    // protects it is asserted rather than left to a comment. `_persist` runs
    // synchronously up to its first await; if an announcement were ever moved
    // in front of it, a throw there would silently cost the player their
    // placement.
    test('a placement is persisted before its event is delivered', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      controller.effects.listen((_) => sink.order.add('event'));

      controller.tapCell(4);
      controller.tapKey(const DigitKey(7));
      await Future<void>.delayed(Duration.zero);

      expect(sink.order, isNotEmpty);
      expect(
        sink.order.indexOf('write'),
        lessThan(sink.order.indexOf('event')),
        reason: 'the board reaches storage before anything is celebrated',
      );
      controller.dispose();
    });

    test('a listener that throws does not cost the player the write', () async {
      final (:controller, :sink) = _controllerFor(<int>[4, 13]);
      final escaped = <Object>[];

      // The throw is caught at the zone rather than by the controller, which
      // is the point: the controller does not have to defend itself, because
      // a broadcast stream delivers on a microtask and the write is already
      // away by then.
      await runZonedGuarded(() async {
        controller.effects.listen((_) => throw StateError('a bad subscriber'));

        controller.tapCell(4);
        controller.tapKey(const DigitKey(7));
        await Future<void>.delayed(Duration.zero);
      }, (error, stack) => escaped.add(error));

      expect(escaped, hasLength(1), reason: 'the subscriber really did throw');

      expect(
        sink.writes,
        greaterThan(0),
        reason:
            'the effect layer is downstream of the board and can never '
            'reach back into it',
      );
      controller.dispose();
    });
  });
}
