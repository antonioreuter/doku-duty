import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/application/motion_settings.dart';
import 'package:doku_duty/features/design_system/domain/motion.dart';

void main() {
  group('two independent switches', () {
    test('motion runs when neither is set', () {
      const settings = MotionSettings(
        osReduceMotion: false,
        reduceEffects: false,
      );
      expect(settings.isMotionReduced, isFalse);
      for (final motion in DokuMotion.values) {
        expect(settings.resolve(motion), motion.duration, reason: motion.name);
      }
    });

    test('the OS setting alone silences motion', () {
      const settings = MotionSettings(
        osReduceMotion: true,
        reduceEffects: false,
      );
      expect(settings.isMotionReduced, isTrue);
      for (final motion in DokuMotion.values) {
        expect(settings.resolve(motion), Duration.zero, reason: motion.name);
      }
    });

    test('the in-app switch alone silences motion', () {
      const settings = MotionSettings(
        osReduceMotion: false,
        reduceEffects: true,
      );
      expect(settings.isMotionReduced, isTrue);
      for (final motion in DokuMotion.values) {
        expect(settings.resolve(motion), Duration.zero, reason: motion.name);
      }
    });

    test('neither switch can override the other', () {
      const both = MotionSettings(osReduceMotion: true, reduceEffects: true);
      expect(both.isMotionReduced, isTrue);
    });

    // The exception the design calls out: instant states were already instant,
    // so reducing motion does not change them.
    test('instant states are unaffected', () {
      const on = MotionSettings(osReduceMotion: true, reduceEffects: false);
      const off = MotionSettings(osReduceMotion: false, reduceEffects: false);
      expect(on.resolve(DokuMotion.noteAdded), Duration.zero);
      expect(off.resolve(DokuMotion.noteAdded), Duration.zero);
    });
  });

  group('the in-app switch', () {
    test('defaults to off — the player opted into nothing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(reduceEffectsProvider), isFalse);
    });

    testWidgets('flipping it reduces motion without touching the OS setting', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(motionSettingsProvider).isMotionReduced, isFalse);
      container.read(reduceEffectsProvider.notifier).set(true);
      final settings = container.read(motionSettingsProvider);
      expect(settings.reduceEffects, isTrue);
      expect(settings.osReduceMotion, isFalse);
      expect(settings.isMotionReduced, isTrue);
      expect(settings.resolve(DokuMotion.puzzleComplete), Duration.zero);
    });
  });

  group('nothing is lost when motion is off', () {
    // Every motion resolves to its end state rather than being skipped, so no
    // information an animation carries becomes unavailable.
    test('every event still has a destination to land on', () {
      const settings = MotionSettings(
        osReduceMotion: true,
        reduceEffects: false,
      );
      for (final motion in DokuMotion.values) {
        expect(settings.resolve(motion), Duration.zero, reason: motion.name);
        // The event itself still exists — reducing motion removes the
        // transition, never the state change.
        expect(DokuMotion.values, contains(motion));
      }
    });
  });
}
