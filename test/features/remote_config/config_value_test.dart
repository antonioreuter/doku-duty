import 'package:test/test.dart';

import 'package:doku_duty/features/remote_config/domain/config_value.dart';

void main() {
  group('the compiled-in defaults are D-24', () {
    // The numbers are asserted by name rather than by relationship, so an edit
    // has to change a test that spells them out. Nothing reads these until
    // change 24, which means a wrong value here is invisible for twenty changes
    // and then becomes an ad volume nobody approved.
    test('one interstitial per three completed nodes', () {
      expect(ConfigValue.interstitialNodeInterval.defaultValue, 3);
    });

    test('ninety seconds minimum between interstitials', () {
      expect(ConfigValue.interstitialMinimumGapSeconds.defaultValue, 90);
    });

    test('six per session maximum', () {
      expect(ConfigValue.interstitialsPerSession.defaultValue, 6);
    });
  });

  group('nothing here can affect placement', () {
    // Constraint 6's placement half. Written before there is anything to
    // guard, because afterwards nobody thinks to: the set is small and
    // innocent-looking now, and the day someone adds
    // `ads.allow_during_puzzle` is the day this test earns its keep.
    test('no configurable value mentions when an ad may appear', () {
      const forbidden = <String>[
        'puzzle',
        'grid',
        'celebration',
        'tap',
        'chest',
        'boss',
        'daily',
        'placement',
        'allow',
        'enable',
        'during',
      ];

      for (final value in ConfigValue.values) {
        for (final word in forbidden) {
          expect(
            value.key.toLowerCase().contains(word),
            isFalse,
            reason:
                '${value.key} looks like a placement rule. Placement is '
                'compiled in and not configurable — only volume is tunable.',
          );
        }
      }
    });

    test('every configurable value is a volume limit', () {
      // The whole set, named. Adding a member without updating this test is
      // the review moment.
      expect(ConfigValue.values, <ConfigValue>[
        ConfigValue.interstitialNodeInterval,
        ConfigValue.interstitialMinimumGapSeconds,
        ConfigValue.interstitialsPerSession,
      ]);
    });

    test('keys are unique', () {
      expect(
        ConfigValue.values.map((v) => v.key).toSet(),
        hasLength(ConfigValue.values.length),
      );
    });
  });
}
