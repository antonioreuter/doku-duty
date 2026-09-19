import 'package:test/test.dart';

import 'package:doku_duty/features/completion_effects/domain/unit_completion.dart';
import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

/// A board whose givens are [source] — every cell a given, so the fixture
/// states exactly the position under test and nothing else.
Board _boardOf(String source) => Board.forPuzzle(givens: _grid(source));

/// Nine cells — one in every row, every column, and every block — so a board
/// holed at these has not one complete **unit** anywhere on it.
const List<int> _oneHolePerUnit = <int>[0, 12, 24, 28, 40, 52, 56, 68, 80];

/// The solution with [cells] blanked out, as a puzzle the player fills in.
String _withHoles(Iterable<int> cells) {
  final digits = _solution.split('');
  for (final cell in cells) {
    digits[cell] = '.';
  }
  return digits.join();
}

Board _place(Board board, int cell, int digit) =>
    (board.place(cell, digit) as EditApplied).board;

Unit _row(int index) => GridGeometry.unitsOfKind(UnitKind.row)[index];
Unit _column(int index) => GridGeometry.unitsOfKind(UnitKind.column)[index];
Unit _block(int index) => GridGeometry.unitsOfKind(UnitKind.block)[index];

void main() {
  group('a unit is complete when it holds nine distinct digits', () {
    test('a row of nine distinct digits is complete', () {
      final board = _boardOf(_solution);

      expect(UnitCompletion.isComplete(board, _row(0)), isTrue);
      expect(UnitCompletion.isComplete(board, _column(0)), isTrue);
      expect(UnitCompletion.isComplete(board, _block(0)), isTrue);
    });

    test('a row with an empty cell is not complete', () {
      final board = _boardOf(_withHoles(<int>[4]));

      expect(UnitCompletion.isComplete(board, _row(0)), isFalse);
      expect(UnitCompletion.isComplete(board, _column(4)), isFalse);
      expect(UnitCompletion.isComplete(board, _block(1)), isFalse);
    });

    test('a full row that repeats a digit is not complete', () {
      // Row 0 is 534678912; putting its own 5 into the 3's cell fills every
      // cell and leaves the row holding 5 twice.
      final board = _place(_boardOf(_withHoles(<int>[1])), 1, 5);

      expect(board.digitAt(1), 5, reason: 'the row is full');
      expect(
        UnitCompletion.isComplete(board, _row(0)),
        isFalse,
        reason: 'nine values, eight distinct digits',
      );
    });

    test('filling the last cell completes the row', () {
      final before = _boardOf(_withHoles(<int>[4]));
      final after = _place(before, 4, 7);

      expect(UnitCompletion.isComplete(before, _row(0)), isFalse);
      expect(UnitCompletion.isComplete(after, _row(0)), isTrue);
    });

    test('erasing from a complete unit un-completes it', () {
      final filled = _place(_boardOf(_withHoles(<int>[4])), 4, 7);
      final erased = (filled.erase(4) as EditApplied).board;

      expect(UnitCompletion.isComplete(filled, _row(0)), isTrue);
      expect(UnitCompletion.isComplete(erased, _row(0)), isFalse);
    });
  });

  group('what one change did to the units around it', () {
    test('a placement reports the units it completed', () {
      // Cell 13 stays empty, so filling cell 4 completes its row and leaves
      // its column and its block still holed.
      final before = _boardOf(_withHoles(<int>[4, 13]));
      final after = _place(before, 4, 7);

      final change = UnitCompletion.forChange(
        before: before,
        after: after,
        cell: 4,
      );

      expect(change.completed.map((u) => u.kind), <UnitKind>[UnitKind.row]);
      expect(change.completed.single.index, 0);
      expect(change.broken, isEmpty);
    });

    test('completing several units reports them row, column, then block', () {
      // The only hole left anywhere its three units share is cell 4's own.
      final before = _boardOf(_withHoles(<int>[4]));
      final after = _place(before, 4, 7);

      final change = UnitCompletion.forChange(
        before: before,
        after: after,
        cell: 4,
      );

      expect(
        change.completed.map((u) => u.kind).toList(),
        <UnitKind>[UnitKind.row, UnitKind.column, UnitKind.block],
        reason: 'the order a cascade chains in (D-47)',
      );
    });

    test('an erase reports the units it broke', () {
      final filled = _boardOf(_solution);
      final erased = _boardOf(_withHoles(<int>[4]));

      final change = UnitCompletion.forChange(
        before: filled,
        after: erased,
        cell: 4,
      );

      expect(change.completed, isEmpty);
      expect(change.broken.map((u) => u.kind).toList(), <UnitKind>[
        UnitKind.row,
        UnitKind.column,
        UnitKind.block,
      ]);
    });

    test(
      'a placement into units that were already complete reports nothing',
      () {
        final board = _boardOf(_solution);

        final change = UnitCompletion.forChange(
          before: board,
          after: board,
          cell: 4,
        );

        expect(change.completed, isEmpty);
        expect(change.broken, isEmpty);
        expect(change.isEmpty, isTrue);
      },
    );

    test('only the changed cell\'s three units are considered', () {
      // A board where row 8 is complete and row 0 has a hole. A placement in
      // row 0 must not report row 8, which was complete before and after.
      final before = _boardOf(_withHoles(<int>[4]));
      final after = _place(before, 4, 7);

      final change = UnitCompletion.forChange(
        before: before,
        after: after,
        cell: 4,
      );

      for (final unit in <Unit>[...change.completed, ...change.broken]) {
        expect(
          GridGeometry.unitsOf(4),
          contains(unit),
          reason: '$unit is not one of cell 4\'s units',
        );
      }
    });
  });

  group('completion never reads the solution', () {
    test('a complete unit that disagrees with the solution is complete', () {
      // Row 0 is 534678912. Swap the 1 and the 2 in cells 6 and 7: still nine
      // distinct digits, and two of them are now wrong.
      final digits = _solution.split('');
      digits[6] = '1';
      digits[7] = '9';
      digits[8] = '2';
      final board = _boardOf(digits.join());

      expect(
        UnitCompletion.isComplete(board, _row(0)),
        isTrue,
        reason:
            'completion states a fact about the unit, not a verdict on the '
            'player (D-04, constraint 1)',
      );
    });

    test(
      'a full board that repeats a digit is not finished, and says no more',
      () {
        final board = _place(_boardOf(_withHoles(<int>[1])), 1, 5);

        expect(board.filledCount, 81, reason: 'every cell holds a value');
        expect(UnitCompletion.isBoardComplete(board), isFalse);
      },
    );

    test('a finished board is finished', () {
      expect(UnitCompletion.isBoardComplete(_boardOf(_solution)), isTrue);
    });

    test('a board with an empty cell is not finished', () {
      expect(
        UnitCompletion.isBoardComplete(_boardOf(_withHoles(<int>[40]))),
        isFalse,
      );
    });
  });

  group('the tint is derived from the board', () {
    test('a completed row tints its nine cells', () {
      final board = _place(_boardOf(_withHoles(<int>[4, 40])), 4, 7);

      final tinted = UnitCompletion.tintedCells(board);
      for (final cell in _row(0).cells) {
        expect(tinted, contains(cell), reason: 'cell $cell is in row 0');
      }
    });

    test('a cell in three completed units is tinted once, identically', () {
      final board = _boardOf(_solution);
      final tinted = UnitCompletion.tintedCells(board);

      // A Set cannot hold a cell twice, which is the structural form of "one
      // flat level, never additive" (D-48) — there is no count to stack.
      expect(tinted.length, GridGeometry.cellCount);
      expect(tinted, contains(0));
    });

    test('a cell in no completed unit is not tinted', () {
      final board = _boardOf(_withHoles(_oneHolePerUnit));

      final tinted = UnitCompletion.tintedCells(board);
      expect(tinted, isEmpty, reason: 'no unit is complete');
    });

    test('a cell held by another completed unit keeps its tint', () {
      // Row 0 complete, column 0 not. Cell 0 is in both, so it stays tinted.
      final board = _boardOf(_withHoles(<int>[36]));

      final tinted = UnitCompletion.tintedCells(board);
      expect(tinted, contains(0), reason: 'row 0 is still complete');
      expect(
        tinted,
        isNot(contains(36)),
        reason: 'cell 36 is empty and in no complete unit',
      );
    });
  });

  group('only values complete a unit', () {
    test('filling the last empty cell with candidates completes nothing', () {
      final board = _boardOf(_withHoles(_oneHolePerUnit));
      var noted = board;
      for (var digit = 1; digit <= 9; digit++) {
        noted = (noted.toggleNote(0, digit) as EditApplied).board;
      }

      expect(noted.notesAt(0).digits.length, 9, reason: 'nine candidates');
      expect(UnitCompletion.isComplete(noted, _row(0)), isFalse);
      expect(
        UnitCompletion.tintedCells(noted),
        isEmpty,
        reason: 'candidates are thinking, and thinking completes nothing',
      );
    });

    test('a note change reports no completion', () {
      final before = _boardOf(_withHoles(_oneHolePerUnit));
      final after = (before.toggleNote(0, 7) as EditApplied).board;

      final change = UnitCompletion.forChange(
        before: before,
        after: after,
        cell: 0,
      );
      expect(change.isEmpty, isTrue);
      expect(after.notesAt(0), isNot(NoteSet.none));
    });
  });
}
