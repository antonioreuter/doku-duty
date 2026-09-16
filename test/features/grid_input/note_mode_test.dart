import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

PuzzleSession _session({
  InputMode mode = InputMode.cellFirst,
  EntryKind kind = EntryKind.value,
}) => PuzzleSession.start(
  solution: (Grid.parse(_solution) as ValidGrid).grid,

  board: Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid),
  mode: mode,
  entryKind: kind,
);

void main() {
  group('a puzzle opens in value mode', () {
    test('whatever the last puzzle ended in', () {
      expect(_session().entryKind, EntryKind.value);

      // A session that ended in notes mode does not colour the next one:
      // the mode belongs to the session, and each puzzle starts a new one.
      final ended = _session().withEntryKind(EntryKind.note);
      expect(ended.entryKind, EntryKind.note);
      expect(_session().entryKind, EntryKind.value);
    });

    test('a digit entered before the toggle is touched is a value', () {
      final after = _session().tapCell(2).tapDigit(4);
      expect(after.board.digitAt(2), 4);
      expect(after.board.notesAt(2), NoteSet.none);
    });
  });

  // A mode, not a modifier held per entry: players work in note-heavy bursts
  // (`docs/SPEC.md` §3.4).
  group('the mode stays in force', () {
    test('several digits in a row are all notes', () {
      var session = _session().withEntryKind(EntryKind.note).tapCell(2);
      for (final digit in const <int>[1, 4, 7]) {
        session = session.tapDigit(digit);
      }

      expect(session.board.notesAt(2), NoteSet.of(const <int>[1, 4, 7]));
      expect(session.board.isEmptyAt(2), isTrue);
      expect(session.entryKind, EntryKind.note);
    });

    test('turning it off returns to values', () {
      var session = _session().withEntryKind(EntryKind.note).tapCell(2);
      session = session.tapDigit(1);
      session = session.withEntryKind(EntryKind.value).tapDigit(4);

      expect(session.board.digitAt(2), 4);
      expect(
        session.board.notesAt(2),
        NoteSet.none,
        reason: 'cleared by the value',
      );
    });

    test('moving between cells does not reset it', () {
      var session = _session().withEntryKind(EntryKind.note);
      session = session.tapCell(2).tapDigit(3);
      session = session.tapCell(5).tapDigit(3);

      expect(session.board.notesAt(2), NoteSet.of(const <int>[3]));
      expect(session.board.notesAt(5), NoteSet.of(const <int>[3]));
      expect(session.entryKind, EntryKind.note);
    });
  });

  // Long-press a pad digit for the opposite mode, so a single note during a run
  // of values costs no trip to the toggle.
  group('one entry in the other mode', () {
    test('a long-press in value mode makes a note', () {
      final session = _session().tapCell(2).tapDigitLongPress(4);

      expect(session.board.notesAt(2), NoteSet.of(const <int>[4]));
      expect(session.board.isEmptyAt(2), isTrue);
      expect(
        session.entryKind,
        EntryKind.value,
        reason: 'the mode is unchanged',
      );
    });

    test('a long-press in notes mode places a value', () {
      final session = _session()
          .withEntryKind(EntryKind.note)
          .tapCell(2)
          .tapDigitLongPress(4);

      expect(session.board.digitAt(2), 4);
      expect(
        session.entryKind,
        EntryKind.note,
        reason: 'the mode is unchanged',
      );
    });

    test('the next ordinary entry is back in the mode in force', () {
      var session = _session().tapCell(2).tapDigitLongPress(4);
      session = session.tapCell(3).tapDigit(6);

      expect(session.board.notesAt(2), NoteSet.of(const <int>[4]));
      expect(session.board.digitAt(3), 6, reason: 'a value, as the mode says');
    });

    test('a long-press with nothing selected does nothing', () {
      final session = _session().tapDigitLongPress(4);
      expect(session.board.notedCount, 0);
      expect(session.lastEdit, isNull);
    });
  });

  group('erase and undo ignore the mode', () {
    test('erase clears a cell whichever mode is in force', () {
      var session = _session().withEntryKind(EntryKind.note).tapCell(2);
      session = session.tapDigit(1).tapDigit(4);
      expect(session.board.notesAt(2).length, 2);

      session = session.tapErase();
      expect(session.board.notesAt(2), NoteSet.none);
    });

    test('undo reverses the last entry whichever kind it was', () {
      final session = _session()
          .withEntryKind(EntryKind.note)
          .tapCell(2)
          .tapDigit(4)
          .tapUndo();
      expect(session.board.notesAt(2), NoteSet.none);
    });
  });
}
