import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/board_history.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

BoardHistory _history() => BoardHistory.start(
  Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid),
);

void main() {
  group('undoing a note', () {
    test('a marked candidate goes away, the rest of the cell stays', () {
      var history = _history().toggleNote(2, 1).history;
      history = history.toggleNote(2, 4).history;
      history = history.toggleNote(2, 7).history;

      final undone = history.undo();
      expect(undone.board.notesAt(2), NoteSet.of(const <int>[1, 4]));
    });

    test('a removed candidate comes back in its own slot', () {
      var history = _history().toggleNote(2, 4).history;
      history = history.toggleNote(2, 4).history; // removes it
      expect(history.board.notesAt(2), NoteSet.none);

      expect(history.undo().board.notesAt(2), NoteSet.of(const <int>[4]));
    });

    test('undo runs back through many notes to an empty cell', () {
      var history = _history();
      for (var digit = 1; digit <= 9; digit++) {
        history = history.toggleNote(2, digit).history;
      }
      expect(history.board.notesAt(2).length, 9);
      expect(history.depth, 9);

      while (history.canUndo) {
        history = history.undo();
      }
      expect(history.board.notesAt(2), NoteSet.none);
    });
  });

  // The one that loses a player's working out if it is wrong, and is silent
  // when it is. `docs/SPEC.md` §3.2 clears the cell; D-16 depends on that; and
  // constraint 1 says the player is never punished for changing their mind.
  group('undoing a value restores the candidates it cleared', () {
    test('every candidate comes back, in its own slot', () {
      var history = _history();
      for (final digit in const <int>[1, 3, 5, 8]) {
        history = history.toggleNote(2, digit).history;
      }

      history = history.place(2, 4).history;
      expect(history.board.digitAt(2), 4);
      expect(history.board.notesAt(2), NoteSet.none);

      final undone = history.undo();
      expect(undone.board.isEmptyAt(2), isTrue);
      expect(undone.board.notesAt(2), NoteSet.of(const <int>[1, 3, 5, 8]));
    });

    test('a cell that had none gets none back', () {
      final history = _history().place(2, 4).history;
      final undone = history.undo();

      expect(undone.board.isEmptyAt(2), isTrue);
      expect(undone.board.notesAt(2), NoteSet.none);
    });

    test('undoing a value that replaced another leaves notes alone', () {
      var history = _history().place(2, 4).history;
      history = history.place(2, 1).history;

      final undone = history.undo();
      expect(undone.board.digitAt(2), 4);
      expect(undone.board.notesAt(2), NoteSet.none);
    });

    test('it is one step, not two', () {
      var history = _history();
      for (final digit in const <int>[1, 3]) {
        history = history.toggleNote(2, digit).history;
      }
      final depthBefore = history.depth;

      history = history.place(2, 4).history;
      expect(history.depth, depthBefore + 1, reason: 'placing is one step');

      final undone = history.undo();
      expect(undone.board.notesAt(2), NoteSet.of(const <int>[1, 3]));
      expect(undone.depth, depthBefore);
    });

    test('erasing the value afterwards does not resurrect them', () {
      var history = _history().toggleNote(2, 1).history;
      history = history.place(2, 4).history;
      final erased = history.erase(2).history;

      expect(erased.board.notesAt(2), NoteSet.none);
      // Undoing the erase puts the value back, not the notes.
      expect(erased.undo().board.digitAt(2), 4);
    });
  });

  group('one history for both', () {
    test('undo reverses notes and values in the order they were made', () {
      var history = _history();
      history = history.toggleNote(2, 1).history; // 1
      history = history.place(3, 6).history; //      2
      history = history.toggleNote(5, 9).history; // 3
      history = history.place(2, 4).history; //      4 (clears the note in 2)

      expect(history.depth, 4);

      history = history.undo(); // undoes 4
      expect(history.board.isEmptyAt(2), isTrue);
      expect(history.board.notesAt(2), NoteSet.of(const <int>[1]));

      history = history.undo(); // undoes 3
      expect(history.board.notesAt(5), NoteSet.none);

      history = history.undo(); // undoes 2
      expect(history.board.isEmptyAt(3), isTrue);

      history = history.undo(); // undoes 1
      expect(history.board.notesAt(2), NoteSet.none);
      expect(history.canUndo, isFalse);
    });

    test('the whole session unwinds to the board it opened with', () {
      final start = _history();
      var history = start;
      for (var cell = 2; cell < 8; cell++) {
        if (history.board.isGiven(cell)) continue;
        history = history.toggleNote(cell, 3).history;
        history = history.toggleNote(cell, 7).history;
        history = history.place(cell, 1).history;
      }

      while (history.canUndo) {
        history = history.undo();
      }
      expect(history.board, start.board);
      expect(history.board.notedCount, 0);
    });
  });

  // Erase empties a cell whichever of the two it holds, so undoing one has to
  // put back whichever it took.
  group('undoing an erase of candidates', () {
    test('every candidate comes back', () {
      var history = _history();
      for (final digit in const <int>[2, 5, 9]) {
        history = history.toggleNote(2, digit).history;
      }

      history = history.erase(2).history;
      expect(history.board.notesAt(2), NoteSet.none);

      expect(history.undo().board.notesAt(2), NoteSet.of(const <int>[2, 5, 9]));
    });

    test('erasing an empty cell is refused and pushes nothing', () {
      final step = _history().erase(2);
      expect(step.edit, isA<EditRefused>());
      expect(step.history.canUndo, isFalse);
    });

    test('erasing a given is still refused', () {
      final step = _history().erase(0);
      expect(step.edit, isA<EditRefused>());
      expect((step.edit as EditRefused).reason, EditRefusal.cellIsGiven);
    });
  });

  group('a refused note pushes nothing', () {
    test('a note on a given', () {
      final step = _history().toggleNote(0, 7);
      expect(step.edit, isA<EditRefused>());
      expect(step.history.canUndo, isFalse);
    });

    test('a note on a cell holding a value', () {
      final history = _history().place(2, 4).history;
      final step = history.toggleNote(2, 7);

      expect(step.edit, isA<EditRefused>());
      expect((step.edit as EditRefused).reason, EditRefusal.cellHasValue);
      expect(step.history.depth, 1, reason: 'still just the placement');
    });
  });
}
