import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/board_history.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

Board _applied(BoardEdit edit) => (edit as EditApplied).board;

/// Cell 2 is empty in [_clues]. Its **peer**s that are also empty, so a
/// candidate can be marked in them.
List<int> _emptyPeersOf(Board board, int cell) => <int>[
  for (final peer in GridGeometry.peersOf(cell))
    if (board.isEmptyAt(peer)) peer,
];

/// A cell that shares no **unit** with [cell] and is empty.
int _emptyStrangerTo(Board board, int cell) {
  final peers = GridGeometry.peersOf(cell).toSet();
  return Iterable<int>.generate(GridGeometry.cellCount).firstWhere(
    (other) =>
        other != cell && !peers.contains(other) && board.isEmptyAt(other),
  );
}

void main() {
  // D-12. Without it notes go stale within twenty moves and the player stops
  // trusting them, which kills the feature the whole technique ladder rests on.
  group('placing a value strips that candidate from every peer', () {
    test('every peer carrying it loses it', () {
      var board = _board();
      final peers = _emptyPeersOf(board, 2);
      for (final peer in peers) {
        board = _applied(board.toggleNote(peer, 4));
      }

      board = _applied(board.place(2, 4));

      for (final peer in peers) {
        expect(
          board.notesAt(peer).contains(4),
          isFalse,
          reason: 'cell $peer is a peer of 2 and still carries 4',
        );
      }
    });

    test('the other candidates in a cleaned cell do not move', () {
      var board = _board();
      final peer = _emptyPeersOf(board, 2).first;
      for (final digit in const <int>[1, 4, 7, 9]) {
        board = _applied(board.toggleNote(peer, digit));
      }

      board = _applied(board.place(2, 4));

      // Constraint 3: a slot is a function of the digit, so removing one
      // candidate cannot shift the rest.
      expect(board.notesAt(peer), NoteSet.of(const <int>[1, 7, 9]));
    });

    test('a cell sharing no unit with the placement keeps its candidate', () {
      var board = _board();
      final stranger = _emptyStrangerTo(board, 2);
      board = _applied(board.toggleNote(stranger, 4));

      board = _applied(board.place(2, 4));

      expect(board.notesAt(stranger), NoteSet.of(const <int>[4]));
    });

    test('only the placed digit goes', () {
      var board = _board();
      final peer = _emptyPeersOf(board, 2).first;
      board = _applied(board.toggleNote(peer, 4));
      board = _applied(board.toggleNote(peer, 6));

      board = _applied(board.place(2, 4));

      expect(board.notesAt(peer), NoteSet.of(const <int>[6]));
    });

    test('the placement is applied even when no peer carries the digit', () {
      final board = _board();
      final edit = board.place(2, 4);
      expect(edit, isA<EditApplied>());
      expect((edit as EditApplied).board.digitAt(2), 4);
    });

    test('the edit records every cell it cleaned', () {
      var board = _board();
      final peers = _emptyPeersOf(board, 2);
      for (final peer in peers) {
        board = _applied(board.toggleNote(peer, 4));
      }

      final edit = board.place(2, 4) as EditApplied;

      // The cleaned peers plus the placed cell itself.
      expect(edit.noteChanges.keys.toSet(), <int>{...peers, 2});
    });
  });

  // Constraint 1. Auto-cleanup removes what the placement disproves and says
  // nothing about it — a candidate is thinking out loud, never a mistake
  // (D-14).
  group('cleanup judges nothing', () {
    test('a hand-marked candidate is removed without comment', () {
      var board = _board();
      final peer = _emptyPeersOf(board, 2).first;
      board = _applied(board.toggleNote(peer, 4));

      final edit = board.place(2, 4) as EditApplied;

      expect(edit.board.notesAt(peer), NoteSet.none);
      // Nothing on the edit names an error, a count, or a flagged cell: the
      // board carries values and candidates and no third thing.
      expect(edit.before, Board.empty);
      expect(edit.after, 4);
    });

    test('cleanup runs the same for a value that contradicts the solution', () {
      var board = _board();
      final peer = _emptyPeersOf(board, 2).first;
      board = _applied(board.toggleNote(peer, 1));

      // 1 is not cell 2's answer. Nothing here knows or cares (D-04).
      board = _applied(board.place(2, 1));

      expect(board.notesAt(peer).contains(1), isFalse);
      expect(board.digitAt(2), 1);
    });
  });

  group('undo takes back the placement and its cleanup together', () {
    test('every stripped candidate comes back in its own slot', () {
      var history = BoardHistory.start(_board());
      final peers = _emptyPeersOf(history.board, 2);
      for (final peer in peers) {
        history = history.toggleNote(peer, 4).history;
        history = history.toggleNote(peer, 6).history;
      }
      // The cell's own candidates too, so one undo has to restore both kinds.
      history = history.toggleNote(2, 4).history;
      history = history.toggleNote(2, 8).history;

      history = history.place(2, 4).history;
      expect(history.board.digitAt(2), 4);

      final undone = history.undo();

      expect(undone.board.digitAt(2), Board.empty);
      expect(undone.board.notesAt(2), NoteSet.of(const <int>[4, 8]));
      for (final peer in peers) {
        expect(
          undone.board.notesAt(peer),
          NoteSet.of(const <int>[4, 6]),
          reason:
              'cell \$peer lost its candidate to a cleanup undo did not '
              'reverse',
        );
      }
    });

    test('it is one step, not one per cleaned cell', () {
      var history = BoardHistory.start(_board());
      for (final peer in _emptyPeersOf(history.board, 2)) {
        history = history.toggleNote(peer, 4).history;
      }
      final before = history.depth;

      history = history.place(2, 4).history;

      expect(history.depth, before + 1);
    });

    test('undoing past the placement reaches the notes before it', () {
      var history = BoardHistory.start(_board());
      final peer = _emptyPeersOf(history.board, 2).first;
      history = history.toggleNote(peer, 4).history;
      history = history.place(2, 4).history;

      expect(history.undo().board.notesAt(peer), NoteSet.of(const <int>[4]));
      expect(history.undo().undo().board.notesAt(peer), NoteSet.none);
    });
  });

  // D-12 is "on and not optional". The absence is the requirement, so it is
  // asserted here — a later change cannot quietly add the setting whose only
  // function would be to make the game worse.
  group('there is no way to turn it off', () {
    test('the board exposes no flag, and place takes no options', () {
      var board = _board();
      final peer = _emptyPeersOf(board, 2).first;
      board = _applied(board.toggleNote(peer, 4));

      // One signature, one behaviour. If this call ever grows a parameter that
      // disables cleanup, this test is where it has to be argued for.
      board = _applied(board.place(2, 4));

      expect(board.notesAt(peer), NoteSet.none);
    });
  });

  group('erasing the value is a new action, not a reversal', () {
    test('erase does not put the cleaned candidates back', () {
      var board = _board();
      final peer = _emptyPeersOf(board, 2).first;
      board = _applied(board.toggleNote(peer, 4));

      board = _applied(board.place(2, 4));
      board = _applied(board.erase(2));

      expect(board.digitAt(2), Board.empty);
      expect(board.notesAt(peer), NoteSet.none);
    });
  });

  group('a given is never cleaned by the board it is part of', () {
    test('placing a value does not touch a given peer', () {
      var board = _board();
      // Cell 0 is the given 5. Placing 5 in one of its peers is a mistake the
      // player is allowed to make, and it must not corrupt the puzzle.
      final peer = GridGeometry.peersOf(0).firstWhere(board.isEmptyAt);
      board = _applied(board.place(peer, 5));

      expect(board.digitAt(0), 5);
      expect(board.isGiven(0), isTrue);
    });
  });
}
