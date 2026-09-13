import 'package:test/test.dart';

import 'package:doku_duty/features/grid_input/domain/board.dart';
import 'package:doku_duty/features/grid_input/domain/board_history.dart';
import 'package:doku_duty/features/grid_input/domain/note_set.dart';
import 'package:doku_duty/features/persistence/domain/note_enums.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid.dart';
import 'package:doku_duty/features/puzzle_engine/domain/grid_geometry.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

Board _board() =>
    Board.forPuzzle(givens: (Grid.parse(_clues) as ValidGrid).grid);

Board _applied(BoardEdit edit) => (edit as EditApplied).board;

void main() {
  group('the fill marks every legal candidate in every empty cell', () {
    test('an untouched board gains its whole candidate grid', () {
      final board = _applied(_board().fillNotes());

      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        if (!board.isEmptyAt(cell)) continue;
        expect(
          board.notesAt(cell).digits,
          board.toGrid().candidatesAt(cell).digits,
          reason: 'cell $cell disagrees with the engine about what is legal',
        );
      }
    });

    test('a digit a peer already holds is not marked', () {
      final board = _applied(_board().fillNotes());

      // Cell 2 sits in row 0, which the clues open with 5 and 3.
      expect(board.notesAt(2).contains(5), isFalse);
      expect(board.notesAt(2).contains(3), isFalse);
    });

    test('no given gains candidates', () {
      final board = _applied(_board().fillNotes());

      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        if (!board.isGiven(cell)) continue;
        expect(board.notesAt(cell), NoteSet.none, reason: 'given at $cell');
      }
    });

    test('no cell holding a placed value gains candidates (D-16)', () {
      var board = _applied(_board().place(2, 4));
      board = _applied(board.fillNotes());

      expect(board.digitAt(2), 4);
      expect(board.notesAt(2), NoteSet.none);
    });

    test('everything it marks is its own work', () {
      final board = _applied(_board().fillNotes());

      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        expect(board.notesAt(cell).manual, isEmpty, reason: 'cell $cell');
      }
    });
  });

  // D-87. The fill adds what is missing and never takes over what is there.
  group('the fill unions rather than replaces', () {
    test('a hand-marked candidate survives and stays the player\'s', () {
      var board = _applied(_board().toggleNote(2, 4));
      board = _applied(board.fillNotes());

      expect(board.notesAt(2).contains(4), isTrue);
      expect(board.notesAt(2).isGenerated(4), isFalse);
    });

    test('the cell still gains the legal candidates it was missing', () {
      var board = _applied(_board().toggleNote(2, 4));
      board = _applied(board.fillNotes());

      expect(board.notesAt(2).digits, board.toGrid().candidatesAt(2).digits);
      expect(board.notesAt(2).generated, isNotEmpty);
    });

    test('a candidate the player had eliminated comes back', () {
      var board = _applied(_board().toggleNote(2, 4));
      board = _applied(board.toggleNote(2, 4)); // eliminated it again
      expect(board.notesAt(2), NoteSet.none);

      board = _applied(board.fillNotes());

      // "Every legal candidate" is what the action means, and one undo makes
      // it free to try.
      expect(board.notesAt(2).contains(4), isTrue);
      expect(board.notesAt(2).isGenerated(4), isTrue);
    });

    test('a hand-marked candidate that is not legal is left alone', () {
      // 5 is in cell 2's row already, so the fill would never mark it.
      var board = _applied(_board().toggleNote(2, 5));
      board = _applied(board.fillNotes());

      expect(board.notesAt(2).contains(5), isTrue);
      expect(board.notesAt(2).isGenerated(5), isFalse);
    });
  });

  group('the fill is one action', () {
    test('undo reverses the whole thing in one step', () {
      var history = BoardHistory.start(_board());
      final before = history.depth;

      history = history.fillNotes().history;
      expect(history.depth, before + 1);
      expect(history.board.notedCount, greaterThan(0));

      expect(history.undo().board.notedCount, 0);
    });

    test('undo leaves every hand-marked candidate exactly as it was', () {
      var history = BoardHistory.start(_board());
      history = history.toggleNote(2, 4).history;
      history = history.toggleNote(11, 9).history;

      history = history.fillNotes().history;
      final undone = history.undo();

      expect(undone.board.notesAt(2), NoteSet.of(const <int>[4]));
      expect(undone.board.notesAt(11), NoteSet.of(const <int>[9]));
      expect(undone.board.notedCount, 2);
    });

    test('a second undo reaches the action before the fill', () {
      var history = BoardHistory.start(_board());
      history = history.toggleNote(2, 4).history;
      history = history.fillNotes().history;

      expect(history.undo().undo().board.notesAt(2), NoteSet.none);
    });

    test('the edit records every cell it marked', () {
      final edit = _board().fillNotes() as EditApplied;

      final emptyCells = <int>[
        for (var cell = 0; cell < GridGeometry.cellCount; cell++)
          if (edit.board.isEmptyAt(cell)) cell,
      ];
      expect(edit.noteChanges.keys.toSet(), emptyCells.toSet());
    });

    test('a fill that changes nothing is refused, not pushed', () {
      var board = _applied(_board().fillNotes());
      // Everything legal is already marked, so there is nothing to add.
      expect(board.fillNotes(), isA<EditRefused>());

      var history = BoardHistory.start(board);
      final depth = history.depth;
      history = history.fillNotes().history;
      expect(history.depth, depth);
    });
  });

  // Constraint 1 and D-14. The fill reads the board as it stands and says
  // nothing about whether the board is right.
  group('the fill judges nothing', () {
    test('a value that contradicts the solution still shapes the fill', () {
      // Cell 2's answer is 4. Place 1 instead; the fill must honour the 1.
      var board = _applied(_board().place(2, 1));
      board = _applied(board.fillNotes());

      for (final peer in GridGeometry.peersOf(2)) {
        if (!board.isEmptyAt(peer)) continue;
        expect(
          board.notesAt(peer).contains(1),
          isFalse,
          reason: 'cell $peer was offered a 1 that cell 2 already holds',
        );
      }
    });

    test('nothing is flagged, counted, or refused for being wrong', () {
      var board = _applied(_board().place(2, 1));
      final edit = board.fillNotes();

      expect(edit, isA<EditApplied>());
    });
  });

  group('the fill costs nothing', () {
    test('it takes no charge, balance, or entitlement to run', () {
      // One signature, no meter. Metering is `add-perks` (change 19), and the
      // absence is asserted here so it cannot arrive by accident.
      final edit = _board().fillNotes();
      expect(edit, isA<EditApplied>());
    });
  });

  // A fill states what is legal; it never states what the player is testing.
  group('the fill and the second ink', () {
    test('a hypothesis is left a hypothesis', () {
      var board = _board();
      board = _applied(board.toggleNote(2, 1, ink: NoteKind.provisional));
      board = _applied(board.toggleNote(2, 4));

      final filled = _applied(board.fillNotes());

      expect(filled.notesAt(2).provisional, <int>[1]);
      expect(filled.notesAt(2).settled, contains(4));
      expect(
        filled.notesAt(2).length,
        greaterThan(2),
        reason: 'the fill still added the candidates that were missing',
      );
    });

    test('nothing the fill adds is provisional', () {
      var board = _board();
      board = _applied(board.toggleNote(40, 3, ink: NoteKind.provisional));

      final filled = _applied(board.fillNotes());

      for (var cell = 0; cell < 81; cell++) {
        for (final digit in filled.notesAt(cell).provisional) {
          expect(
            (cell, digit),
            (40, 3),
            reason: 'the fill wrote the second ink in cell $cell',
          );
        }
      }
    });

    test('a generated candidate re-inked by hand stays generated', () {
      // D-15 and D-90 are separate questions: which of the two first marked
      // it, and which ink it now carries.
      var board = _applied(_board().fillNotes());
      final digit = board.notesAt(2).digits.first;
      expect(board.notesAt(2).isGenerated(digit), isTrue);

      board = _applied(board.toggleNote(2, digit, ink: NoteKind.provisional));

      expect(board.notesAt(2).isProvisional(digit), isTrue);
      expect(board.notesAt(2).isGenerated(digit), isTrue);
    });

    test('the fill does not re-ink what it finds', () {
      var board = _board();
      board = _applied(board.toggleNote(11, 2, ink: NoteKind.provisional));
      final before = board.notesAt(11);

      final filled = _applied(board.fillNotes());

      expect(filled.notesAt(11).provisional, before.provisional);
    });
  });
}
