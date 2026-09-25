import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/board_history.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/persistence/domain/note_enums.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

import '../puzzle_engine/support/killer.dart';
import '../puzzle_engine/support/positions.dart';

/// An empty **killer** board over the reference **cage**s.
Board _killer() => Board.forPuzzle(
  givens: Grid.empty,
  cages: referenceKillerCages(referenceSolution),
);

Board _applied(BoardEdit edit) => (edit as EditApplied).board;

// Cage 'i' of the reference shape holds r3c2 and r4c1: different row,
// different column, different block. Only the **cage** makes them **peer**s.
final int _placed = at(2, 1);
final int _mate = at(3, 0);

// Cage 'b' is r1c4 and r2c4, summing to 7 — so 7, 8 and 9 are impossible
// there by arithmetic, and only by arithmetic.
final int _pairHead = at(0, 3);

void main() {
  test('the fixture is what the tests below assume', () {
    final cages = referenceKillerCages(referenceSolution);
    expect(cages.cageOf(_placed), same(cages.cageOf(_mate)));
    expect(GridGeometry.peersOf(_placed), isNot(contains(_mate)));
    expect(cages.cageOf(_pairHead).size, 2);
    expect(cages.cageOf(_pairHead).sum, 7);
  });

  group('auto-cleanup on a killer board (D-130)', () {
    test(
      'a placement removes the digit from a cage mate outside its units',
      () {
        var board = _applied(_killer().toggleNote(_mate, 4));
        board = _applied(board.toggleNote(_mate, 6));

        board = _applied(board.place(_placed, 4));

        expect(board.notesAt(_mate), NoteSet.of(const <int>[6]));
      },
    );

    test('a provisional note on a cage mate goes too', () {
      var board = _applied(
        _killer().toggleNote(_mate, 4, ink: NoteKind.provisional),
      );

      board = _applied(board.place(_placed, 4));

      expect(board.notesAt(_mate).contains(4), isFalse);
    });

    test('undo restores the cage mate\'s candidate, in its ink and slot', () {
      var history = BoardHistory.start(_killer());
      history = history.toggleNote(_mate, 4, ink: NoteKind.provisional).history;
      history = history.toggleNote(_mate, 9).history;
      final before = history.board.notesAt(_mate);

      history = history.place(_placed, 4).history;
      expect(history.board.notesAt(_mate).contains(4), isFalse);

      // Equality on a note set covers slot and ink alike.
      expect(history.undo().board.notesAt(_mate), before);
      expect(before.inkOf(4), NoteKind.provisional);
    });

    test('the same board without cages leaves that candidate alone', () {
      var board = _applied(
        Board.forPuzzle(givens: Grid.empty).toggleNote(_mate, 4),
      );
      board = _applied(board.place(_placed, 4));
      expect(board.notesAt(_mate), NoteSet.of(const <int>[4]));
    });
  });

  group('auto-notes on a killer board', () {
    test('a cage mate\'s value is excluded', () {
      var board = _applied(_killer().place(_mate, 7));

      board = _applied(board.fillNotes());

      expect(board.notesAt(_placed).contains(7), isFalse);
    });

    test('a sum-impossible digit is still added — the arithmetic is the '
        'player\'s', () {
      final board = _applied(_killer().fillNotes());

      for (final digit in const <int>[7, 8, 9]) {
        expect(board.notesAt(_pairHead).contains(digit), isTrue);
      }
      expect(board.notesAt(_pairHead).length, 9);
    });
  });

  test('the board reports its peers, cage mates included', () {
    final board = _killer();
    expect(board.peersOf(_placed), contains(_mate));
    expect(
      Board.forPuzzle(givens: Grid.empty).peersOf(_placed),
      GridGeometry.peersOf(_placed),
    );
  });

  test('a restart keeps the cages', () {
    final board = _applied(_killer().place(_placed, 4));
    expect(board.asFirstOpened().cages, isNotNull);
    expect(board.asFirstOpened().peersOf(_placed), contains(_mate));
  });

  test('a restored save keeps the cages', () {
    final board = Board.restore(
      givens: Grid.empty,
      placedValues: '.' * 81,
      cages: referenceKillerCages(referenceSolution),
    );
    expect(board.peersOf(_placed), contains(_mate));
  });

  // 9.4: both already compare against the stored solution, which is what makes
  // them right on a **killer** board without a line changing.
  group('what compares against the solution needs no change', () {
    final solution = gridOf(referenceSolution);

    test('the mistake model counts a wrong digit on a killer board', () {
      final session = PuzzleSession.start(
        board: _killer(),
        solution: solution,
        mode: InputMode.cellFirst,
      );
      final right = solution.digitAt(_placed);
      final wrong = right == 9 ? 8 : right + 1;

      expect(session.tapCell(_placed).tapDigit(right).attempt.mistakes, 0);
      expect(session.tapCell(_placed).tapDigit(wrong).attempt.mistakes, 1);
    });

    test('a killer board filled with its solution is solved', () {
      var board = _killer();
      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        board = _applied(board.place(cell, solution.digitAt(cell)));
      }
      expect(board.isComplete, isTrue);
      expect(board.toGrid(), solution);
    });
  });
}
