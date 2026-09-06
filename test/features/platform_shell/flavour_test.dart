import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:test/test.dart';

void main() {
  group('FlavourConfig', () {
    test('prod carries the unsuffixed identifier from D-69', () {
      const config = FlavourConfig.prod;

      expect(config.flavour, Flavour.prod);
      expect(config.bundleIdentifier, 'com.alreuter.dokuduty');
      expect(config.appName, 'Doku Duty');
      expect(config.sentryEnvironment, 'production');
    });

    test('staging suffixes the identifier', () {
      const config = FlavourConfig.staging;

      expect(config.flavour, Flavour.staging);
      expect(config.bundleIdentifier, 'com.alreuter.dokuduty.staging');
      expect(config.appName, 'Duty STG');
      expect(config.sentryEnvironment, 'staging');
    });

    test('dev suffixes the identifier', () {
      const config = FlavourConfig.dev;

      expect(config.flavour, Flavour.dev);
      expect(config.bundleIdentifier, 'com.alreuter.dokuduty.dev');
      expect(config.appName, 'Duty DEV');
      expect(config.sentryEnvironment, 'development');
    });

    test('every flavour resolves to a distinct identifier and name', () {
      const configs = FlavourConfig.values;

      expect(configs.length, Flavour.values.length);
      expect(
        configs.map((c) => c.bundleIdentifier).toSet().length,
        configs.length,
        reason:
            'two flavours sharing an identifier cannot install side by side',
      );
      expect(configs.map((c) => c.appName).toSet().length, configs.length);
      expect(
        configs.map((c) => c.sentryEnvironment).toSet().length,
        configs.length,
      );
    });

    test('every identifier is a valid iOS bundle identifier', () {
      // Apple allows alphanumerics, hyphen, and period only — an underscore
      // here is rejected at upload, long after it is cheap to change.
      final valid = RegExp(r'^[A-Za-z0-9.-]+$');

      for (final config in FlavourConfig.values) {
        expect(
          valid.hasMatch(config.bundleIdentifier),
          isTrue,
          reason: '${config.bundleIdentifier} is not a valid bundle id',
        );
      }
    });

    test('only prod is the release flavour', () {
      expect(FlavourConfig.prod.isProd, isTrue);
      expect(FlavourConfig.staging.isProd, isFalse);
      expect(FlavourConfig.dev.isProd, isFalse);
    });

    test('lookup by flavour returns the matching config', () {
      for (final flavour in Flavour.values) {
        expect(FlavourConfig.of(flavour).flavour, flavour);
      }
    });
  });
}
