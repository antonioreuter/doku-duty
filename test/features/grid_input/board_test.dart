import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

Board _board() => Board.forPuzzle(givens: _grid(_clues));

void main() {
  group('a board is givens plus what the player placed', () {
    test("it starts as the puzzle's givens and nothing else", () {
      final board = _board();

      expect(board.digitAt(0), 5, reason: 'a given is on the board');
      expect(board.isGiven(0), isTrue);
      expect(board.isEmptyAt(2), isTrue);
      expect(board.isGiven(2), isFalse);
      expect(board.filledCount, 30);
      expect(board.placedCount, 0);
    });

    test('it knows which cells are givens, and that never changes', () {
      final board = _board();
      final after = (board.place(2, 4) as EditApplied).board;

      for (var cell = 0; cell < 81; cell++) {
        expect(after.isGiven(cell), board.isGiven(cell), reason: 'cell $cell');
      }
      expect(
        after.isGiven(2),
        isFalse,
        reason: 'placing does not make a given',
      );
    });

    test('the whole board reads as a grid the engine understands', () {
      final board = (_board().place(2, 4) as EditApplied).board;
      expect(board.toGrid().digitAt(0), 5);
      expect(board.toGrid().digitAt(2), 4);
    });
  });

  group('placing', () {
    test('a digit lands in the cell and nothing else moves', () {
      final before = _board();
      final result = before.place(2, 4);

      expect(result, isA<EditApplied>());
      final after = (result as EditApplied).board;
      expect(after.digitAt(2), 4);
      expect(after.placedCount, 1);

      for (var cell = 0; cell < 81; cell++) {
        if (cell == 2) continue;
        expect(after.digitAt(cell), before.digitAt(cell), reason: 'cell $cell');
      }
    });

    test('the board it was placed on is unchanged', () {
      final before = _board();
      before.place(2, 4);
      expect(before.isEmptyAt(2), isTrue, reason: 'a board is a value');
    });

    test('the edit says what the cell held before and holds now', () {
      final first = _board().place(2, 4) as EditApplied;
      expect(first.cell, 2);
      expect(first.before, Board.empty);
      expect(first.after, 4);

      final second = first.board.place(2, 1) as EditApplied;
      expect(second.before, 4);
      expect(second.after, 1);
    });

    // D-05: the player did not get a logic problem wrong, they changed their
    // mind. Nothing here is entitled to an opinion about it.
    test('a digit replaces another with no complaint', () {
      final board = (_board().place(2, 4) as EditApplied).board;
      final result = board.place(2, 1);

      expect(result, isA<EditApplied>());
      expect((result as EditApplied).board.digitAt(2), 1);
      expect(result.board.placedCount, 1);
    });

    test('placing the same digit again changes nothing and is refused', () {
      final board = (_board().place(2, 4) as EditApplied).board;
      final result = board.place(2, 4);

      expect(result, isA<EditRefused>());
      expect((result as EditRefused).reason, EditRefusal.noChange);
      expect(result.board, board);
    });

    test('a wrong digit is accepted exactly as a right one is', () {
      // Cell 2 is 4 in the only solution.
      final wrong = _board().place(2, 1) as EditApplied;
      final right = _board().place(2, 4) as EditApplied;

      expect(wrong.runtimeType, right.runtimeType);
      expect(wrong.board.digitAt(2), 1);
      expect(_grid(_solution).digitAt(2), 4, reason: 'it really is wrong');
    });
  });

  group('givens are not editable', () {
    test('a placement onto a given is refused as a value, not thrown', () {
      final board = _board();
      late final BoardEdit result;
      expect(() => result = board.place(0, 7), returnsNormally);

      expect(result, isA<EditRefused>());
      expect((result as EditRefused).reason, EditRefusal.cellIsGiven);
      expect(result.board, board);
      expect(board.digitAt(0), 5);
    });

    test('an erase of a given is refused the same way', () {
      final board = _board();
      final result = board.erase(0);

      expect(result, isA<EditRefused>());
      expect((result as EditRefused).reason, EditRefusal.cellIsGiven);
      expect(board.digitAt(0), 5);
    });
  });

  group('erasing', () {
    test('it clears a placed value', () {
      final board = (_board().place(2, 4) as EditApplied).board;
      final result = board.erase(2);

      expect(result, isA<EditApplied>());
      final after = (result as EditApplied).board;
      expect(after.isEmptyAt(2), isTrue);
      expect(after.placedCount, 0);
      expect(result.before, 4);
      expect(result.after, Board.empty);
    });

    test('erasing an empty cell changes nothing and is refused', () {
      final board = _board();
      final result = board.erase(2);

      expect(result, isA<EditRefused>());
      expect((result as EditRefused).reason, EditRefusal.noChange);
    });
  });

  group('the stored form', () {
    // Only the player's placements. The givens come from the pack row, so a
    // save can never contradict the puzzle it belongs to.
    test('it stores placements only, givens as blanks', () {
      final board = (_board().place(2, 4) as EditApplied).board;
      final stored = board.toPlacedValues();

      expect(stored, hasLength(81));
      expect(stored[0], '.', reason: 'cell 0 is a given');
      expect(stored[2], '4');
    });

    test('a board round-trips through the stored form', () {
      var board = _board();
      for (final (cell, digit) in const <(int, int)>[(2, 4), (3, 6), (5, 8)]) {
        board = (board.place(cell, digit) as EditApplied).board;
      }

      final restored = Board.restore(
        givens: _grid(_clues),
        placedValues: board.toPlacedValues(),
      );

      expect(restored, board);
      expect(restored.toPlacedValues(), board.toPlacedValues());
      for (var cell = 0; cell < 81; cell++) {
        expect(restored.digitAt(cell), board.digitAt(cell));
        expect(restored.isGiven(cell), board.isGiven(cell));
      }
    });

    test('an empty board stores eighty-one blanks', () {
      expect(_board().toPlacedValues(), '.' * 81);
    });

    test('a restore that disagrees with a given ignores the placement', () {
      // A stale save from before a pack refresh must not overwrite a given.
      final restored = Board.restore(
        givens: _grid(_clues),
        placedValues: '9${'.' * 80}',
      );
      expect(restored.digitAt(0), 5);
      expect(restored.placedCount, 0);
    });
  });

  group('completion', () {
    test('a board is finished when it is full and no unit repeats', () {
      var board = _board();
      for (var cell = 0; cell < 81; cell++) {
        if (board.isGiven(cell)) continue;
        board =
            (board.place(cell, _grid(_solution).digitAt(cell)) as EditApplied)
                .board;
      }
      expect(board.isComplete, isTrue);
    });

    test('a full board with a repeat is not finished', () {
      var board = _board();
      for (var cell = 0; cell < 81; cell++) {
        if (board.isGiven(cell)) continue;
        board =
            (board.place(cell, _grid(_solution).digitAt(cell)) as EditApplied)
                .board;
      }
      final broken = (board.place(2, 1) as EditApplied).board;
      expect(broken.toGrid().isFull, isTrue);
      expect(broken.isComplete, isFalse);
    });

    test('a part-filled board is not finished', () {
      expect(_board().isComplete, isFalse);
    });
  });

  test('boards are compared by value', () {
    expect(_board(), _board());
    expect(_board().hashCode, _board().hashCode);
    expect((_board().place(2, 4) as EditApplied).board, isNot(_board()));
  });
}
