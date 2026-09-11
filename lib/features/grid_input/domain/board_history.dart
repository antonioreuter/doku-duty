import 'board.dart';

/// A board and the edits that got it there, with what the last attempt did.
///
/// Returned rather than mutated so a caller can react to a refusal — a haptic,
/// or nothing at all — without asking the history what just happened.
final class HistoryStep {
  const HistoryStep({required this.history, required this.edit});

  final BoardHistory history;

  /// What the attempt did. [EditRefused] means the history is unchanged.
  final BoardEdit edit;
}

/// The board, and every edit made to it since the puzzle was opened.
///
/// **Session-deep, on purpose.** The board is written to the database on every
/// change and survives an app kill; this history does not. Reopening a puzzle
/// gives the player the board they left, not the moves they made — persisting
/// the stack would mean a schema migration for a history nobody asked to keep,
/// and `add-notes` would rewrite its shape immediately.
///
/// Full depth within the session, with no cap. A cap is a small failure state,
/// and it always bites the player who was exploring hardest.
final class BoardHistory {
  const BoardHistory._(this.board, this._past);

  factory BoardHistory.start(Board board) =>
      BoardHistory._(board, const <EditApplied>[]);

  final Board board;

  /// Applied edits, oldest first. Refusals never enter it, so undo can only
  /// reverse a move the player actually made.
  final List<EditApplied> _past;

  bool get canUndo => _past.isNotEmpty;

  /// How many edits are on the stack. Undo this many times to reach the start.
  int get depth => _past.length;

  HistoryStep place(int cell, int digit) => _step(board.place(cell, digit));

  HistoryStep erase(int cell) => _step(board.erase(cell));

  /// Mark [digit] in [cell] if it is absent, remove it if it is there.
  HistoryStep toggleNote(int cell, int digit) =>
      _step(board.toggleNote(cell, digit));

  /// **Auto-notes**: mark every empty cell with its legal candidates, as one
  /// step on the stack.
  HistoryStep fillNotes() => _step(board.fillNotes());

  HistoryStep _step(BoardEdit edit) {
    if (edit is! EditApplied) {
      return HistoryStep(history: this, edit: edit);
    }
    return HistoryStep(
      history: BoardHistory._(edit.board, <EditApplied>[..._past, edit]),
      edit: edit,
    );
  }

  /// Reverse the last edit, or do nothing when there is none.
  ///
  /// Doing nothing is the whole answer: an undo with an empty stack is an
  /// ordinary thing for a player to try, not an error to report at them.
  BoardHistory undo() {
    if (_past.isEmpty) return this;
    final last = _past.last;

    // Written straight back rather than replayed: the edit already records what
    // every cell held, and replaying would re-run rules that have since changed
    // what they do — including **auto-cleanup**, which would strip the very
    // candidates this is putting back.
    //
    // The value goes back first, then the candidates. Order matters: a board
    // refuses notes on a cell holding a value, so restoring the candidates of a
    // cell whose value is being cleared has to happen after the clearing.
    final restored = last.before == Board.empty
        ? board.erase(last.cell)
        : board.place(last.cell, last.before);
    var next = restored is EditApplied ? restored.board : board;
    // Every cell the edit touched, not only the one it was aimed at. A
    // placement clears its own cell's candidates and **auto-cleanup** strips
    // them from twenty **peer**s; a fill marks eighty-one. One action, one
    // undo — anything less loses the player's working out silently.
    for (final entry in last.noteChanges.entries) {
      next = next.withNotesAt(entry.key, entry.value.before);
    }

    return BoardHistory._(
      next,
      List<EditApplied>.unmodifiable(_past.take(_past.length - 1)),
    );
  }
}
