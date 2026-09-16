import 'package:flutter_test/flutter_test.dart';

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

class _Sink implements BoardSink {
  /// Each call to [writeNotes], in order. One entry is one commit.
  final List<Map<int, NoteSet>> commits = <Map<int, NoteSet>>[];
  final List<String> order = <String>[];

  /// Every cell written, flattened across commits.
  List<(int, NoteSet)> get noteWrites => <(int, NoteSet)>[
    for (final commit in commits)
      for (final entry in commit.entries) (entry.key, entry.value),
  ];

  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async => order.add('board');

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {
    commits.add(Map<int, NoteSet>.of(byCell));
    order.add('notes:${byCell.keys.join(',')}');
  }

  @override
  Future<void> complete(String puzzleId) async {}
}

PuzzleController _controller(
  _Sink sink, {
  Map<int, NoteSet> notes = const <int, NoteSet>{},
}) => PuzzleController(
  puzzle: _puzzle,
  sink: sink,
  initial: sessionFor(
    puzzle: _puzzle,
    placedValues: null,
    notes: notes,
    mode: InputMode.cellFirst,
  ).withEntryKind(EntryKind.note),
);

void main() {
  // Constraint 9 has no visible symptom when it breaks: a note write that stops
  // landing is invisible until a player loses an hour of work.
  group('written the moment it changes', () {
    test('marking a candidate writes that cell', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      await pumpEventQueue();

      expect(sink.noteWrites, hasLength(1));
      expect(sink.noteWrites.single.$1, 2);
      expect(sink.noteWrites.single.$2, NoteSet.of(const <int>[4]));
    });

    test('removing a candidate writes the cell as it now stands', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      controller.tapKey(const DigitKey(4));
      await pumpEventQueue();

      expect(sink.noteWrites, hasLength(2));
      expect(sink.noteWrites.last.$2, NoteSet.none);
    });

    test('a rapid sequence writes every one, none coalesced', () async {
      final sink = _Sink();
      final controller = _controller(sink);
      controller.tapCell(2);

      for (var digit = 1; digit <= 9; digit++) {
        controller.tapKey(DigitKey(digit));
      }
      await pumpEventQueue();

      expect(sink.noteWrites, hasLength(9));
      expect(sink.noteWrites.last.$2.length, 9);
    });

    test('the candidate is on screen before the write starts', () {
      final sink = _Sink();
      final controller = _controller(sink);
      controller.tapCell(2);

      var onScreen = NoteSet.none;
      controller.addListener(() {
        onScreen = controller.state.board.notesAt(2);
        sink.order.add('published');
      });

      controller.tapKey(const DigitKey(4));

      expect(onScreen, NoteSet.of(const <int>[4]));
      expect(sink.order.first, 'published');
    });

    test('an action that changed nothing writes nothing', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.tapCell(0); // a given
      controller.tapKey(const DigitKey(7));
      await pumpEventQueue();

      expect(sink.noteWrites, isEmpty);
    });
  });

  group('a value clearing candidates is written', () {
    test('the cleared cell is written empty', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      controller.tapKey(const DigitKey(7));
      sink.commits.clear();

      controller.setEntryKind(EntryKind.value);
      controller.tapKey(const DigitKey(1));
      await pumpEventQueue();

      expect(sink.noteWrites, hasLength(1));
      expect(sink.noteWrites.single.$2, NoteSet.none);
    });

    // Undo restores the candidates on screen; if it did not also write them,
    // the next launch would show the board without them. That is the silent
    // loss constraint 9 exists to prevent.
    test('undoing it writes them back', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.tapCell(2);
      controller.tapKey(const DigitKey(4));
      controller.tapKey(const DigitKey(7));
      controller.setEntryKind(EntryKind.value);
      controller.tapKey(const DigitKey(1));
      sink.commits.clear();

      controller.tapKey(const UndoKey());
      await pumpEventQueue();

      expect(sink.noteWrites, hasLength(1));
      expect(sink.noteWrites.single.$2, NoteSet.of(const <int>[4, 7]));
      expect(controller.state.board.notesAt(2), NoteSet.of(const <int>[4, 7]));
    });
  });

  test('a reopened puzzle carries its candidates', () {
    final controller = _controller(
      _Sink(),
      notes: <int, NoteSet>{
        2: NoteSet.of(const <int>[1, 5]),
        11: NoteSet.of(const <int>[9]),
      },
    );

    expect(controller.state.board.notesAt(2), NoteSet.of(const <int>[1, 5]));
    expect(controller.state.board.notesAt(11), NoteSet.of(const <int>[9]));
    expect(controller.state.canUndo, isFalse, reason: 'a fresh history');
  });

  // Constraint 9 at scale. **Auto-notes** is the first action that changes
  // hundreds of rows, and it is exactly where a well-meaning batch would be
  // added — one that looks identical to a correct write until a player loses a
  // filled board to an app kill.
  group('a fill is written with the action, as one commit', () {
    test('every cell it marked reaches the sink', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.fillNotes();
      await pumpEventQueue();

      final written = <int, NoteSet>{
        for (final commit in sink.commits) ...commit,
      };
      for (var cell = 0; cell < 81; cell++) {
        final notes = controller.state.board.notesAt(cell);
        if (notes.isEmpty) continue;
        expect(written[cell], notes, reason: 'cell \$cell');
      }
    });

    test('it is one commit, not one per cell', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.fillNotes();
      await pumpEventQueue();

      expect(sink.commits, hasLength(1));
      expect(sink.commits.single.length, greaterThan(1));
    });

    test('the board is published before the write starts', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      var notedWhenPublished = 0;
      var commitsWhenPublished = -1;
      controller.addListener(() {
        notedWhenPublished = controller.state.board.notedCount;
        commitsWhenPublished = sink.commits.length;
      });

      controller.fillNotes();

      // The candidates are on the board the listener was handed, and no write
      // had started when it was: the frame the player is waiting for never
      // waits on the database (constraint 2).
      expect(notedWhenPublished, greaterThan(0));
      expect(commitsWhenPublished, 0);

      await pumpEventQueue();
      expect(sink.commits, hasLength(1));
    });

    test('undoing a fill writes the cells back in one commit', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.fillNotes();
      await pumpEventQueue();
      sink.commits.clear();

      controller.tapKey(const UndoKey());
      await pumpEventQueue();

      expect(sink.commits, hasLength(1));
      for (final notes in sink.commits.single.values) {
        expect(notes, NoteSet.none);
      }
    });

    test('the pad key fills the board, and one undo takes it back', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.tapKey(const AutoNotesKey());
      await pumpEventQueue();
      final filled = controller.state.board.notedCount;
      expect(filled, greaterThan(0));

      controller.tapKey(const UndoKey());
      await pumpEventQueue();

      expect(controller.state.board.notedCount, 0);
    });

    test('the fill fires the same haptic a placement does', () async {
      final haptics = <DokuHaptic>[];
      final controller = PuzzleController(
        puzzle: _puzzle,
        sink: _Sink(),
        initial: sessionFor(
          puzzle: _puzzle,
          placedValues: null,
          mode: InputMode.cellFirst,
        ),
        fireHaptic: haptics.add,
      );

      controller.tapKey(const AutoNotesKey());
      await pumpEventQueue();

      expect(haptics, <DokuHaptic>[DokuHaptic.selectionTick]);
    });

    test('the generated origin reaches the sink', () async {
      final sink = _Sink();
      final controller = _controller(sink);

      controller.fillNotes();
      await pumpEventQueue();

      final written = sink.commits.single;
      expect(written.values.every((notes) => notes.manual.isEmpty), isTrue);
      expect(written.values.any((notes) => notes.generated.isNotEmpty), isTrue);
    });

    test('a failed write reaches onError, never the player', () async {
      final errors = <Object>[];
      final controller = PuzzleController(
        puzzle: _puzzle,
        sink: _FailingSink(),
        initial: sessionFor(
          puzzle: _puzzle,
          placedValues: null,
          mode: InputMode.cellFirst,
        ),
        onError: (error, stack) => errors.add(error),
      );

      controller.fillNotes();
      await pumpEventQueue();

      // D-03: losing a row is a developer's problem. The board on screen is
      // untouched by the failure.
      expect(errors, hasLength(1));
      expect(controller.state.board.notedCount, greaterThan(0));
    });
  });
}

/// A sink whose note write always fails.
class _FailingSink implements BoardSink {
  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) async {}

  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) async {
    throw StateError('the database is gone');
  }

  @override
  Future<void> complete(String puzzleId) async {}
}
