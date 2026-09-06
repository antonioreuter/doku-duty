import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/remote_config/data/config_cache_repository.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('doku_config_cache');
    file = File(p.join(dir.path, 'app.sqlite'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('across a restart', () {
    test('a fetched config is in effect on the next launch', () async {
      final first = AppDatabase(NativeDatabase(file));
      await ConfigCacheRepository(first).write(
        document:
            '{"schema_version": 1, '
            '"${ConfigValue.interstitialsPerSession.key}": 2}',
        validator: 'W/"v1"',
      );
      await first.close();

      // A genuinely separate connection, as a new process would open.
      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final cached = await ConfigCacheRepository(second).read();

      expect(cached, isNotNull);
      expect(cached!.config[ConfigValue.interstitialsPerSession], 2);
      expect(cached.validator, 'W/"v1"');
    });

    test('replacing the cache keeps only the newest document', () async {
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final cache = ConfigCacheRepository(db);

      await cache.write(
        document: '{"${ConfigValue.interstitialsPerSession.key}": 2}',
      );
      await cache.write(
        document: '{"${ConfigValue.interstitialsPerSession.key}": 1}',
        validator: 'W/"v2"',
      );

      expect((await db.select(db.configCache).get()), hasLength(1));
      final cached = await cache.read();
      expect(cached!.config[ConfigValue.interstitialsPerSession], 1);
      expect(cached.validator, 'W/"v2"');
    });
  });

  group('an unusable cache falls back', () {
    test('no cache at all reads as null', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(await ConfigCacheRepository(db).read(), isNull);
    });

    test('a cached document that no longer parses reads as null', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = ConfigCacheRepository(db);

      await cache.write(document: 'this is not json at all');

      // Null means "run on compiled-in defaults", which is a working app.
      expect(await cache.read(), isNull);
    });

    test('a cleared cache reads as null', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = ConfigCacheRepository(db);
      await cache.write(document: '{}');
      await cache.clear();
      expect(await cache.read(), isNull);
    });
  });

  group('the document is re-parsed rather than stored pre-parsed', () {
    // The parser is where clamping and per-key fallback live. A build with a
    // tighter clamp must apply it to a document cached by the build before it.
    test('a cached document that loosens a cap is clamped on read', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = ConfigCacheRepository(db);

      await cache.write(
        document: '{"${ConfigValue.interstitialsPerSession.key}": 99}',
      );

      final cached = await cache.read();
      expect(
        cached!.config[ConfigValue.interstitialsPerSession],
        6,
        reason: 'a cached document is not trusted more than a fetched one',
      );
    });

    test(
      'a cached document with unknown keys still yields the known ones',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final cache = ConfigCacheRepository(db);

        await cache.write(
          document:
              '{"future.key": 1, '
              '"${ConfigValue.interstitialMinimumGapSeconds.key}": 120}',
        );

        final cached = await cache.read();
        expect(cached!.config[ConfigValue.interstitialMinimumGapSeconds], 120);
      },
    );
  });
}
