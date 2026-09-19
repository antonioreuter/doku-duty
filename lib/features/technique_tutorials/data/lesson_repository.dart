import 'package:drift/drift.dart';

import '../../persistence/data/app_database.dart';

/// Which **lesson**s the player has been shown.
///
/// Seen is a fact rather than a count (D-104's shape, applied to a different
/// question): completed, skipped, and replayed four times all read the same,
/// because the only thing anything asks is whether to fire the **lesson**
/// again. A counter here would be a second answer nobody needs and one more
/// thing to keep in step.
final class LessonRepository {
  const LessonRepository(this._db);

  final AppDatabase _db;

  /// Record that [lessonId] has been shown.
  ///
  /// Called when a **lesson** is completed *and* when it is skipped — a
  /// **lesson** that returned after being declined would be nagging rather than
  /// teaching. Idempotent, so a replay or a second skip costs a write and
  /// changes nothing.
  Future<void> markSeen(String lessonId) {
    return _db
        .into(_db.seenLessons)
        .insertOnConflictUpdate(
          SeenLessonsCompanion.insert(
            lessonId: lessonId,
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  Future<bool> hasSeen(String lessonId) async {
    final row = await (_db.select(
      _db.seenLessons,
    )..where((l) => l.lessonId.equals(lessonId))).getSingleOrNull();
    return row != null;
  }

  /// Every **lesson** the player has been shown.
  ///
  /// Empty is the ordinary answer for a new player and for one upgrading from
  /// a database written before this table existed — never an error, and never
  /// read as "all of them", which is the direction that would silently switch
  /// the feature off for every existing install.
  Future<Set<String>> seen() async {
    final rows = await _db.select(_db.seenLessons).get();
    return <String>{for (final row in rows) row.lessonId};
  }
}
