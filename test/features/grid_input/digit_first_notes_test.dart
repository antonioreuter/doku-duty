import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

PuzzleSession _sweeping() => PuzzleSession.start(
  solution: (Grid.parse(_solution) as ValidGrid).grid,

  board: Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid),
  mode: InputMode.digitFirst,
  entryKind: EntryKind.note,
);

void main() {
  // Hold a digit, tap cells, and each one gains that candidate. The strongest
  // scanning tool in the product, and the combination the documents never
  // addressed.
  group('sweeping a candidate across cells', () {
    test('each cell tapped gains it, and the digit stays held', () {
      var session = _sweeping().tapDigit(3);
      expect(session.lockedDigit, 3);

      for (final cell in const <int>[2, 3, 5, 11]) {
        session = session.tapCell(cell);
      }

      for (final cell in const <int>[2, 3, 5, 11]) {
        expect(
          session.board.notesAt(cell),
          NoteSet.of(const <int>[3]),
          reason: 'cell $cell',
        );
      }
      expect(session.lockedDigit, 3, reason: 'still held for the next tap');
    });

    test('nothing is placed as a value', () {
      var session = _sweeping().tapDigit(3);
      session = session.tapCell(2);

      expect(session.board.isEmptyAt(2), isTrue);
      expect(session.board.placedCount, 0);
    });

    test('a cell already holding the candidate loses it', () {
      var session = _sweeping().tapDigit(3);
      session = session.tapCell(2);
      expect(session.board.notesAt(2), NoteSet.of(const <int>[3]));

      session = session.tapCell(2);
      expect(
        session.board.notesAt(2),
        NoteSet.none,
        reason: 'one sweep both marks and unmarks',
      );
    });

    test('sweeping leaves other candidates in the cell alone', () {
      var session = _sweeping().tapDigit(1);
      session = session.tapCell(2);
      session = session.tapDigit(7).tapCell(2);
      expect(session.board.notesAt(2), NoteSet.of(const <int>[1, 7]));

      session = session.tapDigit(1).tapCell(2);
      expect(session.board.notesAt(2), NoteSet.of(const <int>[7]));
    });

    test('a given refuses the candidate without putting the digit down', () {
      var session = _sweeping().tapDigit(3);
      session = session.tapCell(0);

      expect(session.board.notesAt(0), NoteSet.none);
      expect(session.lockedDigit, 3);
      expect(session.canUndo, isFalse);
    });

    test('a cell holding a value refuses the candidate', () {
      var session = PuzzleSession.start(
        solution: (Grid.parse(_solution) as ValidGrid).grid,

        board: Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid),
        mode: InputMode.digitFirst,
      ).tapDigit(4).tapCell(2);
      expect(session.board.digitAt(2), 4);

      session = session.withEntryKind(EntryKind.note).tapDigit(7);
      session = session.tapCell(2);

      expect(session.board.notesAt(2), NoteSet.none);
      expect(session.board.digitAt(2), 4);
    });
  });

  group('the eraser sweeps too', () {
    test('holding erase clears whichever cells are tapped', () {
      var session = _sweeping().tapDigit(3);
      session = session.tapCell(2).tapCell(5);

      session = session.tapErase();
      expect(session.lockedDigit, Board.empty);

      session = session.tapCell(2);
      expect(session.board.notesAt(2), NoteSet.none);
      expect(session.board.notesAt(5), NoteSet.of(const <int>[3]));
    });
  });

  // The rule `add-grid-and-input` set: a held digit means nothing in a mode
  // that has no idea what it is.
  group('switching modes drops the held digit', () {
    test('switching the input mode', () {
      final switched = _sweeping().tapDigit(3).withMode(InputMode.cellFirst);
      expect(switched.lockedDigit, isNull);
    });

    test('switching the entry kind', () {
      final switched = _sweeping().tapDigit(3).withEntryKind(EntryKind.value);
      expect(switched.lockedDigit, isNull);
      expect(switched.entryKind, EntryKind.value);
    });

    test('a long-press holds the digit like any press', () {
      // A held digit is a brush, swept many times, so there is no single entry
      // for the other mode to apply to. The toggle is one tap away.
      final held = _sweeping().tapDigitLongPress(3);
      expect(held.lockedDigit, 3);
      expect(held.entryKind, EntryKind.note, reason: 'the mode is unchanged');
    });

    test('switching to the kind already in force keeps it held', () {
      final same = _sweeping().tapDigit(3).withEntryKind(EntryKind.note);
      expect(same.lockedDigit, 3);
    });
  });
}
