import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/domain/config_value.dart';

/// D-24 states its numbers as **hard limits**. A remote config may tighten
/// them; it may not loosen them.
///
/// Without this, the volume half of constraint 6 could be removed by an S3
/// upload that nobody reviews. Loosening is still possible — it means amending
/// D-24 and shipping a build, the same bar every other product constraint has.
void main() {
  group('a config may tighten', () {
    test('fewer interstitials per session is accepted', () {
      expect(ConfigValue.interstitialsPerSession.clampToDefault(4), 4);
      expect(ConfigValue.interstitialsPerSession.clampToDefault(1), 1);
      expect(ConfigValue.interstitialsPerSession.clampToDefault(0), 0);
    });

    test('a longer gap between interstitials is accepted', () {
      expect(
        ConfigValue.interstitialMinimumGapSeconds.clampToDefault(120),
        120,
      );
      expect(
        ConfigValue.interstitialMinimumGapSeconds.clampToDefault(600),
        600,
      );
    });

    test('more nodes between interstitials is accepted', () {
      expect(ConfigValue.interstitialNodeInterval.clampToDefault(5), 5);
    });
  });

  group('a config may not loosen', () {
    // Each covered independently: a config can be wrong about one value and
    // right about the others, and a test that only checks them together would
    // pass on that.
    test('more interstitials per session is rejected', () {
      expect(ConfigValue.interstitialsPerSession.clampToDefault(10), 6);
      expect(ConfigValue.interstitialsPerSession.clampToDefault(7), 6);
    });

    test('a shorter gap between interstitials is rejected', () {
      expect(ConfigValue.interstitialMinimumGapSeconds.clampToDefault(30), 90);
      expect(ConfigValue.interstitialMinimumGapSeconds.clampToDefault(89), 90);
    });

    test('fewer nodes between interstitials is rejected', () {
      expect(ConfigValue.interstitialNodeInterval.clampToDefault(1), 3);
      expect(ConfigValue.interstitialNodeInterval.clampToDefault(2), 3);
    });
  });

  group('the boundary, in both directions', () {
    test('exactly the documented value is accepted', () {
      for (final value in ConfigValue.values) {
        expect(
          value.clampToDefault(value.defaultValue),
          value.defaultValue,
          reason: value.key,
        );
      }
    });

    test('one step looser is rejected, one step stricter is accepted', () {
      for (final value in ConfigValue.values) {
        final looser = switch (value.clamp) {
          ClampDirection.atLeastDefault => value.defaultValue - 1,
          ClampDirection.atMostDefault => value.defaultValue + 1,
        };
        final stricter = switch (value.clamp) {
          ClampDirection.atLeastDefault => value.defaultValue + 1,
          ClampDirection.atMostDefault => value.defaultValue - 1,
        };

        expect(
          value.clampToDefault(looser),
          value.defaultValue,
          reason: '${value.key} accepted a looser value',
        );
        expect(
          value.clampToDefault(stricter),
          stricter,
          reason: '${value.key} rejected a stricter value',
        );
      }
    });
  });

  group(
    'the values a real config file will eventually contain by accident',
    () {
      // Zero, negative, and absurd. None may produce a looser limit than D-24,
      // and none may throw at a caller reading a value.
      test('zero', () {
        for (final value in ConfigValue.values) {
          final result = value.clampToDefault(0);
          switch (value.clamp) {
            case ClampDirection.atLeastDefault:
              expect(result, value.defaultValue, reason: value.key);
            case ClampDirection.atMostDefault:
              // Zero ads is stricter than six, and therefore allowed.
              expect(result, 0, reason: value.key);
          }
        }
      });

      test('negative', () {
        for (final value in ConfigValue.values) {
          expect(
            () => value.clampToDefault(-1),
            returnsNormally,
            reason: value.key,
          );
          if (value.clamp == ClampDirection.atLeastDefault) {
            expect(
              value.clampToDefault(-1),
              value.defaultValue,
              reason: value.key,
            );
          }
        }
      });

      test('absurdly large', () {
        for (final value in ConfigValue.values) {
          final result = value.clampToDefault(1 << 40);
          if (value.clamp == ClampDirection.atMostDefault) {
            expect(
              result,
              value.defaultValue,
              reason: '${value.key} let a huge number through',
            );
          }
        }
      });

      test('no input throws', () {
        for (final value in ConfigValue.values) {
          for (final input in <int>[-1 << 40, -1, 0, 1, 1 << 40]) {
            expect(
              () => value.clampToDefault(input),
              returnsNormally,
              reason: '${value.key} with $input',
            );
          }
        }
      });
    },
  );
}
