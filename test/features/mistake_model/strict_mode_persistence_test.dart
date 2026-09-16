import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/mistake_model/application/strict_mode.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        persistedStrictModeOverride,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('starts off, synchronously', () {
    final container = makeContainer();
    // No await. A disk read here would be on the path to the first frame, and
    // the value it would be waiting for is the one already returned.
    expect(container.read(strictModeProvider), isFalse);
  });

  test('turning it on persists', () async {
    final container = makeContainer();
    final notifier =
        container.read(strictModeProvider.notifier) as PersistedStrictMode;

    notifier.set(true);
    expect(container.read(strictModeProvider), isTrue);

    await notifier.lastWrite;
    expect(await SettingsRepository(db).read(AppSetting.strictMode), isTrue);
  });

  test('a stored choice arrives after the first frame', () async {
    await SettingsRepository(db).write(AppSetting.strictMode, value: true);

    final container = makeContainer();
    final notifier =
        container.read(strictModeProvider.notifier) as PersistedStrictMode;

    // Off at first — the safe direction — and on once the disk has answered.
    expect(container.read(strictModeProvider), isFalse);
    await notifier.hydrated;
    expect(container.read(strictModeProvider), isTrue);
  });

  // Constraint 1: the race between hydration and a player's tap may only ever
  // resolve towards the player, and a moment of guessing "on" would flag a
  // digit for someone who never asked.
  test('the player beats the disk', () async {
    await SettingsRepository(db).write(AppSetting.strictMode, value: true);

    final container = makeContainer();
    final notifier =
        container.read(strictModeProvider.notifier) as PersistedStrictMode;

    notifier.set(false);
    await notifier.hydrated;

    expect(
      container.read(strictModeProvider),
      isFalse,
      reason: 'the stored value is stale the moment the player chooses',
    );
  });

  test('turning it off persists too', () async {
    await SettingsRepository(db).write(AppSetting.strictMode, value: true);
    final container = makeContainer();
    final notifier =
        container.read(strictModeProvider.notifier) as PersistedStrictMode;
    await notifier.hydrated;

    notifier.toggle();
    await notifier.lastWrite;

    expect(container.read(strictModeProvider), isFalse);
    expect(await SettingsRepository(db).read(AppSetting.strictMode), isFalse);
  });

  test('without the override it is in memory and still off', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(strictModeProvider), isFalse);
  });
}
