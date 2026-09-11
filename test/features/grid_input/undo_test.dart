import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/board_history.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

BoardHistory _history() =>
    BoardHistory.start(Board.forPuzzle(givens: _grid(_clues)));

void main() {
  group('undoing a placement', () {
    test('it restores the empty cell the digit went into', () {
      final placed = _history().place(2, 4);
      expect(placed.history.board.digitAt(2), 4);

      final undone = placed.history.undo();
      expect(undone.board.isEmptyAt(2), isTrue);
      expect(undone.board.placedCount, 0);
    });

    test('it restores the value that was overwritten, not emptiness', () {
      var history = _history().place(2, 4).history;
      history = history.place(2, 1).history;
      expect(history.board.digitAt(2), 1);

      final undone = history.undo();
      expect(
        undone.board.digitAt(2),
        4,
        reason: 'the 4 was there before the 1',
      );
    });

    test('it leaves every other cell alone', () {
      var history = _history().place(2, 4).history;
      history = history.place(3, 6).history;
      final undone = history.undo();

      expect(undone.board.digitAt(2), 4);
      expect(undone.board.isEmptyAt(3), isTrue);
    });
  });

  group('undoing an erase', () {
    test('the erased value comes back', () {
      var history = _history().place(2, 4).history;
      history = history.erase(2).history;
      expect(history.board.isEmptyAt(2), isTrue);

      expect(history.undo().board.digitAt(2), 4);
    });
  });

  group('full depth', () {
    test('undo runs back to the board the puzzle was opened with', () {
      final start = _history();
      var history = start;
      for (final (cell, digit) in const <(int, int)>[
        (2, 4),
        (3, 6),
        (5, 8),
        (2, 1),
        (3, 9),
      ]) {
        history = history.place(cell, digit).history;
      }
      history = history.erase(5).history;
      expect(history.depth, 6);

      while (history.canUndo) {
        history = history.undo();
      }
      expect(history.board, start.board);
      expect(history.depth, 0);
    });

    test('it is not capped', () {
      var history = _history();
      // Every empty cell filled, then every one changed again.
      for (var pass = 0; pass < 2; pass++) {
        for (var cell = 0; cell < 81; cell++) {
          if (history.board.isGiven(cell)) continue;
          history = history.place(cell, pass == 0 ? 1 : 2).history;
        }
      }
      expect(history.depth, 102, reason: '51 empty cells, twice');

      while (history.canUndo) {
        history = history.undo();
      }
      expect(history.board.placedCount, 0);
    });
  });

  // Constraint 1 applies to controls as well as to play: a control that refuses
  // is a small failure state, and this product does not have those.
  group('nothing to undo', () {
    test('undo on a fresh board is a no-op, not an error', () {
      final start = _history();
      expect(start.canUndo, isFalse);

      late final BoardHistory after;
      expect(() => after = start.undo(), returnsNormally);
      expect(after.board, start.board);
      expect(after.depth, 0);
    });

    test('undo past the start keeps doing nothing', () {
      var history = _history().place(2, 4).history;
      for (var i = 0; i < 5; i++) {
        history = history.undo();
      }
      expect(history.board.placedCount, 0);
      expect(history.canUndo, isFalse);
    });
  });

  // An action that never happened must not be undoable, or undo reverses a move
  // the player never made.
  group('a refused edit pushes nothing', () {
    test('a placement onto a given', () {
      final history = _history().place(0, 7);

      expect(history.edit, isA<EditRefused>());
      expect((history.edit as EditRefused).reason, EditRefusal.cellIsGiven);
      expect(history.history.canUndo, isFalse);
      expect(history.history.depth, 0);
    });

    test('an erase of an empty cell', () {
      final history = _history().erase(2);

      expect(history.edit, isA<EditRefused>());
      expect(history.history.depth, 0);
    });

    test('placing the digit that is already there', () {
      var history = _history().place(2, 4).history;
      final again = history.place(2, 4);

      expect(again.edit, isA<EditRefused>());
      expect(again.history.depth, 1, reason: 'still just the first placement');
    });

    test('the outcome is reported so a caller can react to it', () {
      final applied = _history().place(2, 4);
      expect(applied.edit, isA<EditApplied>());
      expect((applied.edit as EditApplied).cell, 2);
      expect((applied.edit as EditApplied).after, 4);
    });
  });

  // The stack is session-deep by choice: the board persists across an app kill,
  // the history does not. A reopened puzzle must start clean rather than
  // offering to undo moves from a previous sitting.
  test('a restored board starts with an empty history', () {
    final board = Board.restore(
      givens: _grid(_clues),
      placedValues: '..4${'.' * 78}',
    );
    final history = BoardHistory.start(board);

    expect(history.board.digitAt(2), 4);
    expect(history.canUndo, isFalse);
    expect(history.depth, 0);
  });
}
