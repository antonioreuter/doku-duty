import 'dart:convert';

import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';

String configJson(Map<String, Object?> body) => jsonEncode(body);

void main() {
  group('unknown keys', () {
    // A newer config must never break an older app. The server will gain keys
    // long before every player has a build that knows them.
    test('are ignored, and known keys still apply', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{
          'schema_version': 1,
          ConfigValue.interstitialsPerSession.key: 4,
          'ads.some_future_thing': 'whatever',
          'seasons.definitions': <Object?>[1, 2, 3],
        }),
      );

      expect(config, isNotNull);
      expect(config![ConfigValue.interstitialsPerSession], 4);
    });

    test('a config of nothing but unknown keys leaves defaults in place', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{'entirely.unknown': 1}),
      );
      expect(config, isNotNull);
      for (final value in ConfigValue.values) {
        expect(config![value], value.defaultValue, reason: value.key);
      }
    });
  });

  group('one malformed value', () {
    test('falls back alone; the rest of the config still applies', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{
          ConfigValue.interstitialsPerSession.key: 'not a number',
          ConfigValue.interstitialMinimumGapSeconds.key: 120,
        }),
      );

      expect(config, isNotNull);
      expect(
        config![ConfigValue.interstitialsPerSession],
        ConfigValue.interstitialsPerSession.defaultValue,
        reason: 'the bad key falls back',
      );
      expect(
        config[ConfigValue.interstitialMinimumGapSeconds],
        120,
        reason: 'the good key still applies',
      );
    });

    test('a null, a list, and an object each fall back on their own', () {
      for (final bad in <Object?>[null, <Object?>[], <String, Object?>{}]) {
        final config = RemoteConfigParser.parse(
          configJson(<String, Object?>{
            ConfigValue.interstitialsPerSession.key: bad,
            ConfigValue.interstitialMinimumGapSeconds.key: 150,
          }),
        );
        expect(
          config![ConfigValue.interstitialsPerSession],
          6,
          reason: 'bad value $bad',
        );
        expect(config[ConfigValue.interstitialMinimumGapSeconds], 150);
      }
    });

    test('a missing key falls back without affecting the others', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{
          ConfigValue.interstitialMinimumGapSeconds.key: 200,
        }),
      );
      expect(config![ConfigValue.interstitialsPerSession], 6);
      expect(config[ConfigValue.interstitialNodeInterval], 3);
      expect(config[ConfigValue.interstitialMinimumGapSeconds], 200);
    });
  });

  group('number shapes a real file will contain', () {
    test('a JSON double that is whole is accepted', () {
      final config = RemoteConfigParser.parse(
        '{"${ConfigValue.interstitialMinimumGapSeconds.key}": 120.0}',
      );
      expect(config![ConfigValue.interstitialMinimumGapSeconds], 120);
    });

    test('a quoted number is accepted', () {
      final config = RemoteConfigParser.parse(
        '{"${ConfigValue.interstitialMinimumGapSeconds.key}": "120"}',
      );
      expect(config![ConfigValue.interstitialMinimumGapSeconds], 120);
    });

    test('a fractional number falls back rather than being rounded', () {
      final config = RemoteConfigParser.parse(
        '{"${ConfigValue.interstitialMinimumGapSeconds.key}": 120.5}',
      );
      expect(
        config![ConfigValue.interstitialMinimumGapSeconds],
        90,
        reason: 'guessing what half a second meant is worse than the default',
      );
    });
  });

  group('parsed values are still clamped', () {
    test('a config loosening a cap does not get through the parser', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{
          ConfigValue.interstitialsPerSession.key: 50,
          ConfigValue.interstitialMinimumGapSeconds.key: 5,
          ConfigValue.interstitialNodeInterval.key: 1,
        }),
      );

      expect(config![ConfigValue.interstitialsPerSession], 6);
      expect(config[ConfigValue.interstitialMinimumGapSeconds], 90);
      expect(config[ConfigValue.interstitialNodeInterval], 3);
    });
  });

  group('the schema version', () {
    test('is recorded when present', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{'schema_version': 7}),
      );
      expect(config!.schemaVersion, 7);
    });

    test('an unrecognised version is still parsed per key', () {
      final config = RemoteConfigParser.parse(
        configJson(<String, Object?>{
          'schema_version': 999,
          ConfigValue.interstitialsPerSession.key: 2,
        }),
      );
      expect(config!.schemaVersion, 999);
      expect(
        config[ConfigValue.interstitialsPerSession],
        2,
        reason: 'a future version must not blank the config',
      );
    });

    test('is null when the document declares none', () {
      final config = RemoteConfigParser.parse(configJson(<String, Object?>{}));
      expect(config!.schemaVersion, isNull);
    });
  });

  group('documents that are not config at all', () {
    // These return null, meaning "nothing usable here" — the caller keeps what
    // is already in effect rather than falling back to compiled-in values.
    test(
      'an empty object parses to all defaults, which is not the same thing',
      () {
        final config = RemoteConfigParser.parse('{}');
        expect(config, isNotNull);
        expect(config![ConfigValue.interstitialsPerSession], 6);
      },
    );

    test('an array where an object was expected is rejected', () {
      expect(RemoteConfigParser.parse('[1,2,3]'), isNull);
    });

    test('a truncated document is rejected', () {
      expect(RemoteConfigParser.parse('{"schema_version": 1,'), isNull);
    });

    test('an empty body is rejected', () {
      expect(RemoteConfigParser.parse(''), isNull);
    });

    test('a bare string or number is rejected', () {
      expect(RemoteConfigParser.parse('"hello"'), isNull);
      expect(RemoteConfigParser.parse('42'), isNull);
    });
  });

  group('the defaults constructor', () {
    test('answers every value with its compiled-in default', () {
      final config = RemoteConfig.defaults();
      for (final value in ConfigValue.values) {
        expect(config[value], value.defaultValue, reason: value.key);
      }
      expect(config.schemaVersion, isNull);
    });
  });
}
