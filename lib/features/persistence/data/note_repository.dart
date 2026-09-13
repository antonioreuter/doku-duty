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
/// One stored candidate: the ink it is written in and who marked it.
///
/// The two travel together because they are two facts about the same row, and
/// a write that carried only one of them would have to guess the other (D-15).
typedef NoteMark = ({NoteKind kind, NoteOrigin origin});

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

  /// Write several cells' candidates in one commit.
  ///
  /// For an action that reaches many cells: **auto-cleanup** strips a placed
  /// digit from twenty **peer**s, **auto-notes** marks up to eighty-one. Each
  /// [cells] entry replaces that cell's candidates wholesale — a digit absent
  /// from the set has its row deleted, and one whose [NoteMark] changed has its
  /// row rewritten, which is how a re-inking reaches the store at all.
  ///
  /// **A transaction is not the batching constraint 9 forbids.** What that
  /// constraint rules out is *deferral*: a buffer, a debounce, a flush on
  /// backgrounding — anything that lets the app stop between the change and the
  /// write. This commits with the action, in the same call, and its only effect
  /// is that a kill part-way through leaves the board as it was rather than
  /// half filled. Writing the cells one at a time would be strictly worse for
  /// the same constraint, not better.
  Future<void> putCells({
    required String puzzleId,
    required Map<int, Map<int, NoteMark>> cells,
    DateTime? at,
  }) {
    final stamp = at ?? DateTime.now();
    return _db.transaction(() async {
      for (final cell in cells.entries) {
        for (var digit = 1; digit <= 9; digit++) {
          final mark = cell.value[digit];
          if (mark == null) {
            await remove(puzzleId: puzzleId, cell: cell.key, digit: digit);
          } else {
            await put(
              puzzleId: puzzleId,
              cell: cell.key,
              digit: digit,
              kind: mark.kind,
              origin: mark.origin,
              at: stamp,
            );
          }
        }
      }
    });
  }

  // `clearProvisional` stood here from `add-persistence-layer` until
  // `add-provisional-notes`, which is the change that finally had a caller for
  // it — and found it could not have one. It deleted every provisional row in
  // one statement, which is cheaper than [putCells] and wrong for this app:
  //
  // - Every note write derives from a diff of the board before and after
  //   (`PuzzleController._persist`), because undo restores candidates with no
  //   edit describing them. A clearance routed through a direct delete would
  //   still be followed by that diff, so the action would be written twice.
  // - Nothing reverses a delete statement. Undo puts the cleared candidates
  //   back on the board, and only the diff path carries them to the store.
  //
  // D-11's one-action clear is unchanged; it goes through [putCells] with
  // every other multi-cell action. Do not reintroduce a second write path into
  // note rows — two paths into one table is how they come to disagree.

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
