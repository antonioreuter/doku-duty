import 'dart:io';

import 'package:test/test.dart';

import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/placement.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

Grid _gridOf(String source) => (Grid.parse(source) as ValidGrid).grid;

void main() {
  final clues = _gridOf(_clues);
  final solution = _gridOf(_solution);

  /// Cell 2 is empty in the clues; the solution has a 4 there.
  const empty = 2;
  const right = 4;
  const wrong = 7;
  const alsoWrong = 8;

  PlacementReport report(Grid grid, int cell, int digit) => inspectPlacement(
    grid: grid,
    solution: solution,
    cell: cell,
    digit: digit,
  );

  group('an attempt starts clean', () {
    test('a fresh attempt has no mistakes', () {
      expect(Attempt.fresh.mistakes, 0);
      expect(Attempt.fresh.isPerfect, isTrue);
    });

    test('a right placement leaves it clean', () {
      final after = Attempt.fresh.recording(report(clues, empty, right));
      expect(after.mistakes, 0);
      expect(after.isPerfect, isTrue);
    });

    test('a wrong placement counts once', () {
      final after = Attempt.fresh.recording(report(clues, empty, wrong));
      expect(after.mistakes, 1);
      expect(after.isPerfect, isFalse);
    });
  });

  // The tally is what the player did, not which cells ended up wrong. Ace
  // chalks a mark on the wall for each one.
  group('a mistake is one wrong placement', () {
    // At this layer every report is a placement that landed; whether the board
    // would refuse one is `Board`'s question, and the session's test covers it.
    test('the same wrong digit reported twice counts twice', () {
      var attempt = Attempt.fresh.recording(report(clues, empty, wrong));
      final board = clues.withDigit(empty, wrong);
      attempt = attempt.recording(report(board, empty, wrong));

      expect(attempt.mistakes, 2);
    });

    test('two different wrong digits in one cell count twice', () {
      var attempt = Attempt.fresh.recording(report(clues, empty, wrong));
      final board = clues.withDigit(empty, wrong);
      attempt = attempt.recording(report(board, empty, alsoWrong));

      expect(attempt.mistakes, 2);
    });

    test('wrong placements in different cells each count', () {
      var attempt = Attempt.fresh;
      // Cell 3's solution is 6, cell 5's is 8.
      for (final (cell, digit) in const <(int, int)>[(2, 7), (3, 1), (5, 2)]) {
        attempt = attempt.recording(report(clues, cell, digit));
      }
      expect(attempt.mistakes, 3);
    });
  });

  group('nothing walks the count back', () {
    test('correcting the cell leaves the count where it was', () {
      var attempt = Attempt.fresh.recording(report(clues, empty, wrong));
      final board = clues.withDigit(empty, wrong);
      attempt = attempt.recording(report(board, empty, right));

      expect(attempt.mistakes, 1, reason: 'the placement still happened');
    });

    test(
      'overwriting the corrected cell is exempt, and still does not drop it',
      () {
        var attempt = Attempt.fresh.recording(report(clues, empty, wrong));
        var board = clues.withDigit(empty, wrong);
        attempt = attempt.recording(report(board, empty, right));
        board = board.withDigit(empty, right);
        // D-05: this one is exempt, so the count neither rises nor falls.
        attempt = attempt.recording(report(board, empty, alsoWrong));

        expect(attempt.mistakes, 1);
      },
    );

    // D-96, and the reason for it: a count that undo could walk back measures
    // nothing. Undo reverses the board; it does not reverse what happened.
    test('the attempt offers no way at all to lower the count', () {
      // The code, with the prose stripped: the doc comment explains why undo
      // does not reach the count, and a scan that read it would fail on the
      // explanation rather than on the API.
      final code = File('lib/features/mistake_model/domain/attempt.dart')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      for (final forbidden in const <String>[
        'undo',
        'decrement',
        'clear',
        '- 1',
        'mistakes -',
      ]) {
        expect(
          code,
          isNot(contains(forbidden)),
          reason: 'the count must only ever rise ($forbidden)',
        );
      }
      // And the one operation it does have takes a placement, so the only way
      // the number moves is a player putting a digit down.
      expect(code, contains('Attempt recording(PlacementReport'));
      expect(code, contains('mistakes + 1'));
    });

    test('a fresh attempt is the only way back to zero', () {
      final attempt = Attempt.fresh.recording(report(clues, empty, wrong));
      expect(attempt.mistakes, 1);
      expect(Attempt.fresh.mistakes, 0, reason: 'starting again, not undoing');
    });
  });

  group('the value is immutable', () {
    test('recording returns a new attempt and leaves the old one alone', () {
      final before = Attempt.fresh.recording(report(clues, empty, wrong));
      final after = before.recording(report(clues, 3, 1));

      expect(before.mistakes, 1);
      expect(after.mistakes, 2);
    });

    test(
      'an exempt placement returns an attempt that still compares equal',
      () {
        final board = clues.withDigit(empty, right);
        final before = Attempt.fresh;
        final after = before.recording(report(board, empty, wrong));

        expect(after, before);
      },
    );
  });
}
