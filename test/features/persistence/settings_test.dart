import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';

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
    // positioning: auto-check on by default would make it indistinguishable
    // from every competitor, and no code review catches a default.
    test('auto-check is off until the player turns it on', () async {
      expect(await settings.read(AppSetting.autoCheck), isFalse);
    });

    test('strict mode is off until the player turns it on', () async {
      expect(await settings.read(AppSetting.strictMode), isFalse);
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
      for (final setting in <AppSetting>[
        AppSetting.strictMode,
        AppSetting.autoCheck,
      ]) {
        expect(setting.defaultValue, isFalse, reason: setting.name);
      }
    });
  });

  group('choices', () {
    test('a chosen value is returned instead of the default', () async {
      await settings.write(AppSetting.reduceEffects, value: true);
      expect(await settings.read(AppSetting.reduceEffects), isTrue);
    });

    test('resetting returns the setting to its default', () async {
      await settings.write(AppSetting.autoCheck, value: true);
      await settings.reset(AppSetting.autoCheck);
      expect(await settings.read(AppSetting.autoCheck), isFalse);
    });

    test('one setting does not disturb another', () async {
      await settings.write(AppSetting.strictMode, value: true);
      expect(await settings.read(AppSetting.autoCheck), isFalse);
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
