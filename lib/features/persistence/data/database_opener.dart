import 'dart:async';

import 'app_database.dart';

/// The result of opening storage, including whether anything was lost.
class OpenedDatabase {
  const OpenedDatabase({required this.database, required this.wasReset});

  final AppDatabase database;

  /// True when the existing file could not be used and an empty one replaced
  /// it. Nothing shows this to the player; it exists so the app knows not to
  /// offer a resume that no longer exists, and so the failure is reportable.
  final bool wasReset;
}

/// Opens the database, and never lets a bad one stop the app.
///
/// Constraint 1 has no exception for infrastructure. A corrupt file, a failed
/// migration, or a disk that will not cooperate is a lost saved game — which is
/// genuinely bad — but a player staring at an error screen instead of a puzzle
/// is worse, and it is a failure state in a product that has none (D-03).
///
/// So: try the file, and if it cannot be used, start empty and carry on.
Future<OpenedDatabase> openDatabase({
  required AppDatabase Function() open,
  required Future<void> Function() discard,
  required void Function(Object error, StackTrace stack) report,
}) async {
  try {
    final database = open();
    // Force the connection and any migration to actually run. Constructing the
    // object proves nothing — drift opens lazily, so a corrupt file would not
    // be noticed until the first read, which is somewhere far less able to
    // recover from it.
    await database.customSelect('SELECT 1').get();
    return OpenedDatabase(database: database, wasReset: false);
  } on Object catch (error, stack) {
    // Reported, not shown. The crash reporter the shell already installed is
    // where this belongs; the player is told nothing, because there is nothing
    // they can usefully do.
    report(error, stack);

    await discard();
    final database = open();
    await database.customSelect('SELECT 1').get();
    return OpenedDatabase(database: database, wasReset: true);
  }
}
