import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_controller.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/board_history.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/grid_input/presentation/number_pad.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/domain/note_enums.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

Board _applied(BoardEdit edit) => (edit as EditApplied).board;

/// A board carrying both inks across several cells.
Board _mixed() {
  var board = _board();
  for (final entry in const <int, List<int>>{
    2: <int>[1, 4],
    11: <int>[3],
    40: <int>[7, 9],
  }.entries) {
    for (final digit in entry.value) {
      board = _applied(board.toggleNote(entry.key, digit));
    }
  }
  for (final entry in const <int, List<int>>{
    2: <int>[7],
    21: <int>[2, 5],
    40: <int>[3],
  }.entries) {
    for (final digit in entry.value) {
      board = _applied(
        board.toggleNote(entry.key, digit, ink: NoteKind.provisional),
      );
    }
  }
  return board;
}

void main() {
  // D-11. A failed line of reasoning is abandoned in one tap without disturbing
  // settled work — which is the entire reason the second ink exists.
  group('clearing every provisional mark', () {
    test('every one of them goes', () {
      final cleared = _applied(_mixed().clearProvisional());

      for (var cell = 0; cell < 81; cell++) {
        expect(
          cleared.notesAt(cell).provisional,
          isEmpty,
          reason: 'cell $cell still carries a hypothesis',
        );
      }
    });

    test('settled work is untouched', () {
      final before = _mixed();
      final cleared = _applied(before.clearProvisional());

      expect(cleared.notesAt(2).settled, <int>[1, 4]);
      expect(cleared.notesAt(11).settled, <int>[3]);
      expect(cleared.notesAt(40).settled, <int>[7, 9]);
    });

    test('a cell holding only hypotheses is emptied', () {
      final cleared = _applied(_mixed().clearProvisional());
      expect(cleared.notesAt(21), NoteSet.none);
    });

    test('settled candidates keep their slots', () {
      final cleared = _applied(_mixed().clearProvisional());
      // Cell 2 held 1 and 4 settled with 7 provisional; removing the 7 must
      // move neither of the others (constraint 3).
      expect(cleared.notesAt(2), NoteSet.of(const <int>[1, 4]));
    });

    test('values and givens are not touched', () {
      var board = _applied(_mixed().place(23, 2));
      final before = board.toPlacedValues();
      board = _applied(board.clearProvisional());

      expect(board.toPlacedValues(), before);
      expect(board.digitAt(0), 5, reason: 'a given');
    });

    test('the edit records every cell it emptied', () {
      final edit = _mixed().clearProvisional() as EditApplied;
      expect(edit.noteChanges.keys.toSet(), <int>{2, 21, 40});
    });

    test('a board with no hypotheses is refused, not pushed', () {
      var board = _board();
      board = _applied(board.toggleNote(2, 4));

      expect(board.clearProvisional(), isA<EditRefused>());
      expect(
        (board.clearProvisional() as EditRefused).reason,
        EditRefusal.noChange,
      );
    });

    test('an empty board is refused too', () {
      expect(_board().clearProvisional(), isA<EditRefused>());
    });
  });

  // D-91. A chain test ends one of two ways, and without this the half that
  // succeeds is the slower half.
  group('promoting every provisional mark', () {
    test('every one of them becomes settled', () {
      final promoted = _applied(_mixed().promoteProvisional());

      for (var cell = 0; cell < 81; cell++) {
        expect(
          promoted.notesAt(cell).provisional,
          isEmpty,
          reason: 'cell $cell is still a hypothesis',
        );
      }
      expect(promoted.notesAt(21).settled, <int>[2, 5]);
    });

    test('nothing is added and nothing is removed', () {
      final before = _mixed();
      final promoted = _applied(before.promoteProvisional());

      for (var cell = 0; cell < 81; cell++) {
        expect(
          promoted.notesAt(cell).digits,
          before.notesAt(cell).digits,
          reason: 'cell $cell gained or lost a candidate',
        );
      }
    });

    test('candidates already settled are untouched', () {
      final promoted = _applied(_mixed().promoteProvisional());
      expect(promoted.notesAt(11), NoteSet.of(const <int>[3]));
    });

    test('a cell holding both inks ends up all settled', () {
      final promoted = _applied(_mixed().promoteProvisional());
      expect(promoted.notesAt(2).settled, <int>[1, 4, 7]);
      expect(promoted.notesAt(2).provisional, isEmpty);
    });

    test('origins survive the promotion (D-15)', () {
      var board = _board();
      board = _applied(board.fillNotes());
      final digit = board.notesAt(2).digits.first;
      board = _applied(board.toggleNote(2, digit, ink: NoteKind.provisional));
      expect(board.notesAt(2).isGenerated(digit), isTrue);

      board = _applied(board.promoteProvisional());

      expect(board.notesAt(2).inkOf(digit), NoteKind.settled);
      expect(board.notesAt(2).isGenerated(digit), isTrue);
    });

    test('the edit records every cell it changed', () {
      final edit = _mixed().promoteProvisional() as EditApplied;
      expect(edit.noteChanges.keys.toSet(), <int>{2, 21, 40});
    });

    test('a board with no hypotheses is refused, not pushed', () {
      var board = _applied(_board().toggleNote(2, 4));
      expect(board.promoteProvisional(), isA<EditRefused>());
    });
  });

  group('each is one undo step', () {
    test('undoing a clearance puts every hypothesis back in its own ink', () {
      var history = BoardHistory.start(_mixed());
      final before = history.board;
      final depth = history.depth;

      history = history.clearProvisional().history;
      expect(history.depth, depth + 1, reason: 'one step, not one per cell');

      final undone = history.undo().board;
      for (var cell = 0; cell < 81; cell++) {
        expect(
          undone.notesAt(cell),
          before.notesAt(cell),
          reason: 'cell $cell',
        );
      }
    });

    test('undoing a promotion returns every candidate to its ink', () {
      var history = BoardHistory.start(_mixed());
      final before = history.board;

      history = history.promoteProvisional().history;
      final undone = history.undo().board;

      for (var cell = 0; cell < 81; cell++) {
        expect(
          undone.notesAt(cell),
          before.notesAt(cell),
          reason: 'cell $cell',
        );
      }
    });

    test('undoing past a clearance reaches the action before it', () {
      var history = BoardHistory.start(_board());
      history = history.toggleNote(2, 4).history;
      history = history.toggleNote(2, 7, ink: NoteKind.provisional).history;
      history = history.clearProvisional().history;

      expect(history.undo().board.notesAt(2).provisional, <int>[7]);
      expect(history.undo().undo().board.notesAt(2).provisional, isEmpty);
      expect(history.undo().undo().board.notesAt(2).settled, <int>[4]);
    });

    test('a refused clearance pushes nothing', () {
      var history = BoardHistory.start(_applied(_board().toggleNote(2, 4)));
      final depth = history.depth;

      history = history.clearProvisional().history;
      history = history.promoteProvisional().history;

      expect(history.depth, depth);
    });
  });

  // Both are aimed at the board, not at a cell, so neither needs a selection
  // nor a held digit to be usable.
  group('reaching them from the session', () {
    PuzzleSession session() => PuzzleSession.start(
      solution: (Grid.parse(_solution) as ValidGrid).grid,
      board: _mixed(),
    );

    test('clearing needs no selection', () {
      final after = session().clearProvisional();

      expect(after.selectedCell, isNull);
      expect(after.board.notesAt(21), NoteSet.none);
    });

    test('promoting needs no selection', () {
      final after = session().promoteProvisional();

      expect(after.selectedCell, isNull);
      expect(after.board.notesAt(21).settled, <int>[2, 5]);
    });

    test('neither disturbs the mode, the ink, or a held digit', () {
      final before = session()
          .withMode(InputMode.digitFirst)
          .withEntryKind(EntryKind.note)
          .withNoteInk(NoteKind.provisional)
          .tapDigit(4);
      expect(before.lockedDigit, 4);

      final after = before.clearProvisional();

      expect(after.mode, InputMode.digitFirst);
      expect(after.entryKind, EntryKind.note);
      expect(after.noteInk, NoteKind.provisional);
      expect(after.lockedDigit, 4, reason: 'the brush is still in hand');
    });

    test('each is one undo from the session', () {
      final after = session().promoteProvisional();
      expect(after.canUndo, isTrue);
      expect(after.tapUndo().board.notesAt(21).provisional, <int>[2, 5]);
    });
  });

  // The pad's three keys reach the session, and nothing else does the work
  // twice. The keys themselves are `notes_pad_test.dart`; this is the wiring.
  group('the pad keys reach the board', () {
    const puzzle = StoredPuzzle(
      id: 'q1',
      clues: _clues,
      solution:
          '534678912672195348198342567859761423426853791713924856961537284287419635345286179',
      rank: Rank.deputy,
      seed: 1,
    );

    ({PuzzleController controller, List<DokuHaptic> haptics}) controllerOn(
      Board board,
    ) {
      final haptics = <DokuHaptic>[];
      return (
        controller: PuzzleController(
          puzzle: puzzle,
          sink: _NullSink(),
          initial: PuzzleSession.start(
            solution: (Grid.parse(_solution) as ValidGrid).grid,
            board: board,
            mode: InputMode.cellFirst,
          ),
          fireHaptic: haptics.add,
        ),
        haptics: haptics,
      );
    }

    test('the ink toggle changes the ink and nothing else', () {
      final on = controllerOn(_board());
      final controller = on.controller;
      expect(controller.state.noteInk, NoteKind.settled);

      controller.tapKey(const InkToggleKey());
      expect(controller.state.noteInk, NoteKind.provisional);
      expect(controller.state.entryKind, EntryKind.value);
      expect(controller.state.canUndo, isFalse, reason: 'it touched no cell');

      controller.tapKey(const InkToggleKey());
      expect(controller.state.noteInk, NoteKind.settled);
    });

    test('the clear key clears, and the promote key promotes', () {
      final clearing = controllerOn(_mixed()).controller;
      clearing.tapKey(const ClearProvisionalKey());
      expect(clearing.state.board.notesAt(21).digits, isEmpty);
      expect(clearing.state.board.notesAt(2).settled, <int>[1, 4]);

      final promoting = controllerOn(_mixed()).controller;
      promoting.tapKey(const PromoteProvisionalKey());
      expect(promoting.state.board.notesAt(21).settled, <int>[2, 5]);
      expect(promoting.state.board.notesAt(21).provisional, isEmpty);
    });

    test('each fires the haptic the other board-level actions fire', () {
      for (final key in const <PadKey>[
        ClearProvisionalKey(),
        PromoteProvisionalKey(),
      ]) {
        final on = controllerOn(_mixed());
        on.controller.tapKey(key);
        expect(on.haptics, <DokuHaptic>[DokuHaptic.selectionTick]);
      }

      // The ink toggle changes no cell, so it is silent — exactly as the notes
      // toggle is.
      final toggling = controllerOn(_board());
      toggling.controller.tapKey(const InkToggleKey());
      toggling.controller.tapKey(const NotesToggleKey());
      expect(toggling.haptics, isEmpty);
    });

    test('neither needs a selection nor a held digit', () {
      final on = controllerOn(_mixed());
      expect(on.controller.state.selectedCell, isNull);

      on.controller.tapKey(const ClearProvisionalKey());

      expect(on.controller.state.board.notesAt(21).digits, isEmpty);
    });
  });
}

/// The board sink is not what these tests are about — storage is
/// `note_storage_test.dart`.
final class _NullSink implements BoardSink {
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
