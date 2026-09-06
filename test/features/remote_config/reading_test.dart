import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/application/remote_config_provider.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('before any fetch', () {
    test('every value is readable and returns its compiled-in default', () {
      final container = makeContainer();
      final config = container.read(remoteConfigProvider);
      for (final value in ConfigValue.values) {
        expect(config[value], value.defaultValue, reason: value.key);
      }
    });

    test('reading needs no await', () {
      final container = makeContainer();
      // No `await` anywhere in this test. If reading ever required one, this
      // would not compile — which is the assertion.
      final sessions = container.read(
        remoteConfigProvider,
      )[ConfigValue.interstitialsPerSession];
      expect(sessions, 6);
    });
  });

  group('the read is synchronous, and must stay so', () {
    // A signature test. The day someone makes this async is the day an ad
    // placement starts awaiting, and constraint 2 goes with it.
    test('the config in effect is not a Future', () {
      final container = makeContainer();
      final Object config = container.read(remoteConfigProvider);
      expect(config, isNot(isA<Future<Object?>>()));
      expect(config, isA<RemoteConfig>());
    });

    test('a value read is an int, not a Future<int>', () {
      final container = makeContainer();
      final Object value = container.read(
        remoteConfigProvider,
      )[ConfigValue.interstitialsPerSession];
      expect(value, isA<int>());
      expect(value, isNot(isA<Future<Object?>>()));
    });
  });

  group('applying a config', () {
    test('replaces the values in effect', () {
      final container = makeContainer();
      container
          .read(remoteConfigProvider.notifier)
          .apply(
            const RemoteConfig(
              values: <ConfigValue, int>{
                ConfigValue.interstitialsPerSession: 2,
              },
              schemaVersion: 1,
            ),
          );

      expect(
        container.read(
          remoteConfigProvider,
        )[ConfigValue.interstitialsPerSession],
        2,
      );
    });

    test('a value absent from the applied config still answers', () {
      final container = makeContainer();
      container
          .read(remoteConfigProvider.notifier)
          .apply(
            const RemoteConfig(
              values: <ConfigValue, int>{
                ConfigValue.interstitialsPerSession: 2,
              },
              schemaVersion: 1,
            ),
          );

      // Never null, never a throw — the accessor falls back per key.
      expect(
        container.read(
          remoteConfigProvider,
        )[ConfigValue.interstitialMinimumGapSeconds],
        90,
      );
    });

    test('is applied whole, so no read sees half of two configs', () {
      final container = makeContainer();
      final notifier = container.read(remoteConfigProvider.notifier);

      notifier.apply(
        const RemoteConfig(
          values: <ConfigValue, int>{
            ConfigValue.interstitialsPerSession: 2,
            ConfigValue.interstitialMinimumGapSeconds: 300,
          },
          schemaVersion: 1,
        ),
      );
      final first = container.read(remoteConfigProvider);

      notifier.apply(RemoteConfig.defaults());
      final second = container.read(remoteConfigProvider);

      expect(first[ConfigValue.interstitialsPerSession], 2);
      expect(first[ConfigValue.interstitialMinimumGapSeconds], 300);
      expect(second[ConfigValue.interstitialsPerSession], 6);
      expect(second[ConfigValue.interstitialMinimumGapSeconds], 90);
    });
  });
}
