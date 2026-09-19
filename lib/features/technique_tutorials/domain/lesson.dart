import '../../puzzle_engine/domain/rank.dart';
import '../../puzzle_engine/domain/technique.dart';

/// One step of a **lesson**: what to read, and what to look at while reading it.
final class LessonStep {
  const LessonStep({required this.text, this.cells = const <int>[]});

  /// One sentence. The player is mid-puzzle and reading is not why they opened
  /// the app.
  final String text;

  /// The cells this step is about, marked while it is on screen. May be empty
  /// for a step that talks about the grid as a whole.
  final List<int> cells;
}

/// The placement the player makes to finish a **lesson**.
final class LessonPlacement {
  const LessonPlacement({required this.cell, required this.digit});

  final int cell;
  final int digit;
}

/// A short guided walkthrough teaching one technique.
///
/// Content, not mechanism: a fixed grid, an ordered list of steps, and the one
/// placement the player makes at the end. Nothing here reads the player's own
/// puzzle, and nothing it does can reach one.
final class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.technique,
    required this.steps,
    required this.grid,
    required this.placement,
  });

  /// Stable, and stored: this is the key in the seen table, so renaming one
  /// makes every player who saw it see it again.
  final String id;

  final String title;

  /// The technique this teaches, or null for the **notes lesson** — which
  /// teaches a tool rather than a technique, and so can never be suppressed by
  /// a **technique unlock** (D-104).
  final Technique? technique;

  final List<LessonStep> steps;

  /// Eighty-one characters, `.` for empty, like every other grid in the app.
  final String grid;

  final LessonPlacement placement;

  /// Where this **lesson** sits on the ladder, for choosing the hardest due one
  /// (D-106). The **notes lesson** sits at the **rank** it is owed by.
  Rank get introducedAt => technique?.introducedAt ?? notesRank;

  /// The **rank** by which notes must have been taught.
  ///
  /// Sheriff, one full **rank** before Marshal, where notes stop being optional
  /// (`docs/SPEC.md` §4).
  static const Rank notesRank = Rank.sheriff;

  /// The one **lesson** that teaches notes rather than a technique.
  ///
  /// Its grid is the same real position the naked pair **lesson** uses, which
  /// is deliberate: notes are the tool that makes a naked pair visible, and
  /// meeting the board twice means the second lesson is already familiar.
  ///
  /// It teaches the three things about notes a player cannot work out by
  /// pressing buttons: that a note is a candidate rather than an answer, that
  /// the nine slots never move (constraint 3), and that a note is never a
  /// **mistake** (D-09, D-10, D-14).
  static const Lesson notes = Lesson(
    id: 'notes',
    title: 'Notes',
    technique: null,
    grid:
        '7614.....835719.62942.....7.....6.896..8..17..87.91.452.8.....4..........1.5..8.6',
    steps: <LessonStep>[
      LessonStep(
        text:
            'A note is a digit you are still considering for a cell, not an '
            'answer you are giving.',
        cells: <int>[30, 33],
      ),
      LessonStep(
        text:
            'Each note keeps its own slot — 1 top-left, 5 centre, 9 '
            'bottom-right — so removing one never moves the others.',
        cells: <int>[30, 33],
      ),
      LessonStep(
        text:
            'Notes are never counted against you. A wrong note costs '
            'nothing, so mark freely.',
        cells: <int>[],
      ),
      LessonStep(
        text:
            'Marked up like this, the cell has only one digit left. Place '
            'the 5.',
        cells: <int>[28],
      ),
    ],
    placement: LessonPlacement(cell: 28, digit: 5),
  );
}
