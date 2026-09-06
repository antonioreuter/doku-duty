import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/shape.dart';
import 'package:doku_duty/features/design_system/presentation/pressable.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: child),
);

AnimatedContainer _container(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));

double _bottomPadding(WidgetTester tester) =>
    (_container(tester).padding! as EdgeInsets).bottom;

double _translationY(WidgetTester tester) =>
    _container(tester).transform!.getTranslation().y;

void main() {
  group('pressing', () {
    testWidgets('translates down and drops depth, then restores', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Pressable(
            onPressed: () {},
            child: const SizedBox(width: 120, height: 44),
          ),
        ),
      );

      expect(_bottomPadding(tester), DokuDepth.rest);
      expect(_translationY(tester), 0.0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(_bottomPadding(tester), DokuDepth.pressed);
      expect(_translationY(tester), DokuDepth.pressTranslation);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(_bottomPadding(tester), DokuDepth.rest);
      expect(_translationY(tester), 0.0);
    });

    testWidgets('total travel is the documented 8px', (tester) async {
      await tester.pumpWidget(
        _host(
          Pressable(
            onPressed: () {},
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final restTop = _translationY(tester);
      final restDepth = _bottomPadding(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final travel =
          (_translationY(tester) - restTop) +
          (restDepth - _bottomPadding(tester));
      expect(travel, 8.0);
      await gesture.up();
    });
  });

  group('latency', () {
    // Constraint 2: no animation ever blocks the next tap. A player mashing the
    // number pad must never lose an input to a rebound still in flight.
    testWidgets('the next tap lands while the release is still animating', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Pressable(
            onPressed: () => taps++,
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      );

      await tester.tap(find.byType(Pressable));
      await tester.pump(const Duration(milliseconds: 10)); // mid-rebound
      await tester.tap(find.byType(Pressable));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byType(Pressable));
      await tester.pumpAndSettle();

      expect(taps, 3);
    });

    testWidgets('the callback fires on tap, not after the animation', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          Pressable(
            onPressed: () => tapped = true,
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      );
      await tester.tap(find.byType(Pressable));
      // No pump for the animation duration — the action already happened.
      expect(tapped, isTrue);
    });
  });

  group('disabled', () {
    testWidgets('does not move when it has no action', (tester) async {
      await tester.pumpWidget(
        _host(const Pressable(child: SizedBox.square(dimension: 48))),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(_bottomPadding(tester), DokuDepth.rest);
      expect(_translationY(tester), 0.0);
      await gesture.up();
    });
  });

  group('reduce motion', () {
    testWidgets('lands on the pressed state with no transition', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Pressable(
            onPressed: () {},
            reduceMotion: true,
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Pressable)),
      );
      await tester.pump();
      expect(_bottomPadding(tester), DokuDepth.pressed);
      await gesture.up();
    });
  });

  group('the shadow', () {
    testWidgets('is a solid offset in the token family, never a blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Pressable(
            onPressed: () {},
            token: PaletteToken.cactusGreen,
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      );
      final decoration = _container(tester).decoration! as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(
        decoration.boxShadow,
        anyOf(isNull, isEmpty),
        reason: 'depth is a painted offset, not a BoxShadow',
      );
      // The shadow is the same family as the face.
      expect(
        decoration.color!.toARGB32() & 0xFFFFFF,
        PaletteToken.cactusGreen.depthShade,
      );
    });
  });
}
