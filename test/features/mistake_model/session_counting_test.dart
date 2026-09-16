import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

PuzzleSession _session({InputMode mode = InputMode.cellFirst}) =>
    PuzzleSession.start(
      board: Board.forPuzzle(givens: _gridOf(_clues)),
      solution: _gridOf(_solution),
      mode: mode,
    );

void main() {
  /// Cell 2 is empty; the solution has a 4 there.
  const empty = 2;
  const right = 4;
  const wrong = 7;

  group('a placement reaches the tally', () {
    test('a fresh session has nothing recorded', () {
      expect(_session().attempt.mistakes, 0);
      expect(_session().attempt.isPerfect, isTrue);
    });

    test('cell-first: a wrong digit counts', () {
      final after = _session().tapCell(empty).tapDigit(wrong);
      expect(after.attempt.mistakes, 1);
    });

    test('cell-first: the right digit does not', () {
      final after = _session().tapCell(empty).tapDigit(right);
      expect(after.attempt.mistakes, 0);
    });

    // One rule for both input modes: a placement that counted in one and not
    // the other would be invisible until a player compared their statistics
    // with how they actually play.
    test('digit-first: a wrong digit counts the same', () {
      final after = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(wrong).tapCell(empty);
      expect(after.attempt.mistakes, 1);
    });

    test('digit-first: the right digit does not', () {
      final after = _session(
        mode: InputMode.digitFirst,
      ).tapDigit(right).tapCell(empty);
      expect(after.attempt.mistakes, 0);
    });

    test('a long-pressed value in notes mode counts too', () {
      final after = _session()
          .withEntryKind(EntryKind.note)
          .tapCell(empty)
          .tapDigitLongPress(wrong);
      expect(after.attempt.mistakes, 1);
    });
  });

  // D-14, at the seam where it could actually break: the session is the one
  // thing that sees both notes and placements.
  group('no note reaches the tally', () {
    test('marking a wrong candidate counts nothing', () {
      final after = _session()
          .withEntryKind(EntryKind.note)
          .tapCell(empty)
          .tapDigit(wrong);
      expect(after.board.notesAt(empty).contains(wrong), isTrue);
      expect(after.attempt.mistakes, 0);
    });

    test('a whole cell of wrong candidates counts nothing', () {
      var session = _session().withEntryKind(EntryKind.note).tapCell(empty);
      for (var digit = 1; digit <= 9; digit++) {
        session = session.tapDigit(digit);
      }
      expect(after(session), 0);
    });

    test('auto-notes counts nothing', () {
      expect(after(_session().fillNotes()), 0);
    });

    test('erasing counts nothing', () {
      final session = _session().tapCell(empty).tapErase();
      expect(after(session), 0);
    });
  });

  group('a refused placement counts nothing', () {
    test('a digit with no cell selected', () {
      expect(after(_session().tapDigit(wrong)), 0);
    });

    test('a given cannot be overwritten, so nothing is recorded', () {
      // Cell 0 is the given 5.
      final session = _session().tapCell(0).tapDigit(wrong);
      expect(session.board.digitAt(0), 5);
      expect(
        after(session),
        0,
        reason: 'a digit that never landed is not a mistake',
      );
    });

    test('placing the digit already there', () {
      final placed = _session().tapCell(empty).tapDigit(wrong);
      final again = placed.tapDigit(wrong);
      expect(
        again.attempt.mistakes,
        1,
        reason: 'the refused repeat adds nothing to the one that landed',
      );
    });
  });

  group('undo does not walk the count back', () {
    test('undoing a wrong placement leaves it recorded', () {
      final after = _session().tapCell(empty).tapDigit(wrong).tapUndo();

      expect(after.board.digitAt(empty), Board.empty);
      expect(after.attempt.mistakes, 1, reason: 'the placement happened');
    });

    test('undoing back to the start still leaves it recorded', () {
      var session = _session().tapCell(empty).tapDigit(wrong);
      while (session.canUndo) {
        session = session.tapUndo();
      }
      expect(session.attempt.mistakes, 1);
    });
  });

  group('strict mode is carried, not consulted for counting', () {
    test('the count is the same whether stakes are on or off', () {
      final relaxed = _session().tapCell(empty).tapDigit(wrong);
      final strict = _session()
          .withStrictMode(true)
          .tapCell(empty)
          .tapDigit(wrong);

      expect(relaxed.attempt.mistakes, strict.attempt.mistakes);
    });

    test('turning it on and off leaves the tally alone', () {
      final session = _session().tapCell(empty).tapDigit(wrong);
      expect(session.withStrictMode(true).attempt.mistakes, 1);
      expect(
        session.withStrictMode(true).withStrictMode(false).attempt.mistakes,
        1,
        reason: 'what the player did does not change with their mind',
      );
    });

    test('it starts off', () {
      expect(_session().isStrict, isFalse);
    });
  });
}

int after(PuzzleSession session) => session.attempt.mistakes;
