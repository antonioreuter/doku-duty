import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/note_repository.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/puzzle_save_repository.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';
import 'package:doku_duty/features/persistence/domain/sync_metadata.dart';

import 'support/fixture_pack.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the schema carries what sync will need', () {
    test('every syncable table has a stamp and a pending flag', () async {
      for (final table in syncableTables) {
        final columns = await db
            .customSelect('PRAGMA table_info($table)')
            .map((row) => row.read<String>('name'))
            .get();
        expect(columns, contains('updated_at'), reason: table);
        expect(columns, contains('pending_upload'), reason: table);
      }
    });

    test('a save records the device it came from', () async {
      final columns = await db
          .customSelect('PRAGMA table_info(puzzle_saves)')
          .map((row) => row.read<String>('name'))
          .get();
      expect(columns, contains('device_origin'));
    });

    test(
      'the syncable list matches the tables that actually have the columns',
      () async {
        final all = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' "
              "AND name NOT LIKE 'sqlite_%'",
            )
            .map((row) => row.read<String>('name'))
            .get();

        for (final table in all) {
          final columns = await db
              .customSelect('PRAGMA table_info($table)')
              .map((row) => row.read<String>('name'))
              .get();
          final hasMetadata =
              columns.contains('updated_at') &&
              columns.contains('pending_upload');
          expect(
            hasMetadata,
            syncableTables.contains(table),
            reason:
                '$table disagrees with the syncable list — either it gained '
                'sync columns without being listed, or it lost them',
          );
        }
      },
    );
  });

  group('writing a row maintains the metadata', () {
    test('a note write stamps and marks it pending', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await NoteRepository(db).put(
        puzzleId: 'p1',
        cell: 0,
        digit: 1,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
      );

      final row = await db.select(db.notes).getSingle();
      expect(row.pendingUpload, isTrue);
      expect(row.updatedAt.isAfter(before), isTrue);
    });

    test('a stamp moves when the row is modified', () async {
      final notes = NoteRepository(db);
      await notes.put(
        puzzleId: 'p1',
        cell: 0,
        digit: 1,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
        at: DateTime.utc(2020),
      );
      expect(
        (await db.select(db.notes).getSingle()).updatedAt.isAtSameMomentAs(
          DateTime.utc(2020),
        ),
        isTrue,
      );

      await notes.put(
        puzzleId: 'p1',
        cell: 0,
        digit: 1,
        kind: NoteKind.provisional,
        origin: NoteOrigin.manual,
        at: DateTime.utc(2021),
      );
      expect(
        (await db.select(db.notes).getSingle()).updatedAt.isAtSameMomentAs(
          DateTime.utc(2021),
        ),
        isTrue,
      );
    });

    test('a save, a solve, a statistic and a setting all stamp', () async {
      await PuzzleSaveRepository(db).save(
        puzzleId: 'p1',
        placedValues: const <int, int>{},
        elapsed: Duration.zero,
      );
      await installFixturePack(PackRepository(db));
      await PackRepository(db).markSolved('fixture-deputy');
      await StatisticsRepository(db).recordSolve(
        techniquesRequired: <Technique>{Technique.hiddenSingle},
        timeTaken: const Duration(minutes: 1),
        attempt: Attempt.fresh,
      );
      await SettingsRepository(db).write(AppSetting.reduceEffects, value: true);

      expect(
        (await db.select(db.puzzleSaves).getSingle()).pendingUpload,
        isTrue,
      );
      expect(
        (await db.select(db.solvedPuzzles).getSingle()).pendingUpload,
        isTrue,
      );
      expect(
        (await db.select(db.lifetimeStats).getSingle()).pendingUpload,
        isTrue,
      );
      expect((await db.select(db.settings).getSingle()).pendingUpload, isTrue);
    });
  });

  group('stamps are comparable across devices', () {
    // D-76. Sync is last-write-wins, so the only thing that matters about a
    // stamp is that two devices order two writes the same way.
    test(
      'an instant survives the round trip whatever the local zone is',
      () async {
        final instant = DateTime.utc(2026, 9, 5, 12, 34, 56, 789);
        await NoteRepository(db).put(
          puzzleId: 'p1',
          cell: 0,
          digit: 1,
          kind: NoteKind.settled,
          origin: NoteOrigin.manual,
          at: instant,
        );

        final stored = (await db.select(db.notes).getSingle()).updatedAt;
        expect(stored.isAtSameMomentAs(instant), isTrue);
      },
    );

    test('two writes in the same second are still ordered', () async {
      // Unix-second storage would collapse these into one value, and
      // last-write-wins would then resolve a real conflict by luck.
      final first = DateTime.utc(2026, 9, 5, 12, 0, 0, 100);
      final second = DateTime.utc(2026, 9, 5, 12, 0, 0, 900);

      final notes = NoteRepository(db);
      await notes.put(
        puzzleId: 'p1',
        cell: 0,
        digit: 1,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
        at: first,
      );
      await notes.put(
        puzzleId: 'p1',
        cell: 0,
        digit: 2,
        kind: NoteKind.settled,
        origin: NoteOrigin.manual,
        at: second,
      );

      final rows = await db.select(db.notes).get();
      final one = rows.firstWhere((r) => r.digit == 1).updatedAt;
      final two = rows.firstWhere((r) => r.digit == 2).updatedAt;
      expect(two.isAfter(one), isTrue, reason: 'sub-second precision was lost');
    });
  });

  group('nothing consumes it yet', () {
    test('no code in this layer sends, uploads, or asks for an account', () {
      // Guarding the "not doing" half of the change. The metadata is written
      // and left alone; acting on it belongs to the sync change.
      final banned = RegExp(
        r'\b(http|HttpClient|Socket|upload|Cognito|signIn|account)\b',
        caseSensitive: false,
      );
      final offenders = <String>[];
      for (final entity in Directory(
        'lib/features/persistence',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final code = lines[i].split('//').first;
          if (banned.hasMatch(code)) offenders.add('${entity.path}:${i + 1}');
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
