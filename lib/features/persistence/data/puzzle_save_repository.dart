import 'package:drift/drift.dart';

import 'app_database.dart';

/// A puzzle in progress, as the game reads it.
class ResumableSave {
  const ResumableSave({
    required this.puzzleId,
    required this.placedValues,
    required this.elapsed,
  });

  final String puzzleId;

  /// Cell index to placed digit. Absent means empty.
  final Map<int, int> placedValues;

  final Duration elapsed;
}

/// Reads and writes the state of a puzzle in progress.
///
/// The reason this exists is the app kill. A player twenty minutes into an
/// expert grid does not get a warning before the OS reclaims the process, so
/// every write here lands immediately, on the same terms as note state (D-33).
class PuzzleSaveRepository {
  const PuzzleSaveRepository(this._db);

  static const String _emptyCell = '.';

  final AppDatabase _db;

  /// Write the whole save.
  Future<void> save({
    required String puzzleId,
    required Map<int, int> placedValues,
    required Duration elapsed,
    DateTime? at,
  }) {
    return _db
        .into(_db.puzzleSaves)
        .insertOnConflictUpdate(
          PuzzleSavesCompanion.insert(
            puzzleId: puzzleId,
            placedValues: _encode(placedValues),
            elapsedMs: Value(elapsed.inMilliseconds),
            updatedAt: Value(at ?? DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// Place one value, and clear that cell's notes in the same action.
  ///
  /// The two happen together because D-16 relies on a cell never holding both:
  /// a completed grid has no notes by construction, which is why there is no
  /// "you still have notes" check to strand a player on a solved puzzle.
  Future<void> placeValue({
    required String puzzleId,
    required int cell,
    required int value,
  }) {
    return _db.transaction(() async {
      final current = await _row(puzzleId);
      final grid = _decode(current?.placedValues);
      grid[cell] = value;
      await save(
        puzzleId: puzzleId,
        placedValues: grid,
        elapsed: Duration(milliseconds: current?.elapsedMs ?? 0),
      );
      await (_db.delete(
        _db.notes,
      )..where((n) => n.puzzleId.equals(puzzleId) & n.cell.equals(cell))).go();
    });
  }

  /// Clear one cell. The cell ends up holding neither a value nor notes.
  Future<void> clearValue({required String puzzleId, required int cell}) {
    return _db.transaction(() async {
      final current = await _row(puzzleId);
      final grid = _decode(current?.placedValues)..remove(cell);
      await save(
        puzzleId: puzzleId,
        placedValues: grid,
        elapsed: Duration(milliseconds: current?.elapsedMs ?? 0),
      );
      await (_db.delete(
        _db.notes,
      )..where((n) => n.puzzleId.equals(puzzleId) & n.cell.equals(cell))).go();
    });
  }

  /// The puzzle to offer for resume, if any.
  Future<ResumableSave?> inProgress() async {
    final row =
        await (_db.select(_db.puzzleSaves)
              ..where((s) => s.isComplete.equals(false))
              ..orderBy(<OrderingTerm Function($PuzzleSavesTable)>[
                (s) => OrderingTerm(
                  expression: s.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toSave(row);
  }

  Future<List<ResumableSave>> all() async {
    final rows = await _db.select(_db.puzzleSaves).get();
    return rows.map(_toSave).toList();
  }

  /// Mark a puzzle finished.
  ///
  /// Its notes go with it: they described a grid that no longer has unknowns,
  /// and keeping them would offer a resume that has nothing to resume.
  Future<void> complete(String puzzleId) {
    return _db.transaction(() async {
      await (_db.update(
        _db.puzzleSaves,
      )..where((s) => s.puzzleId.equals(puzzleId))).write(
        PuzzleSavesCompanion(
          isComplete: const Value(true),
          updatedAt: Value(DateTime.now()),
          pendingUpload: const Value(true),
        ),
      );
      await (_db.delete(
        _db.notes,
      )..where((n) => n.puzzleId.equals(puzzleId))).go();
    });
  }

  Future<PuzzleSave?> _row(String puzzleId) => (_db.select(
    _db.puzzleSaves,
  )..where((s) => s.puzzleId.equals(puzzleId))).getSingleOrNull();

  ResumableSave _toSave(PuzzleSave row) => ResumableSave(
    puzzleId: row.puzzleId,
    placedValues: _decode(row.placedValues),
    elapsed: Duration(milliseconds: row.elapsedMs),
  );

  static String _encode(Map<int, int> values) {
    final buffer = List<String>.filled(81, _emptyCell);
    for (final entry in values.entries) {
      buffer[entry.key] = entry.value.toString();
    }
    return buffer.join();
  }

  static Map<int, int> _decode(String? encoded) {
    if (encoded == null) return <int, int>{};
    final values = <int, int>{};
    for (var cell = 0; cell < encoded.length; cell++) {
      final char = encoded[cell];
      if (char != _emptyCell) values[cell] = int.parse(char);
    }
    return values;
  }
}
