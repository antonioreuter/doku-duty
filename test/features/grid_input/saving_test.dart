import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

const _puzzle = StoredPuzzle(
  id: 'q1',
  clues: _clues,
  solution: _solution,
  rank: Rank.deputy,
  seed: 1,
);

/// Records every write, in order, so "on every change" can be counted.
class _RecordingSink implements BoardSink {
  final List<String> writes = <String>[];
  final List<(int, NoteSet)> noteWrites = <(int, NoteSet)>[];
  final List<String> completed = <String>[];

  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async {
    writes.add(board.toPlacedValues());
  }

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {
    for (final entry in byCell.entries) {
      noteWrites.add((entry.key, entry.value));
    }
  }

  @override
  Future<void> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async => completed.add(puzzleId);
}

/// Records the order of publish and write, so one can be shown to precede the
/// other.
class _OrderedSink implements BoardSink {
  _OrderedSink(this.order);

  final List<String> order;

  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async => order.add('write');

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async =>
      order.add('writeNotes');

  @override
  Future<void> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async {}
}

class _FailingSink implements BoardSink {
  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async => throw StateError('disk full');

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async =>
      throw StateError('disk full');

  @override
  Future<void> complete(
    String puzzleId, {
    Set<Technique> techniquesRequired = const <Technique>{},
    Attempt attempt = Attempt.fresh,
  }) async {}
}

PuzzleController _controller(
  BoardSink sink, {
  String? placedValues,
  List<DokuHaptic>? haptics,
  List<Object>? errors,
}) => PuzzleController(
  puzzle: _puzzle,
  sink: sink,
  initial: sessionFor(
    puzzle: _puzzle,
    placedValues: placedValues,
    mode: InputMode.cellFirst,
  ),
  fireHaptic: haptics?.add,
  onError: errors == null ? null : (error, stack) => errors.add(error),
);

void main() {
  group('written on every change', () {
    test('placing a digit writes the board', () async {
      final sink = _RecordingSink();
      final controller = _controller(sink);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      await pumpEventQueue();

      expect(sink.writes, hasLength(1));
      expect(sink.writes.single[2], '4');
    });

    test('erase and undo are written the same way', () async {
      final sink = _RecordingSink();
      final controller = _controller(sink);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      controller.tapKey(const EraseKey());
      controller.tapKey(const UndoKey());
      await pumpEventQueue();

      expect(sink.writes, hasLength(3));
      expect(sink.writes[0][2], '4');
      expect(sink.writes[1][2], '.', reason: 'erased');
      expect(sink.writes[2][2], '4', reason: 'undone back to the 4');
    });

    test('every change is a write — nothing is batched or timed', () async {
      final sink = _RecordingSink();
      final controller = _controller(sink);

      for (final cell in <int>[2, 3, 5, 11, 21]) {
        controller.tapCell(cell);
        controller.tapKey(const DigitKey(1));
      }
      await pumpEventQueue();

      expect(sink.writes, hasLength(5));
    });

    test('an action that changed nothing writes nothing', () async {
      final sink = _RecordingSink();
      final controller = _controller(sink);

      controller.tapCell(0); // a given
      controller.tapKey(const DigitKey(7));
      controller.tapKey(const UndoKey()); // nothing to undo
      controller.tapCell(4); // selection only
      await pumpEventQueue();

      expect(sink.writes, isEmpty);
    });
  });

  // The frame the player is waiting for is never waiting on the database: the
  // new board is published, and only then does the write start.
  test('the board is published before the write is started', () {
    final order = <String>[];
    final sink = _OrderedSink(order);
    final controller = _controller(sink);

    var boardWhenNotified = '';
    controller.addListener(() {
      order.add('published');
      boardWhenNotified = controller.state.board.toPlacedValues();
    });

    controller.tapCell(2);
    controller.tapKey(const DigitKey(4));

    expect(boardWhenNotified[2], '4', reason: 'the digit is already on screen');
    expect(order, <String>['published', 'published', 'write']);
  });

  group('resuming', () {
    test('a saved board comes back, with an empty history', () {
      final controller = _controller(
        _RecordingSink(),
        placedValues: '..4${'.' * 78}',
      );

      expect(controller.state.board.digitAt(2), 4);
      expect(controller.state.canUndo, isFalse);
    });

    test('no save means a fresh board', () {
      expect(_controller(_RecordingSink()).state.board.placedCount, 0);
    });
  });

  group('finishing', () {
    test('a solved puzzle is recorded solved', () async {
      final sink = _RecordingSink();
      final controller = _controller(sink);

      for (var cell = 0; cell < 81; cell++) {
        if (controller.state.board.isGiven(cell)) continue;
        controller.tapCell(cell);
        controller.tapKey(DigitKey(int.parse(_solution[cell])));
      }
      await pumpEventQueue();

      expect(controller.isSolved, isTrue);
      expect(sink.completed, <String>['q1']);
    });

    test(
      'a full board that disagrees with the solution is not solved',
      () async {
        final sink = _RecordingSink();
        final controller = _controller(sink);

        for (var cell = 0; cell < 81; cell++) {
          if (controller.state.board.isGiven(cell)) continue;
          controller.tapCell(cell);
          controller.tapKey(DigitKey(int.parse(_solution[cell])));
        }
        // Swap two cells so the board is full and wrong.
        controller.tapCell(2);
        controller.tapKey(const DigitKey(1));
        await pumpEventQueue();

        expect(controller.isSolved, isFalse);
        expect(sink.completed, <String>[
          'q1',
        ], reason: 'the earlier solve stands');
      },
    );
  });

  group('haptics and errors', () {
    test('a placement names a haptic from the vocabulary', () {
      final haptics = <DokuHaptic>[];
      final controller = _controller(_RecordingSink(), haptics: haptics);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));

      expect(haptics, <DokuHaptic>[DokuHaptic.selectionTick]);
    });

    test('a refused action is silent', () {
      final haptics = <DokuHaptic>[];
      final controller = _controller(_RecordingSink(), haptics: haptics);

      controller.tapCell(0);
      controller.tapKey(const DigitKey(7));

      expect(haptics, isEmpty);
    });

    test('a failed write is reported, never shown', () async {
      final errors = <Object>[];
      final controller = _controller(_FailingSink(), errors: errors);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      await pumpEventQueue();

      expect(errors, hasLength(1));
      expect(controller.state.board.digitAt(2), 4, reason: 'still playable');
    });
  });
}
