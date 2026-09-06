import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/haptics.dart';
import 'package:doku_duty/features/design_system/domain/motion.dart';
import 'package:doku_duty/features/design_system/presentation/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('the vocabulary', () {
    test('has exactly the five members docs/DESIGN.md §5 names', () {
      expect(DokuHaptic.values, <DokuHaptic>[
        DokuHaptic.selectionTick,
        DokuHaptic.lightImpact,
        DokuHaptic.mediumImpact,
        DokuHaptic.lightDoubleTap,
        DokuHaptic.success,
      ]);
    });

    test('every member fires something', () async {
      for (final haptic in DokuHaptic.values) {
        calls.clear();
        await const HapticService().fire(haptic);
        expect(calls, isNotEmpty, reason: haptic.name);
      }
    });
  });

  group('notes are silent', () {
    // D-52. Asserted on the event table, so a note can never acquire a haptic
    // without someone editing the table.
    test('note entry has no haptic in the event table', () {
      expect(DokuMotion.noteAdded.haptic, isNull);
    });

    test('firing the note event fires nothing', () async {
      await const HapticService().fire(DokuMotion.noteAdded.haptic);
      expect(calls, isEmpty);
    });
  });

  group('latency', () {
    // Constraint 2. The double tap has a 90ms gap in it; a caller awaiting
    // fire() in a tap handler must not wait that gap out.
    testWidgets('firing never makes the caller wait for a gap', (tester) async {
      for (final haptic in DokuHaptic.values) {
        var completed = false;
        unawaited(
          const HapticService().fire(haptic).then((_) {
            completed = true;
          }),
        );
        await tester.pump();
        expect(
          completed,
          isTrue,
          reason: '${haptic.name} did not return promptly',
        );
      }
      // Let the scheduled second pulse land so it does not leak into the next
      // test.
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('the double tap still produces two pulses', (tester) async {
      calls.clear();
      await const HapticService().fire(DokuHaptic.lightDoubleTap);
      expect(calls, hasLength(1), reason: 'the first pulse is immediate');
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, hasLength(2), reason: 'the second pulse follows the gap');
    });
  });

  group('degrading', () {
    test(
      'a device that cannot produce a haptic is a no-op, not an error',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              throw PlatformException(code: 'unavailable');
            });
        await expectLater(
          const HapticService().fire(DokuHaptic.selectionTick),
          completes,
        );
      },
    );

    test('no platform side at all is also a no-op', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            throw MissingPluginException();
          });
      await expectLater(
        const HapticService().fire(DokuHaptic.success),
        completes,
      );
    });

    test('haptics off fires nothing', () async {
      await const HapticService(isEnabled: false).fire(DokuHaptic.mediumImpact);
      expect(calls, isEmpty);
    });
  });

  group('the event table', () {
    test('every in-puzzle event that should buzz has a haptic', () {
      expect(DokuMotion.valuePlaced.haptic, DokuHaptic.selectionTick);
      expect(DokuMotion.keyPressed.haptic, DokuHaptic.selectionTick);
      expect(DokuMotion.unitComplete.haptic, DokuHaptic.lightImpact);
      expect(DokuMotion.blockComplete.haptic, DokuHaptic.mediumImpact);
      expect(DokuMotion.duplicatePlaced.haptic, DokuHaptic.lightDoubleTap);
      expect(DokuMotion.puzzleComplete.haptic, DokuHaptic.success);
    });

    test('the tint hold and the character entrance are silent', () {
      expect(DokuMotion.completionTintHold.haptic, isNull);
      expect(DokuMotion.characterEnters.haptic, isNull);
    });
  });
}
