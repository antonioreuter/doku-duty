import 'package:test/test.dart';

import 'package:doku_duty/features/design_system/domain/motion.dart';

void main() {
  group('the 400ms ceiling', () {
    // Constraint 2, and the reason these are tokens at all. A celebration that
    // delays the next tap converts a reward into an obstacle (D-46).
    test('no in-puzzle motion exceeds 400ms except the two recorded ones', () {
      for (final motion in DokuMotion.values) {
        if (!motion.isInPuzzle) continue;
        if (motion.isRecordedException) continue;
        expect(
          motion.duration.inMilliseconds,
          lessThanOrEqualTo(400),
          reason:
              '${motion.name} is ${motion.duration.inMilliseconds}ms — if '
              'this is deliberate it needs a decision, not a bigger number',
        );
      }
    });

    test(
      'exactly two exceptions are recorded, and they are the documented two',
      () {
        final exceptions = DokuMotion.values
            .where((m) => m.isRecordedException)
            .toList();
        expect(exceptions, <DokuMotion>[
          DokuMotion.cascade, // 520ms, D-47
          DokuMotion.puzzleComplete, // 1400ms
        ]);
      },
    );

    test(
      'an exception must actually exceed the ceiling to claim to be one',
      () {
        for (final motion in DokuMotion.values.where(
          (m) => m.isRecordedException,
        )) {
          expect(
            motion.duration.inMilliseconds,
            greaterThan(400),
            reason: '${motion.name} claims an exception it does not need',
          );
        }
      },
    );
  });

  group('durations match docs/DESIGN.md §5', () {
    test('per-event values', () {
      expect(DokuMotion.valuePlaced.duration, const Duration(milliseconds: 90));
      expect(DokuMotion.keyPressed.duration, const Duration(milliseconds: 90));
      expect(DokuMotion.noteAdded.duration, Duration.zero);
      expect(
        DokuMotion.unitComplete.duration,
        const Duration(milliseconds: 260),
      );
      expect(
        DokuMotion.blockComplete.duration,
        const Duration(milliseconds: 340),
      );
      expect(
        DokuMotion.duplicatePlaced.duration,
        const Duration(milliseconds: 400),
      );
      expect(DokuMotion.cascade.duration, const Duration(milliseconds: 520));
      expect(
        DokuMotion.puzzleComplete.duration,
        const Duration(milliseconds: 1400),
      );
      expect(
        DokuMotion.characterEnters.duration,
        const Duration(milliseconds: 220),
      );
      expect(
        DokuMotion.completionTintHold.duration,
        const Duration(milliseconds: 2000),
      );
    });

    // D-52. Notes are thinking, and thinking should be quiet.
    test('adding a note is instant, with no transition at all', () {
      expect(DokuMotion.noteAdded.duration, Duration.zero);
    });

    test('cascade steps are 90ms apart', () {
      expect(DokuMotion.cascadeStepOffset, const Duration(milliseconds: 90));
    });
  });

  group('reduce motion', () {
    test('every duration collapses to zero when motion is reduced', () {
      for (final motion in DokuMotion.values) {
        expect(
          motion.resolve(reduceMotion: true),
          Duration.zero,
          reason: motion.name,
        );
      }
    });

    test('durations are unchanged when motion is not reduced', () {
      for (final motion in DokuMotion.values) {
        expect(
          motion.resolve(reduceMotion: false),
          motion.duration,
          reason: motion.name,
        );
      }
    });
  });
}
