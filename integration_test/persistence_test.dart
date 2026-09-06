import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';

/// The half of constraint 9 a host test cannot reach.
///
/// Host tests prove the write lands in *a* sqlite file. These prove it lands in
/// the right place on a real OS, through the sqlite the app actually bundles,
/// and that it is still there in a new process.
///
/// Run twice. The first run writes; the second asserts what the first left
/// behind, which is the only honest way to test surviving process death — the
/// process that died has to be a real one.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const puzzleId = 'integration-probe';

  testWidgets('the database lives in the application-support directory', (
    tester,
  ) async {
    final db = AppDatabase.open();
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get();

    final directory = await getApplicationSupportDirectory();
    expect(directory.existsSync(), isTrue);
    // drift_flutter names the file after the database.
    final entries = directory
        .listSync()
        .map((e) => e.path.split('/').last)
        .toList();
    expect(
      entries.any((name) => name.startsWith('doku_duty')),
      isTrue,
      reason:
          'expected a doku_duty database in ${directory.path}, '
          'found $entries',
    );
  });

  testWidgets('a write reaches disk and survives reopening', (tester) async {
    final writer = AppDatabase.open();
    await NoteRepository(writer).put(
      puzzleId: puzzleId,
      cell: 40,
      digit: 7,
      kind: NoteKind.provisional,
      origin: NoteOrigin.manual,
    );
    await PuzzleSaveRepository(writer).save(
      puzzleId: puzzleId,
      placedValues: <int, int>{0: 5, 80: 9},
      elapsed: const Duration(minutes: 7),
    );
    await writer.close();

    final reader = AppDatabase.open();
    addTearDown(reader.close);
    final notes = await NoteRepository(reader).notesFor(puzzleId);
    expect(notes, hasLength(1));
    expect(notes.single.digit, 7);
    expect(notes.single.kind, NoteKind.provisional);

    final save = await PuzzleSaveRepository(reader).inProgress();
    expect(save?.puzzleId, puzzleId);
    expect(save?.placedValues, <int, int>{0: 5, 80: 9});
    expect(save?.elapsed, const Duration(minutes: 7));
  });

  testWidgets('what a previous process wrote is still here', (tester) async {
    // Meaningful on the second run, after the app has been killed between them.
    // On the first run this passes trivially, which is why the run order is
    // part of the check rather than incidental to it.
    final db = AppDatabase.open();
    addTearDown(db.close);
    final notes = await NoteRepository(db).notesFor(puzzleId);
    expect(
      notes,
      hasLength(1),
      reason: 'the note written by an earlier process is gone',
    );
    expect(notes.single.digit, 7);
  });
}
