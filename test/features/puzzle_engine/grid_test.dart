import 'package:test/test.dart';

import 'package:doku_duty/features/puzzle_engine/domain/candidates.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _grid(String source) => (Grid.parse(source) as ValidGrid).grid;

void main() {
  group('parsing', () {
    test('an 81-character grid round-trips the stored format', () {
      final parsed = Grid.parse(_clues);
      expect(parsed, isA<ValidGrid>());
      final grid = (parsed as ValidGrid).grid;
      expect(grid.toStorageString(), _clues);
      expect(grid.digitAt(0), 5);
      expect(grid.digitAt(1), 3);
      expect(grid.isEmptyAt(2), isTrue);
      expect(grid.digitAt(80), 9);
    });

    test('a solved grid round-trips too', () {
      expect(_grid(_solution).toStorageString(), _solution);
    });

    test('the empty grid is eighty-one dots', () {
      expect(Grid.empty.toStorageString(), '.' * 81);
      expect(_grid('.' * 81), Grid.empty);
    });
  });

  group('malformed input is a value, never an exception', () {
    test('a grid of the wrong length is rejected', () {
      for (final source in <String>['', '.' * 80, '.' * 82, '${_clues}5']) {
        final result = Grid.parse(source);
        expect(result, isA<InvalidGrid>(), reason: 'length ${source.length}');
        final invalid = result as InvalidGrid;
        expect(invalid.problem, GridProblem.wrongLength);
        expect(invalid.description, isNotEmpty);
      }
    });

    test('a stray character is rejected, and its position is reported', () {
      final source = _clues.replaceRange(4, 5, 'x');
      final result = Grid.parse(source);
      expect(result, isA<InvalidGrid>());
      final invalid = result as InvalidGrid;
      expect(invalid.problem, GridProblem.unrecognisedCharacter);
      expect(invalid.position, 4);
      expect(invalid.description, contains('x'));
    });

    test('a zero is not a blank — only a dot is', () {
      final result = Grid.parse('0' * 81);
      expect(result, isA<InvalidGrid>());
      expect(
        (result as InvalidGrid).problem,
        GridProblem.unrecognisedCharacter,
      );
    });

    test('parsing never throws, whatever it is handed', () {
      for (final source in <String>['', 'nonsense', '≈' * 81, '1' * 200]) {
        expect(() => Grid.parse(source), returnsNormally);
      }
    });
  });

  group('cells', () {
    test('placing a digit leaves the rest of the grid alone', () {
      final before = _grid(_clues);
      final after = before.withDigit(2, 4);
      expect(after.digitAt(2), 4);
      expect(before.digitAt(2), 0, reason: 'the original is immutable');
      for (var cell = 0; cell < 81; cell++) {
        if (cell == 2) continue;
        expect(after.digitAt(cell), before.digitAt(cell));
      }
    });

    test('clearing a cell writes a blank', () {
      final cleared = _grid(_clues).cleared(0);
      expect(cleared.isEmptyAt(0), isTrue);
      expect(cleared.toStorageString()[0], '.');
    });

    test('the given count is the number of filled cells', () {
      expect(_grid(_clues).filledCount, 30);
      expect(Grid.empty.filledCount, 0);
      expect(_grid(_solution).filledCount, 81);
    });
  });

  group('candidates', () {
    test('an empty cell keeps the digits no peer has placed', () {
      final grid = _grid(_clues);
      // Cell 2 sits in row 0 (5, 3, 7), column 2 (8, 6), block 0 (5, 3, 6, 9, 8).
      expect(grid.candidatesAt(2), Candidates.of(const <int>[1, 2, 4]));
    });

    test('a filled cell offers no candidates', () {
      expect(_grid(_clues).candidatesAt(0), Candidates.none);
    });

    test('every digit is a candidate everywhere on an empty grid', () {
      for (var cell = 0; cell < 81; cell++) {
        expect(Grid.empty.candidatesAt(cell), Candidates.all);
      }
    });
  });

  group('completion', () {
    test('a solved grid is complete', () {
      expect(_grid(_solution).isComplete, isTrue);
      expect(_grid(_solution).isFull, isTrue);
    });

    test('an unfinished grid is not complete', () {
      expect(_grid(_clues).isComplete, isFalse);
      expect(_grid(_clues).isFull, isFalse);
    });

    test('a full grid that repeats a digit in a unit is not complete', () {
      final broken = _grid(_solution).withDigit(1, 5);
      expect(broken.isFull, isTrue);
      expect(broken.isComplete, isFalse);
    });
  });

  test('grids are compared by value', () {
    expect(_grid(_clues), _grid(_clues));
    expect(_grid(_clues).hashCode, _grid(_clues).hashCode);
    expect(_grid(_clues), isNot(_grid(_solution)));
  });
}
