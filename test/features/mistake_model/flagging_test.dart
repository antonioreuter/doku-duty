import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

PuzzleSession _session({bool strict = false}) => PuzzleSession.start(
  board: Board.forPuzzle(givens: _gridOf(_clues)),
  solution: _gridOf(_solution),
  isStrict: strict,
);

void main() {
  /// Cell 2 is empty; the solution has a 4 there. Cell 3's is 6.
  const empty = 2;
  const right = 4;
  const wrong = 7;
  const otherEmpty = 3;

  group('with stakes off, nothing is flagged', () {
    test('a wrong digit is not flagged', () {
      final after = _session().tapCell(empty).tapDigit(wrong);

      expect(after.flaggedCells, isEmpty);
      expect(after.attempt.mistakes, 1, reason: 'recorded, and not shown');
    });

    test('a board full of wrong digits flags nothing', () {
      var session = _session();
      for (final cell in const <int>[2, 3, 5]) {
        session = session.tapCell(cell).tapDigit(9);
      }
      expect(session.flaggedCells, isEmpty);
    });
  });

  group('with stakes on, a disagreeing cell is flagged at once', () {
    test('a wrong digit is flagged the moment it is placed', () {
      final after = _session(strict: true).tapCell(empty).tapDigit(wrong);

      expect(after.flaggedCells, <int>{empty});
    });

    test('the right digit is not flagged', () {
      final after = _session(strict: true).tapCell(empty).tapDigit(right);

      expect(after.flaggedCells, isEmpty);
    });

    test('correcting a flagged cell unflags it', () {
      final after = _session(
        strict: true,
      ).tapCell(empty).tapDigit(wrong).tapDigit(right);

      expect(after.flaggedCells, isEmpty);
      expect(
        after.attempt.mistakes,
        1,
        reason: 'the flag goes, the tally does not',
      );
    });

    test('erasing a flagged cell unflags it', () {
      final after = _session(
        strict: true,
      ).tapCell(empty).tapDigit(wrong).tapErase();

      expect(after.flaggedCells, isEmpty);
    });

    test('several wrong cells are each flagged', () {
      var session = _session(strict: true);
      session = session.tapCell(empty).tapDigit(wrong);
      session = session.tapCell(otherEmpty).tapDigit(9);

      expect(session.flaggedCells, <int>{empty, otherEmpty});
    });

    test('a given is never flagged', () {
      // Cell 0 is the given 5 and agrees with the solution by construction.
      expect(_session(strict: true).flaggedCells, isEmpty);
    });

    test('a note is never flagged, whatever it says', () {
      var session = _session(strict: true).withEntryKind(EntryKind.note);
      session = session.tapCell(empty);
      for (var digit = 1; digit <= 9; digit++) {
        session = session.tapDigit(digit);
      }

      expect(session.flaggedCells, isEmpty, reason: 'D-14');
    });
  });

  // D-05 restricts *counting*; flagging states a fact. Strict mode promises the
  // board is checked, so a cell that disagrees is shown as disagreeing however
  // it got that way — and it still costs the player nothing.
  group('flagging and counting are separate', () {
    test('an overwritten correct cell is flagged and not counted', () {
      final after = _session(
        strict: true,
      ).tapCell(empty).tapDigit(right).tapDigit(wrong);

      expect(after.flaggedCells, <int>{empty});
      expect(after.attempt.mistakes, 0, reason: 'D-05');
    });

    test(
      'a counted cell that is later corrected keeps the count, loses the flag',
      () {
        final after = _session(
          strict: true,
        ).tapCell(empty).tapDigit(wrong).tapDigit(right);

        expect(after.flaggedCells, isEmpty);
        expect(after.attempt.mistakes, 1);
      },
    );
  });

  // D-94: one switch, and leaving it must be as available as entering it.
  group('turning stakes off lifts the flagging at once', () {
    test('the flags go the moment it is turned off', () {
      final strict = _session(strict: true).tapCell(empty).tapDigit(wrong);
      expect(strict.flaggedCells, isNotEmpty);

      expect(strict.withStrictMode(false).flaggedCells, isEmpty);
    });

    test('and come back if it is turned on again', () {
      final session = _session().tapCell(empty).tapDigit(wrong);

      expect(session.flaggedCells, isEmpty);
      expect(session.withStrictMode(true).flaggedCells, <int>{empty});
    });

    test('the board and the tally are untouched either way', () {
      final session = _session(strict: true).tapCell(empty).tapDigit(wrong);
      final relaxed = session.withStrictMode(false);

      expect(relaxed.board.digitAt(empty), wrong);
      expect(relaxed.attempt.mistakes, 1);
    });
  });
}
