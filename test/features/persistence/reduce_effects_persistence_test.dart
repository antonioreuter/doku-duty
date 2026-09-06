import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/application/motion_settings.dart';
import 'package:doku_duty/features/design_system/domain/motion.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/settings_repository.dart';
import 'package:doku_duty/features/persistence/domain/app_setting.dart';

void main() {
  // motionSettingsProvider reads the platform view for the OS reduce-motion
  // setting, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        persistedReduceEffectsOverride,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('starts at the documented default, synchronously', () {
    final container = makeContainer();
    // No await. If this ever needed one, a disk read would be sitting on the
    // path to the first frame.
    expect(container.read(reduceEffectsProvider), isFalse);
  });

  test('flipping it persists', () async {
    final container = makeContainer();
    final notifier =
        container.read(reduceEffectsProvider.notifier)
            as PersistedReduceEffects;
    notifier.set(true);
    expect(container.read(reduceEffectsProvider), isTrue);

    // Await the write itself rather than guessing at a delay, then read storage
    // directly rather than through the notifier that did the writing.
    await notifier.lastWrite;
    expect(await SettingsRepository(db).read(AppSetting.reduceEffects), isTrue);
  });

  test('a stored choice is picked up after the first frame', () async {
    await SettingsRepository(db).write(AppSetting.reduceEffects, value: true);

    final container = makeContainer();
    final notifier =
        container.read(reduceEffectsProvider.notifier)
            as PersistedReduceEffects;
    expect(
      container.read(reduceEffectsProvider),
      isFalse,
      reason: 'the default is what renders first',
    );

    await notifier.hydrated;
    expect(
      container.read(reduceEffectsProvider),
      isTrue,
      reason: 'the stored choice arrives once the read completes',
    );
  });

  test(
    'toggling twice returns to the stored default and persists it',
    () async {
      final container = makeContainer();
      final notifier =
          container.read(reduceEffectsProvider.notifier)
                as PersistedReduceEffects
            ..toggle();
      await notifier.lastWrite;
      expect(
        await SettingsRepository(db).read(AppSetting.reduceEffects),
        isTrue,
      );

      notifier.toggle();
      await notifier.lastWrite;
      expect(
        await SettingsRepository(db).read(AppSetting.reduceEffects),
        isFalse,
      );
    },
  );

  test('a choice made before hydration finishes is not overwritten', () async {
    // The player is faster than the disk. This is not hypothetical: the app is
    // interactive before the read completes, which is the whole point of
    // hydrating late.
    await SettingsRepository(db).write(AppSetting.reduceEffects, value: false);

    final container = makeContainer();
    final notifier =
        container.read(reduceEffectsProvider.notifier) as PersistedReduceEffects
          ..set(true);

    await notifier.lastWrite;
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(reduceEffectsProvider),
      isTrue,
      reason: 'hydration overwrote the choice the player just made',
    );
    expect(await SettingsRepository(db).read(AppSetting.reduceEffects), isTrue);
  });

  group('the two switches stay independent', () {
    test(
      'the OS setting is not stored, and reduce effects does not read it',
      () async {
        await SettingsRepository(
          db,
        ).write(AppSetting.reduceEffects, value: true);
        final container = makeContainer();
        await (container.read(reduceEffectsProvider.notifier)
                as PersistedReduceEffects)
            .hydrated;

        final settings = container.read(motionSettingsProvider);
        expect(settings.reduceEffects, isTrue);
        expect(
          settings.osReduceMotion,
          isFalse,
          reason: 'persisting the in-app switch must not touch the OS one',
        );
        expect(settings.isMotionReduced, isTrue);
        expect(settings.resolve(DokuMotion.puzzleComplete), Duration.zero);
      },
    );
  });
}
