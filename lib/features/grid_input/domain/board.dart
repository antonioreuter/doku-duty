import '../../puzzle_engine/domain/grid.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';
import 'note_set.dart';

/// Why an edit did not happen.
enum EditRefusal {
  /// The cell holds a given. Givens are the puzzle, not the player's work.
  cellIsGiven,

  /// The edit would leave the board exactly as it is.
  noChange,

  /// The cell holds a value, and a cell holds either a value or notes, never
  /// both (`docs/SPEC.md` §3.2, D-16).
  cellHasValue,
}

/// What one attempt to change the board did.
///
/// A refusal is a value. Nothing a player can do with a finger is an exception,
/// and a control that threw would be a failure state wearing a different hat.
sealed class BoardEdit {
  const BoardEdit(this.board);

  /// The board as it stands after the attempt — unchanged on a refusal.
  final Board board;
}

/// What one edit did to one cell's candidates.
final class NoteChange {
  const NoteChange({required this.before, required this.after});

  final NoteSet before;
  final NoteSet after;

  @override
  bool operator ==(Object other) =>
      other is NoteChange && other.before == before && other.after == after;

  @override
  int get hashCode => Object.hash(before, after);
}

/// The board changed.
final class EditApplied extends BoardEdit {
  const EditApplied({
    required Board board,
    required this.cell,
    required this.before,
    required this.after,
    this.noteChanges = const <int, NoteChange>{},
  }) : super(board);

  final int cell;

  /// What the cell held before, [Board.empty] if it held nothing.
  final int before;

  /// What it holds now, [Board.empty] after an erase.
  final int after;

  /// Every cell whose candidates this edit changed, keyed by cell.
  ///
  /// A map rather than one pair because a single action reaches further than
  /// one cell: **auto-cleanup** strips a placed digit from twenty **peer**s and
  /// **auto-notes** marks up to eighty-one cells, and each is one thing the
  /// player did — so each has to be one thing undo reverses (D-12).
  ///
  /// Carried on value edits too, not only note edits: placing a value clears
  /// that cell's candidates, and undo has to put back what it cleared or the
  /// player silently loses their working out.
  final Map<int, NoteChange> noteChanges;

  /// The candidates [cell] held before. Convenience for the common single-cell
  /// case; [noteChanges] is the whole truth.
  NoteSet get notesBefore => noteChanges[cell]?.before ?? NoteSet.none;

  /// The candidates [cell] holds now.
  NoteSet get notesAfter => noteChanges[cell]?.after ?? NoteSet.none;
}

/// The board did not change, and why.
final class EditRefused extends BoardEdit {
  const EditRefused({required Board board, required this.reason})
    : super(board);

  final EditRefusal reason;
}

/// A puzzle as the player has it: the givens, and the digits they placed.
///
/// Immutable. Every edit returns a new board, which is what makes undo a stack
/// of small facts rather than a pile of snapshots, and what stops a widget
/// holding a board that quietly changes underneath it.
///
/// Nothing here knows whether a digit is *right*. A wrong digit is placed
/// exactly as a right one is, because finding it is the game (D-04,
/// constraint 1); the mistake model is `add-mistake-model`.
final class Board {
  const Board._(this._givens, this._placed, this._notes);

  /// An empty cell.
  static const int empty = Grid.blank;

  /// A fresh board for [givens], with nothing placed.
  factory Board.forPuzzle({required Grid givens}) => Board._(
    givens,
    List<int>.unmodifiable(List<int>.filled(GridGeometry.cellCount, empty)),
    const <int, NoteSet>{},
  );

  /// A board rebuilt from a save.
  ///
  /// A placement that lands on a given is dropped rather than honoured: a save
  /// written before a **pack** refresh must never overwrite the puzzle it
  /// belongs to.
  factory Board.restore({
    required Grid givens,
    required String placedValues,
    Map<int, NoteSet> notes = const <int, NoteSet>{},
  }) {
    final digits = List<int>.filled(GridGeometry.cellCount, empty);
    final parsed = Grid.parse(placedValues);
    if (parsed is ValidGrid) {
      for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
        if (givens.digitAt(cell) != empty) continue;
        digits[cell] = parsed.grid.digitAt(cell);
      }
    }
    // A note on a given, or on a cell the save also gave a value, is dropped
    // rather than honoured: a cell holds one or the other, never both.
    final kept = <int, NoteSet>{
      for (final entry in notes.entries)
        if (givens.digitAt(entry.key) == empty &&
            digits[entry.key] == empty &&
            entry.value.isNotEmpty)
          entry.key: entry.value,
    };
    return Board._(
      givens,
      List<int>.unmodifiable(digits),
      Map<int, NoteSet>.unmodifiable(kept),
    );
  }

  final Grid _givens;
  final List<int> _placed;

  /// Candidates by cell. Absent means none, so an untouched board carries an
  /// empty map rather than eighty-one empty sets.
  final Map<int, NoteSet> _notes;

  bool isGiven(int cell) => _givens.digitAt(cell) != empty;

  /// The digit in [cell], given or placed, or [empty].
  int digitAt(int cell) {
    final given = _givens.digitAt(cell);
    return given != empty ? given : _placed[cell];
  }

  bool isEmptyAt(int cell) => digitAt(cell) == empty;

  /// Cells holding a digit, givens included.
  int get filledCount {
    var count = 0;
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (digitAt(cell) != empty) count++;
    }
    return count;
  }

  /// Cells the player filled.
  int get placedCount => _placed.where((digit) => digit != empty).length;

  /// The candidates in [cell]. A cell holding a value has none.
  NoteSet notesAt(int cell) =>
      digitAt(cell) == empty ? (_notes[cell] ?? NoteSet.none) : NoteSet.none;

  /// Cells carrying at least one candidate.
  int get notedCount => _notes.length;

  /// Mark [digit] in [cell] if it is absent, remove it if it is there.
  BoardEdit toggleNote(int cell, int digit) {
    if (isGiven(cell)) {
      return EditRefused(board: this, reason: EditRefusal.cellIsGiven);
    }
    if (_placed[cell] != empty) {
      return EditRefused(board: this, reason: EditRefusal.cellHasValue);
    }
    final before = _notes[cell] ?? NoteSet.none;
    final after = before.toggle(digit);
    return EditApplied(
      board: Board._(_givens, _placed, _withNotes(cell, after)),
      cell: cell,
      before: empty,
      after: empty,
      noteChanges: <int, NoteChange>{
        cell: NoteChange(before: before, after: after),
      },
    );
  }

  Map<int, NoteSet> _withNotes(int cell, NoteSet notes) {
    final next = Map<int, NoteSet>.of(_notes);
    if (notes.isEmpty) {
      next.remove(cell);
    } else {
      next[cell] = notes;
    }
    return Map<int, NoteSet>.unmodifiable(next);
  }

  /// Put [notes] into [cell] wholesale. Used by undo to restore what a value
  /// placement cleared.
  Board withNotesAt(int cell, NoteSet notes) =>
      Board._(_givens, _placed, _withNotes(cell, notes));

  /// The candidates, by cell, for storage. Cells with none are absent.
  Map<int, NoteSet> toNotes() => _notes;

  /// Put [digit] in [cell].
  BoardEdit place(int cell, int digit) => _edit(cell, digit);

  /// Clear whatever the player put in [cell] — a value or candidates.
  ///
  /// Erase empties a cell whichever of the two it holds. Without this there is
  /// no single action that clears a cell's candidates, and the player would
  /// have to toggle each one off in turn.
  BoardEdit erase(int cell) {
    if (isGiven(cell)) {
      return EditRefused(board: this, reason: EditRefusal.cellIsGiven);
    }
    if (_placed[cell] != empty) return _edit(cell, empty);

    final notes = _notes[cell] ?? NoteSet.none;
    if (notes.isEmpty) {
      return EditRefused(board: this, reason: EditRefusal.noChange);
    }
    return EditApplied(
      board: Board._(_givens, _placed, _withNotes(cell, NoteSet.none)),
      cell: cell,
      before: empty,
      after: empty,
      noteChanges: <int, NoteChange>{
        cell: NoteChange(before: notes, after: NoteSet.none),
      },
    );
  }

  BoardEdit _edit(int cell, int digit) {
    if (isGiven(cell)) {
      return EditRefused(board: this, reason: EditRefusal.cellIsGiven);
    }
    final before = _placed[cell];
    if (before == digit) {
      return EditRefused(board: this, reason: EditRefusal.noChange);
    }
    final placed = List<int>.of(_placed);
    placed[cell] = digit;
    // A value clears the cell's candidates, and the edit carries them so undo
    // can put them back (`docs/SPEC.md` §3.2).
    final notesBefore = _notes[cell] ?? NoteSet.none;
    final notes = Map<int, NoteSet>.of(_notes)..remove(cell);
    final changes = <int, NoteChange>{
      cell: NoteChange(before: notesBefore, after: NoteSet.none),
    };

    // **Auto-cleanup** (D-12). A digit placed here cannot also be a candidate
    // in a cell that shares a **unit** with it, so those candidates go — every
    // one of them, on every placement, with no setting to stop it. Without this
    // the board disagrees with itself within about twenty moves and the player
    // stops trusting their own notes, which kills the feature the technique
    // ladder rests on.
    //
    // Recorded on the same edit rather than applied as a second one: the
    // player did one thing, so undo reverses one thing. Nothing here judges
    // the removal — a candidate is thinking out loud, never a mistake (D-14).
    if (digit != empty) {
      for (final peer in GridGeometry.peersOf(cell)) {
        final peerNotes = notes[peer];
        if (peerNotes == null || !peerNotes.contains(digit)) continue;
        final cleaned = peerNotes.without(digit);
        changes[peer] = NoteChange(before: peerNotes, after: cleaned);
        if (cleaned.isEmpty) {
          notes.remove(peer);
        } else {
          notes[peer] = cleaned;
        }
      }
    }

    return EditApplied(
      board: Board._(
        _givens,
        List<int>.unmodifiable(placed),
        Map<int, NoteSet>.unmodifiable(notes),
      ),
      cell: cell,
      before: before,
      after: digit,
      noteChanges: Map<int, NoteChange>.unmodifiable(changes),
    );
  }

  /// **Auto-notes**: mark every empty cell with each candidate no **peer** of
  /// it already holds as a value.
  ///
  /// **Unions, never replaces** (D-87). A candidate the player marked stays
  /// theirs and stays put, including one the fill would not have offered;
  /// what the fill adds is generated. A legal candidate the player had
  /// eliminated does come back, because "every legal candidate" is what the
  /// action means — and it is one undo step, so trying it costs nothing.
  ///
  /// Legality is asked of the engine's [Grid.candidatesAt] rather than worked
  /// out again here, so there is exactly one definition of it in the codebase.
  /// It reads the board as it stands: a value that contradicts the solution
  /// shapes the fill like any other, and nothing is flagged (D-14).
  ///
  /// One [EditApplied] carrying every cell it touched, so the player's one
  /// action is one thing undo reverses.
  BoardEdit fillNotes() {
    final grid = toGrid();
    final changes = <int, NoteChange>{};
    final notes = Map<int, NoteSet>.of(_notes);

    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (digitAt(cell) != empty) continue;
      final before = _notes[cell] ?? NoteSet.none;
      var after = before;
      for (final digit in grid.candidatesAt(cell).digits) {
        after = after.withGenerated(digit);
      }
      if (after == before) continue;
      changes[cell] = NoteChange(before: before, after: after);
      notes[cell] = after;
    }

    if (changes.isEmpty) {
      return EditRefused(board: this, reason: EditRefusal.noChange);
    }
    return EditApplied(
      board: Board._(_givens, _placed, Map<int, NoteSet>.unmodifiable(notes)),
      // The fill is aimed at the board, not a cell. [EditApplied.cell] names
      // the cell a value moved in, and no value moved.
      cell: changes.keys.first,
      before: empty,
      after: empty,
      noteChanges: Map<int, NoteChange>.unmodifiable(changes),
    );
  }

  /// The whole board, for anything that wants to ask the engine about it.
  Grid toGrid() => Grid.fromDigits(<int>[
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) digitAt(cell),
  ]);

  /// Every cell holds a digit and no **unit** repeats one. The engine answers,
  /// so there is exactly one definition of finished in the codebase.
  bool get isComplete => toGrid().isComplete;

  /// The form `PuzzleSaves.placedValues` stores: eighty-one characters, the
  /// player's placements only, givens as blanks.
  ///
  /// Placements only, deliberately. The givens live on the **pack** row, so a
  /// save cannot contradict the puzzle it belongs to.
  String toPlacedValues() {
    final buffer = StringBuffer();
    for (final digit in _placed) {
      buffer.write(digit == empty ? Grid.blankCharacter : '$digit');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Board || other._givens != _givens) return false;
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (other._placed[cell] != _placed[cell]) return false;
    }
    if (other._notes.length != _notes.length) return false;
    for (final entry in _notes.entries) {
      if (other._notes[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    _givens,
    Object.hashAll(_placed),
    Object.hashAllUnordered(
      _notes.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
