import 'package:drift/drift.dart';

import 'app_database.dart';

/// Reads and writes note state.
///
/// **Every method here writes immediately.** There is no buffer, no debounce, no
/// batch, and nothing that waits for the app to be backgrounded. That is
/// constraint 9, and it is the constraint with no visible symptom when it
/// breaks: a batched write looks identical to a correct one until a player
/// twenty minutes into an expert grid loses the board to an app kill (D-33).
///
/// The writes are single statements, so issuing one costs about as much as the
/// keystroke that caused it. A caller on the input path may start the write and
/// carry on without awaiting it — the note is already on screen, and the future
/// exists for tests and for callers that genuinely need to know (constraint 2).
class NoteRepository {
  const NoteRepository(this._db);

  final AppDatabase _db;

  /// Add or replace one candidate.
  ///
  /// Upsert rather than insert: re-marking a candidate that is already there is
  /// a normal thing for a player to do, and it must not throw at them.
  Future<void> put({
    required String puzzleId,
    required int cell,
    required int digit,
    required NoteKind kind,
    required NoteOrigin origin,
    DateTime? at,
  }) {
    return _db
        .into(_db.notes)
        .insertOnConflictUpdate(
          NotesCompanion.insert(
            puzzleId: puzzleId,
            cell: cell,
            digit: digit,
            kind: kind,
            origin: origin,
            // Stamped on the same statement as the change, so a row cannot be
            // modified without its sync metadata moving with it.
            updatedAt: Value(at ?? DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// Remove one candidate. The other eight in the cell are untouched, because
  /// nothing about them referred to it (constraint 3).
  Future<void> remove({
    required String puzzleId,
    required int cell,
    required int digit,
  }) {
    return (_db.delete(_db.notes)..where(
          (n) =>
              n.puzzleId.equals(puzzleId) &
              n.cell.equals(cell) &
              n.digit.equals(digit),
        ))
        .go();
  }

  /// Clear every **provisional note** on a puzzle in one action (D-11).
  ///
  /// One statement, so the player's single tap is a single write. **Settled
  /// notes** are untouched — that separation is the entire point of the second
  /// ink.
  Future<void> clearProvisional(String puzzleId) {
    return (_db.delete(_db.notes)..where(
          (n) =>
              n.puzzleId.equals(puzzleId) &
              n.kind.equalsValue(NoteKind.provisional),
        ))
        .go();
  }

  /// Every note on a puzzle.
  Future<List<Note>> notesFor(String puzzleId) {
    return (_db.select(
      _db.notes,
    )..where((n) => n.puzzleId.equals(puzzleId))).get();
  }

  /// Every note in one cell.
  Future<List<Note>> notesInCell(String puzzleId, int cell) {
    return (_db.select(
      _db.notes,
    )..where((n) => n.puzzleId.equals(puzzleId) & n.cell.equals(cell))).get();
  }
}
