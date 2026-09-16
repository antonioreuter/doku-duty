import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/puzzle_session.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

PuzzleSession _session({bool strict = true}) => PuzzleSession.start(
  board: Board.forPuzzle(givens: _gridOf(_clues)),
  solution: _gridOf(_solution),
  isStrict: strict,
);

/// Three wrong placements, in three cells whose solutions are 4, 6 and 8.
PuzzleSession _toTheLimit(PuzzleSession session, {int mistakes = 3}) {
  var current = session;
  for (final cell in const <int>[2, 3, 5].take(mistakes)) {
    current = current.tapCell(cell).tapDigit(9);
  }
  return current;
}

void main() {
  group('the third mistake ends the attempt', () {
    test('two do not', () {
      final session = _toTheLimit(_session(), mistakes: 2);

      expect(session.attempt.mistakes, 2);
      expect(session.isOver, isFalse);
      expect(session.mistakesRemaining, 1);
    });

    test('the third does', () {
      final session = _toTheLimit(_session());

      expect(session.attempt.mistakes, Attempt.strictLimit);
      expect(session.isOver, isTrue);
      expect(session.mistakesRemaining, 0);
    });

    // Constraint 1: there is no limit outside the mode. Not a larger one — none.
    test('the third ends nothing with stakes off', () {
      var session = _toTheLimit(_session(strict: false));
      expect(session.isOver, isFalse);

      // And a fourth, a fifth, a sixth. Row 0's solution is 534678912, so
      // these three digits are each wrong for their cell.
      for (final (cell, digit) in const <(int, int)>[(6, 1), (7, 2), (8, 3)]) {
        session = session.tapCell(cell).tapDigit(digit);
      }
      expect(session.attempt.mistakes, 6);
      expect(session.isOver, isFalse);
      expect(session.mistakesRemaining, isNull);
    });

    test('an exempt placement does not move the attempt towards its end', () {
      // D-05: cell 2's solution is 4. Place it right, then wrong, repeatedly.
      var session = _session().tapCell(2).tapDigit(4);
      for (var i = 0; i < 5; i++) {
        session = session.tapDigit(9).tapDigit(4);
      }

      expect(session.attempt.mistakes, 0);
      expect(session.isOver, isFalse);
    });
  });

  group('an ended attempt accepts nothing', () {
    test('no placement', () {
      final ended = _toTheLimit(_session());
      final after = ended.tapCell(6).tapDigit(1);

      expect(after.board, ended.board);
      expect(after.attempt.mistakes, Attempt.strictLimit);
    });

    test('no note', () {
      final ended = _toTheLimit(_session());
      final after = ended.withEntryKind(EntryKind.note).tapCell(6).tapDigit(1);

      expect(after.board.notesAt(6).isEmpty, isTrue);
    });

    test('no erase', () {
      final ended = _toTheLimit(_session());
      final after = ended.tapCell(2).tapErase();

      expect(after.board.digitAt(2), ended.board.digitAt(2));
    });

    test('no undo', () {
      final ended = _toTheLimit(_session());
      final after = ended.tapUndo();

      expect(after.board, ended.board);
      expect(
        after.isOver,
        isTrue,
        reason: 'undo is not a way back into an attempt that is over',
      );
    });

    test('no auto-notes, no clear, no promote', () {
      final ended = _toTheLimit(_session());

      expect(ended.fillNotes().board, ended.board);
      expect(ended.clearProvisional().board, ended.board);
      expect(ended.promoteProvisional().board, ended.board);
    });

    test('the board is still there to look at', () {
      final ended = _toTheLimit(_session());

      // Locked, not cleared: the player gets to see what they did.
      expect(ended.board.digitAt(2), 9);
      expect(ended.flaggedCells, isNotEmpty);
    });
  });

  group('starting again', () {
    test('gives the grid as the puzzle was first opened', () {
      final restarted = _toTheLimit(_session()).restarted();

      for (var cell = 0; cell < 81; cell++) {
        expect(
          restarted.board.digitAt(cell),
          restarted.board.isGiven(cell) ? isNot(Board.empty) : Board.empty,
          reason: 'cell $cell',
        );
        expect(restarted.board.notesAt(cell).isEmpty, isTrue);
      }
    });

    test('puts the count back to zero', () {
      final restarted = _toTheLimit(_session()).restarted();

      expect(restarted.attempt.mistakes, 0);
      expect(restarted.isOver, isFalse);
      expect(restarted.mistakesRemaining, Attempt.strictLimit);
    });

    test('keeps the mode the player chose', () {
      final restarted = _toTheLimit(_session()).restarted();

      expect(restarted.isStrict, isTrue, reason: 'they opted in, not out');
    });

    test('has nothing to undo', () {
      final restarted = _toTheLimit(_session()).restarted();

      expect(restarted.canUndo, isFalse);
    });

    test('is available before the end too', () {
      // Nothing about restarting depends on having failed.
      final restarted = _session().tapCell(2).tapDigit(9).restarted();
      expect(restarted.attempt.mistakes, 0);
      expect(restarted.board.digitAt(2), Board.empty);
    });
  });

  // D-94 says leaving the mode must be as available as entering it — but the
  // switch governs what happens *next*. D-95 refused "continue without stakes"
  // as a way out of an attempt that has ended, and a setting is not a loophole
  // back into it.
  group('turning stakes off does not un-end an attempt', () {
    test('an ended attempt stays ended', () {
      final ended = _toTheLimit(_session());
      expect(ended.isOver, isTrue);

      final relaxed = ended.withStrictMode(false);

      expect(
        relaxed.isOver,
        isTrue,
        reason: 'the switch does not reach back into a run that is over',
      );
      expect(
        relaxed.mistakesRemaining,
        isNull,
        reason: 'no cap outside stakes',
      );
      expect(
        relaxed.flaggedCells,
        isEmpty,
        reason: 'flagging is for what next',
      );
    });

    test('and it still accepts nothing', () {
      final relaxed = _toTheLimit(_session()).withStrictMode(false);
      final after = relaxed.tapCell(6).tapDigit(9);

      expect(after.board, relaxed.board);
    });

    test('starting again is the way out, and it works', () {
      final restarted = _toTheLimit(
        _session(),
      ).withStrictMode(false).restarted();

      expect(restarted.isOver, isFalse);
      expect(restarted.attempt.mistakes, 0);
      expect(restarted.tapCell(6).tapDigit(9).board.digitAt(6), 9);
    });

    // The cap itself does lift for a run that had *not* ended: a player who
    // leaves the mode with two mistakes against them is no longer counting
    // down to anything.
    test('a run short of the limit loses its cap and its flags', () {
      final two = _toTheLimit(_session(), mistakes: 2);

      final relaxed = two.withStrictMode(false);

      expect(relaxed.isOver, isFalse);
      expect(relaxed.mistakesRemaining, isNull);
      expect(relaxed.flaggedCells, isEmpty);
      expect(relaxed.tapCell(6).tapDigit(1).board.digitAt(6), 1);
    });

    test('and turning them back on restores both', () {
      final two = _toTheLimit(_session(), mistakes: 2).withStrictMode(false);
      final strict = two.withStrictMode(true);

      expect(strict.mistakesRemaining, 1);
      expect(strict.flaggedCells, isNotEmpty);
      expect(strict.isOver, isFalse);
    });

    test('three made outside stakes end it the moment stakes go on', () {
      final loose = _toTheLimit(_session(strict: false));
      expect(loose.isOver, isFalse);

      expect(loose.withStrictMode(true).isOver, isTrue);
    });
  });

  // Constraint 1, and the reason strict mode is opt-in: the stakes are the
  // point. Selling a way out of them would make the mode a funnel.
  test('nothing offers a way to buy the attempt back', () {
    for (final path in const <String>[
      'lib/features/mistake_model/domain/attempt.dart',
      'lib/features/mistake_model/domain/mistake.dart',
      'lib/features/mistake_model/application/strict_mode.dart',
      'lib/features/grid_input/domain/puzzle_session.dart',
      // The screen is the only surface that could actually carry an offer, so
      // leaving it out was leaving out the thing being guarded against.
      'lib/features/grid_input/presentation/puzzle_screen.dart',
    ]) {
      final source = File(path).readAsStringSync().toLowerCase();
      for (final forbidden in const <String>[
        'revive',
        'continue_',
        'extralife',
        'extra life',
        'rewarded',
        'stamp',
        'purchase',
        'watchad',
        'second chance',
      ]) {
        expect(source, isNot(contains(forbidden)), reason: '$path: $forbidden');
      }
    }
  });
}
