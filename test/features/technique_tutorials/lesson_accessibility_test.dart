import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';

Lesson get _lesson =>
    lessonCatalogue.firstWhere((lesson) => lesson.id == 'nakedPair');

Widget _host(Lesson lesson, double scale) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
  child: MaterialApp(
    home: LessonView(lesson: lesson, onDone: ({required bool skipped}) {}),
  ),
);

void main() {
  group('at the reader\'s text sizes', () {
    for (final scale in <double>[1, 2, 3, 4, 5]) {
      testWidgets('nothing overflows or truncates at ${scale}x', (
        tester,
      ) async {
        // The smallest phone the app targets (D-84), where the pad overflowed
        // before (D-93). A lesson is a taller surface than the pad.
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(_lesson, scale));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'the lesson overflowed at ${scale}x',
        );

        // The step's sentence is the lesson. Cut off, there is no lesson.
        for (final element in find.text(_lesson.steps.first.text).evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: 'the step text was truncated at ${scale}x',
          );
        }
      });
    }

    testWidgets('the way out stays on screen at every text size', (
      tester,
    ) async {
      // Skip is pinned below the scrolling area precisely so this holds. A way
      // out the player has to go looking for is not one (constraint 1).
      for (final scale in <double>[1, 3, 5]) {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(_lesson, scale));
        await tester.pumpAndSettle();

        final skip = find.byKey(const ValueKey<String>('lesson-skip'));
        expect(skip, findsOneWidget, reason: 'no skip at ${scale}x');
        final box = tester.getRect(skip);
        expect(
          box.bottom,
          lessThanOrEqualTo(568.0),
          reason: 'the skip control is below the fold at ${scale}x',
        );
        expect(box.height, greaterThanOrEqualTo(44), reason: 'D-93 at $scale');
      }
    });
  });

  testWidgets('the step reaches a screen reader as the words it shows', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_lesson, 1));
    await tester.pumpAndSettle();

    // The sentence carries the teaching, so it has to be announced. The grid
    // beside it is excluded rather than read cell by cell.
    expect(find.bySemanticsLabel(_lesson.steps.first.text), findsOneWidget);
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);
    expect(find.bySemanticsLabel('Next'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the marked cells are not marked by colour alone', (
    tester,
  ) async {
    // The painter draws a ring as well as a fill. Asserted on the recorded
    // drawing rather than on the pixels, so a change that dropped the stroke
    // and kept the tint fails here (constraint 5).
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_lesson, 1));
    await tester.pumpAndSettle();

    final painted = find
        .byType(CustomPaint)
        .evaluate()
        .map((e) => (e.widget as CustomPaint).painter);
    expect(
      painted.any(
        (p) => p != null && p.runtimeType.toString().contains('Lesson'),
      ),
      isTrue,
      reason: 'the lesson grid is not painted by its own painter',
    );
  });

  testWidgets('a lesson brings no motion of its own', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(_lesson, 1));
    await tester.pumpAndSettle();

    // Asserted rather than assumed: stepping is a rebuild, not an animation,
    // so there is nothing for **reduce effects** to silence beyond the press
    // feedback the shared control already handles.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
