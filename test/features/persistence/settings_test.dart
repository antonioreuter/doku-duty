import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  group('defaults', () {
    // Constraint 1. This is the assertion that protects the product's entire
    // positioning: flagging on by default would make the app indistinguishable
    // from every competitor, and no code review catches a default. Since D-94
    // **strict mode** is the one switch that carries flagging, so this is now
    // the single most consequential default in the product.
    test('strict mode is off until the player turns it on', () async {
      expect(await settings.read(AppSetting.strictMode), isFalse);
    });

    test('nothing flags errors while it is off', () async {
      // The other half of D-94: there is no second setting that could turn
      // flagging on by itself.
      expect(
        AppSetting.values.map((setting) => setting.name),
        isNot(contains('autoCheck')),
        reason: 'auto-check was retired into strict mode (D-94)',
      );
    });

    test('reduce effects is off — the player opted into nothing', () async {
      expect(await settings.read(AppSetting.reduceEffects), isFalse);
    });

    test(
      'every setting has a documented default and returns it unset',
      () async {
        final all = await settings.readAll();
        expect(all.keys, unorderedEquals(AppSetting.values));
        for (final setting in AppSetting.values) {
          expect(all[setting], setting.defaultValue, reason: setting.name);
        }
      },
    );

    test('no setting defaults to something that could punish the player', () {
      // Every setting that adds a penalty or a limit must default off. If a
      // future setting cannot honestly answer this, it needs its own decision.
      // Stated over every setting rather than a named few, so a new one is
      // caught by this test rather than by a player.
      for (final setting in AppSetting.values) {
        expect(setting.defaultValue, isFalse, reason: setting.name);
      }
    });
  });

  // D-04 and constraint 1: the only route to **strict mode** is the player.
  group('nothing but the player turns strict mode on', () {
    test('no remote value can reach a setting at all', () {
      // Remote config carries ints for ad pacing and nothing else, so an S3
      // upload structurally cannot flip a player-facing switch. `add-remote-
      // config` clamps what it does carry; this asserts what it does not.
      for (final value in ConfigValue.values) {
        expect(value.defaultValue, isA<int>(), reason: value.key);
        expect(value.key, startsWith('ads.'), reason: value.key);
        expect(value.key.toLowerCase(), isNot(contains('strict')));
        expect(value.key.toLowerCase(), isNot(contains('mistake')));
      }
    });

    test('the repository is the only way a setting changes', () async {
      // Writing is the one public route, and it takes an AppSetting — there is
      // no path that takes a rank, a node, or a config key.
      await settings.write(AppSetting.strictMode, value: true);
      expect(await settings.read(AppSetting.strictMode), isTrue);
      await settings.reset(AppSetting.strictMode);
      expect(await settings.read(AppSetting.strictMode), isFalse);
    });
  });

  // A player who turned auto-check on before D-94 retired it has a row on disk
  // under a key nothing maps to any more. It must be inert, not fatal.
  group('a retired setting', () {
    test('a row under a key no setting owns is ignored', () async {
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(
              key: 'autoCheck',
              boolValue: true,
              updatedAt: Value(DateTime.now()),
            ),
          );

      final all = await settings.readAll();

      expect(all.keys, unorderedEquals(AppSetting.values));
      expect(
        all.keys.map((setting) => setting.name),
        isNot(contains('autoCheck')),
      );
    });

    test('every other setting still reads normally beside it', () async {
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(
              key: 'autoCheck',
              boolValue: true,
              updatedAt: Value(DateTime.now()),
            ),
          );

      expect(await settings.read(AppSetting.strictMode), isFalse);
      expect(await settings.read(AppSetting.reduceEffects), isFalse);
      final all = await settings.readAll();
      for (final setting in AppSetting.values) {
        expect(all[setting], setting.defaultValue, reason: setting.name);
      }
    });
  });

  group('choices', () {
    test('a chosen value is returned instead of the default', () async {
      await settings.write(AppSetting.reduceEffects, value: true);
      expect(await settings.read(AppSetting.reduceEffects), isTrue);
    });

    test('resetting returns the setting to its default', () async {
      await settings.write(AppSetting.strictMode, value: true);
      await settings.reset(AppSetting.strictMode);
      expect(await settings.read(AppSetting.strictMode), isFalse);
    });

    test('one setting does not disturb another', () async {
      await settings.write(AppSetting.strictMode, value: true);
      expect(await settings.read(AppSetting.numberFirstInput), isFalse);
      expect(await settings.read(AppSetting.reduceEffects), isFalse);
    });
  });

  group('across a restart', () {
    test('a chosen value survives the app being closed and reopened', () async {
      final dir = Directory.systemTemp.createTempSync('doku_settings_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'settings.sqlite'));

      final first = AppDatabase(NativeDatabase(file));
      await SettingsRepository(
        first,
      ).write(AppSetting.reduceEffects, value: true);
      await first.close();

      // A genuinely new process would open a new database over the same file.
      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      expect(
        await SettingsRepository(second).read(AppSetting.reduceEffects),
        isTrue,
      );
    });
  });
}
