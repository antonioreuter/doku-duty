import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/database_opener.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('doku_open_test');
    file = File(p.join(dir.path, 'app.sqlite'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<OpenedDatabase> open() => openDatabase(
    open: () => AppDatabase(NativeDatabase(file)),
    discard: () async {
      if (file.existsSync()) file.deleteSync();
    },
    report: (_, _) {},
  );

  group('a healthy database', () {
    test('opens and reports no reset', () async {
      final opened = await open();
      addTearDown(opened.database.close);
      expect(opened.wasReset, isFalse);
    });

    test('keeps what was already saved', () async {
      final first = await open();
      await PuzzleSaveRepository(first.database).save(
        puzzleId: 'p1',
        placedValues: <int, int>{0: 5},
        elapsed: const Duration(minutes: 2),
      );
      await first.database.close();

      final second = await open();
      addTearDown(second.database.close);
      expect(second.wasReset, isFalse);
      expect(
        (await PuzzleSaveRepository(second.database).inProgress())?.puzzleId,
        'p1',
      );
    });
  });

  group('a corrupt database', () {
    test('starts empty and stays playable', () async {
      file.writeAsBytesSync(List<int>.filled(4096, 0x41)); // not a database

      final opened = await open();
      addTearDown(opened.database.close);

      expect(opened.wasReset, isTrue);
      // Playable means writable, not merely open.
      await PuzzleSaveRepository(opened.database).save(
        puzzleId: 'fresh',
        placedValues: const <int, int>{},
        elapsed: Duration.zero,
      );
      expect(
        (await PuzzleSaveRepository(opened.database).inProgress())?.puzzleId,
        'fresh',
      );
    });

    test('offers no stale puzzle to resume', () async {
      file.writeAsBytesSync(List<int>.filled(4096, 0x41));

      final opened = await open();
      addTearDown(opened.database.close);
      expect(await PuzzleSaveRepository(opened.database).inProgress(), isNull);
    });

    test('the failure is reported, and the player is shown nothing', () async {
      file.writeAsBytesSync(List<int>.filled(4096, 0x41));

      final reported = <Object>[];
      final opened = await openDatabase(
        open: () => AppDatabase(NativeDatabase(file)),
        discard: () async => file.deleteSync(),
        report: (error, _) => reported.add(error),
      );
      addTearDown(opened.database.close);

      expect(
        reported,
        hasLength(1),
        reason: 'a reset is diagnosable or it is invisible',
      );
      // Nothing in this layer can show a dialog — it has no widgets at all.
      expect(opened.wasReset, isTrue);
    });
  });

  group('a failed migration', () {
    test(
      'takes the same path rather than leaving the app unable to start',
      () async {
        // A database claiming a schema version from the future is what a
        // downgrade looks like, and drift cannot migrate backwards.
        final db = AppDatabase(NativeDatabase(file));
        await db.customStatement('PRAGMA user_version = 9999');
        await db.close();

        final opened = await open();
        addTearDown(opened.database.close);

        expect(opened.wasReset, isTrue);
        await PuzzleSaveRepository(opened.database).save(
          puzzleId: 'after-failure',
          placedValues: const <int, int>{},
          elapsed: Duration.zero,
        );
        expect(
          (await PuzzleSaveRepository(opened.database).inProgress())?.puzzleId,
          'after-failure',
        );
      },
    );
  });
}
