import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

PuzzleSession _session({InputMode mode = InputMode.cellFirst}) =>
    PuzzleSession.start(
      board: Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid),
      mode: mode,
    );

void main() {
  group('cell-first, the default', () {
    test('a player who has changed nothing gets it', () {
      expect(_session().mode, InputMode.cellFirst);
      expect(_session().lockedDigit, isNull);
    });

    test('select a cell, tap a digit, the digit lands', () {
      final after = _session().tapCell(2).tapDigit(4);

      expect(after.selectedCell, 2);
      expect(after.board.digitAt(2), 4);
      expect(after.lastEdit, isA<EditApplied>());
    });

    test('a digit with nothing selected goes nowhere', () {
      final after = _session().tapDigit(4);

      expect(after.board.placedCount, 0);
      expect(after.lastEdit, isNull);
      expect(after.canUndo, isFalse);
    });

    test('tapping a digit does not lock it', () {
      final after = _session().tapCell(2).tapDigit(4);
      expect(after.lockedDigit, isNull);
    });

    test('erase clears the selected cell', () {
      final after = _session().tapCell(2).tapDigit(4).tapErase();
      expect(after.board.isEmptyAt(2), isTrue);
    });

    test('erase does nothing to a given', () {
      final after = _session().tapCell(0).tapErase();
      expect(after.board.digitAt(0), 5);
      expect(after.lastEdit, isA<EditRefused>());
      expect(after.canUndo, isFalse);
    });

    test('a digit onto a given is refused and changes nothing', () {
      final after = _session().tapCell(0).tapDigit(7);
      expect(after.board.digitAt(0), 5);
      expect((after.lastEdit as EditRefused).reason, EditRefusal.cellIsGiven);
    });

    test('undo reverses the last placement', () {
      final after = _session().tapCell(2).tapDigit(4).tapUndo();
      expect(after.board.isEmptyAt(2), isTrue);
    });

    test('undo with nothing to reverse is a no-op', () {
      final start = _session();
      final after = start.tapUndo();
      expect(after.board, start.board);
      expect(after.canUndo, isFalse);
    });
  });

  group('digit-first', () {
    test('choosing a digit holds it, and tapping cells places it', () {
      var session = _session(mode: InputMode.digitFirst).tapDigit(4);
      expect(session.lockedDigit, 4);
      expect(session.board.placedCount, 0, reason: 'holding is not placing');

      session = session.tapCell(2).tapCell(3);

      expect(session.board.digitAt(2), 4);
      expect(session.board.digitAt(3), 4);
      expect(session.lockedDigit, 4, reason: 'the digit stays held');
    });

    test('pressing the held digit again puts it down', () {
      final session = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(4).tapDigit(4);
      expect(session.lockedDigit, isNull);
    });

    test('choosing another digit swaps what is held', () {
      final session = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(4).tapDigit(7);
      expect(session.lockedDigit, 7);
    });

    test('with nothing held, tapping a cell only selects it', () {
      final session = _session(mode: InputMode.digitFirst).tapCell(2);
      expect(session.selectedCell, 2);
      expect(session.board.placedCount, 0);
    });

    test('erase can be held and clears the cells it is tapped on', () {
      var session = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(4).tapCell(2).tapCell(3);
      expect(session.board.placedCount, 2);

      session = session.tapErase();
      expect(session.lockedDigit, Board.empty, reason: 'the eraser is held');

      session = session.tapCell(2);
      expect(session.board.isEmptyAt(2), isTrue);
      expect(session.board.digitAt(3), 4);
    });

    test('a held digit is refused by a given without being put down', () {
      final session = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(4).tapCell(0);

      expect(session.board.digitAt(0), 5);
      expect(session.lockedDigit, 4);
      expect(session.canUndo, isFalse);
    });
  });

  // A digit held in one mode means nothing in the other. Carrying it across
  // would place digits the player did not ask for on their next tap.
  group('switching modes', () {
    test('anything held is put down', () {
      final switched = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(4).withMode(InputMode.cellFirst);

      expect(switched.mode, InputMode.cellFirst);
      expect(switched.lockedDigit, isNull);
    });

    test('the eraser is put down too', () {
      final switched = _session(
        mode: InputMode.digitFirst,
      ).tapErase().withMode(InputMode.cellFirst);
      expect(switched.lockedDigit, isNull);
    });

    test('the board and the selection survive the switch', () {
      final before = _session().tapCell(2).tapDigit(4);
      final after = before.withMode(InputMode.digitFirst);

      expect(after.board, before.board);
      expect(after.selectedCell, 2);
      expect(after.canUndo, isTrue);
    });

    test('switching to the mode already in force changes nothing', () {
      final session = _session(mode: InputMode.digitFirst).tapDigit(4);
      expect(session.withMode(InputMode.digitFirst).lockedDigit, 4);
    });
  });

  test('one set of rules serves both modes', () {
    // The same three taps, mode aside, reach the same board.
    final cellFirst = _session().tapCell(2).tapDigit(4);
    final digitFirst = _session(
      mode: InputMode.digitFirst,
    ).tapDigit(4).tapCell(2);

    expect(digitFirst.board, cellFirst.board);
  });

  // D-13, D-88. The single highest-value comfort feature for hard grids, and
  // free — **digit sweep** is the perk, and it does something else entirely.
  //
  // Derived from what the session already holds rather than kept as its own
  // sticky field: a third source would need its own rules for when it clears,
  // and each of those is a way for the pad to light the wrong digit.
  group('the highlighted digit', () {
    test('nothing is lit on a fresh puzzle', () {
      expect(_session().highlightedDigit, isNull);
    });

    test('a held digit is what is lit', () {
      final held = _session().withMode(InputMode.digitFirst).tapDigit(4);

      expect(held.lockedDigit, 4);
      expect(held.highlightedDigit, 4);
    });

    test('putting the digit down puts the light out', () {
      final down = _session()
          .withMode(InputMode.digitFirst)
          .tapDigit(4)
          .tapDigit(4);

      expect(down.lockedDigit, isNull);
      expect(down.highlightedDigit, isNull);
    });

    test('a held eraser lights nothing', () {
      final held = _session().withMode(InputMode.digitFirst).tapErase();

      expect(held.lockedDigit, Board.empty);
      expect(held.highlightedDigit, isNull);
    });

    test("a selected cell's value is lit in cell-first", () {
      // Cell 0 is the given 5.
      expect(_session().tapCell(0).highlightedDigit, 5);
    });

    test('a digit placed in the selected cell lights itself', () {
      final after = _session().tapCell(2).tapDigit(4);

      expect(after.highlightedDigit, 4);
    });

    test('an empty selected cell lights nothing', () {
      expect(_session().tapCell(2).highlightedDigit, isNull);
    });

    test('a cell holding only candidates lights nothing', () {
      final noted = _session()
          .withEntryKind(EntryKind.note)
          .tapCell(2)
          .tapDigit(4);

      expect(noted.board.notesAt(2).contains(4), isTrue);
      // Five candidates are not one digit, so there is nothing to light for.
      expect(noted.highlightedDigit, isNull);
    });

    test('a held digit outranks the selected cell', () {
      final both = _session()
          .tapCell(0) // the given 5
          .withMode(InputMode.digitFirst)
          .tapDigit(4);

      expect(both.highlightedDigit, 4);
    });

    test('changing what a digit press writes puts the light out with it', () {
      final after = _session()
          .withMode(InputMode.digitFirst)
          .tapDigit(4)
          .withEntryKind(EntryKind.note);

      expect(after.lockedDigit, isNull);
      expect(after.highlightedDigit, isNull);
    });
  });
}
