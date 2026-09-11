import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

Board _applied(BoardEdit edit) => (edit as EditApplied).board;

void main() {
  group('a cell carries its candidates', () {
    test('a fresh board has none anywhere', () {
      final board = _board();
      for (var cell = 0; cell < 81; cell++) {
        expect(board.notesAt(cell), NoteSet.none, reason: 'cell $cell');
      }
      expect(board.notedCount, 0);
    });

    test('marking changes that cell and nothing else', () {
      final before = _board();
      final after = _applied(before.toggleNote(2, 4));

      expect(after.notesAt(2), NoteSet.of(const <int>[4]));
      for (var cell = 0; cell < 81; cell++) {
        if (cell == 2) continue;
        expect(after.notesAt(cell), NoteSet.none, reason: 'cell $cell');
      }
      expect(before.notesAt(2), NoteSet.none, reason: 'a board is a value');
    });

    test('the edit says what the cell held before and holds now', () {
      final first = _board().toggleNote(2, 4) as EditApplied;
      expect(first.cell, 2);
      expect(first.notesBefore, NoteSet.none);
      expect(first.notesAfter, NoteSet.of(const <int>[4]));
    });

    test('marking the same digit again removes it', () {
      var board = _applied(_board().toggleNote(2, 4));
      board = _applied(board.toggleNote(2, 4));
      expect(board.notesAt(2), NoteSet.none);
    });

    test('nine candidates fit in one cell', () {
      var board = _board();
      for (var digit = 1; digit <= 9; digit++) {
        board = _applied(board.toggleNote(2, digit));
      }
      expect(board.notesAt(2).length, 9);
    });
  });

  // D-16 rests on this: a completed grid has no notes by construction, so there
  // is no "you still have notes" check to strand a player on a solved puzzle.
  group('a cell holds either a value or notes, never both', () {
    test('a cell holding a value reports no candidates', () {
      final board = _applied(_board().place(2, 4));
      expect(board.notesAt(2), NoteSet.none);
    });

    test('placing a value clears that cell\'s candidates', () {
      var board = _board();
      for (final digit in const <int>[1, 4, 7]) {
        board = _applied(board.toggleNote(2, digit));
      }
      expect(board.notesAt(2).length, 3);

      final placed = board.place(2, 4) as EditApplied;
      expect(placed.board.notesAt(2), NoteSet.none);
      expect(placed.board.digitAt(2), 4);
    });

    test('the placement records exactly which candidates it cleared', () {
      var board = _board();
      for (final digit in const <int>[1, 4, 7]) {
        board = _applied(board.toggleNote(2, digit));
      }

      final placed = board.place(2, 4) as EditApplied;
      expect(placed.notesBefore, NoteSet.of(const <int>[1, 4, 7]));
      expect(placed.notesAfter, NoteSet.none);
    });

    test('a placement on a cell with no candidates records none', () {
      final placed = _board().place(2, 4) as EditApplied;
      expect(placed.notesBefore, NoteSet.none);
    });

    test('marking a candidate in a cell holding a value is refused', () {
      final board = _applied(_board().place(2, 4));
      final result = board.toggleNote(2, 7);

      expect(result, isA<EditRefused>());
      expect((result as EditRefused).reason, EditRefusal.cellHasValue);
      expect(result.board, board);
    });

    test('clearing the value does not bring the candidates back on its own', () {
      var board = _applied(_board().toggleNote(2, 1));
      board = _applied(board.place(2, 4));
      final erased = _applied(board.erase(2));

      // Undo restores them; erase is a different action and simply empties the
      // cell.
      expect(erased.notesAt(2), NoteSet.none);
      expect(erased.isEmptyAt(2), isTrue);
    });
  });

  group('givens take no candidates', () {
    test('marking one is refused as a value, not thrown', () {
      final board = _board();
      late final BoardEdit result;
      expect(() => result = board.toggleNote(0, 7), returnsNormally);

      expect(result, isA<EditRefused>());
      expect((result as EditRefused).reason, EditRefusal.cellIsGiven);
      expect(board.notesAt(0), NoteSet.none);
    });
  });

  group('the stored form', () {
    test('notes round-trip alongside placed values', () {
      var board = _board();
      board = _applied(board.place(3, 6));
      for (final (cell, digit) in const <(int, int)>[
        (2, 1),
        (2, 4),
        (5, 9),
        (11, 3),
      ]) {
        board = _applied(board.toggleNote(cell, digit));
      }

      final restored = Board.restore(
        givens: (Grid.parse(_clues) as ValidGrid).grid,
        placedValues: board.toPlacedValues(),
        notes: board.toNotes(),
      );

      expect(restored, board);
      expect(restored.notesAt(2), NoteSet.of(const <int>[1, 4]));
      expect(restored.notesAt(5), NoteSet.of(const <int>[9]));
      expect(restored.notesAt(11), NoteSet.of(const <int>[3]));
      expect(restored.digitAt(3), 6);
    });

    test('the stored form is per cell and per digit', () {
      final board = _applied(_board().toggleNote(2, 4));
      expect(board.toNotes(), <int, NoteSet>{
        2: NoteSet.of(const <int>[4]),
      });
    });

    test('a restore with no notes is a board with no notes', () {
      final restored = Board.restore(
        givens: (Grid.parse(_clues) as ValidGrid).grid,
        placedValues: '.' * 81,
        notes: const <int, NoteSet>{},
      );
      expect(restored.notedCount, 0);
    });

    test('a stored note on a given is dropped', () {
      final restored = Board.restore(
        givens: (Grid.parse(_clues) as ValidGrid).grid,
        placedValues: '.' * 81,
        notes: <int, NoteSet>{
          0: NoteSet.of(const <int>[7]),
        },
      );
      expect(restored.notesAt(0), NoteSet.none);
    });
  });

  test('boards with different notes are different values', () {
    final a = _applied(_board().toggleNote(2, 4));
    final b = _applied(_board().toggleNote(2, 5));
    expect(a, isNot(b));
    expect(a, _applied(_board().toggleNote(2, 4)));
  });
}
