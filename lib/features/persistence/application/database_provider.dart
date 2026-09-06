import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../platform_shell/application/crash_reporting.dart';
import '../data/app_database.dart';
import '../data/database_opener.dart';

/// The local database, opened on first read.
///
/// Lazy is load-bearing, not incidental. Riverpod builds a provider the first
/// time something reads it, so as long as nothing on the first-frame path
/// watches this, opening the file — and creating it on a fresh install — happens
/// after the app is already on screen. The shell's 2-second cold-start budget
/// has no slack budgeted for a database.
///
/// A test asserts the shell does not read it. That test is the guarantee; this
/// comment is only the reason.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});

/// Opens the database, recovering from one that cannot be read.
///
/// Async, and deliberately not on the first-frame path: the app renders, then
/// this resolves. A corrupt file costs the saved game and nothing else — the
/// player is shown no dialog, because a failure state is exactly what this
/// product does not have (D-03).
final openedDatabaseProvider = FutureProvider<OpenedDatabase>((ref) async {
  final opened = await openDatabase(
    open: AppDatabase.open,
    discard: _deleteDatabaseFile,
    report: (error, stack) {
      // ignore: discarded_futures
      reportHandled(error, stack);
    },
  );
  ref.onDispose(opened.database.close);
  return opened;
});

/// Removes the database file so a fresh one can be created in its place.
Future<void> _deleteDatabaseFile() async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'doku_duty.sqlite'));
  if (file.existsSync()) file.deleteSync();
}
