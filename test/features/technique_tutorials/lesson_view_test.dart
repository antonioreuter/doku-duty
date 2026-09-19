import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/pressable.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';

Lesson get _lesson =>
    lessonCatalogue.firstWhere((lesson) => lesson.id == 'nakedPair');

Widget _host(Lesson lesson, {void Function({required bool skipped})? onDone}) =>
    MaterialApp(
      home: LessonView(
        lesson: lesson,
        onDone: onDone ?? ({required bool skipped}) {},
      ),
    );

/// A surface tall enough to hold the grid, the sentence and the controls.
/// The default 800x600 cuts the controls off the bottom, and a tap that lands
/// outside the viewport hits nothing.
void _tallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _toFinalStep(WidgetTester tester, Lesson lesson) async {
  for (var i = 0; i < lesson.steps.length - 1; i++) {
    await tester.tap(find.byKey(const ValueKey<String>('lesson-next')));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('stepping through', () {
    testWidgets('each step shows its own sentence', (tester) async {
      final lesson = _lesson;
      _tallSurface(tester);
      await tester.pumpWidget(_host(lesson));
      await tester.pumpAndSettle();

      expect(find.text(lesson.steps.first.text), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('lesson-next')));
      await tester.pumpAndSettle();

      expect(find.text(lesson.steps[1].text), findsOneWidget);
      expect(find.text(lesson.steps.first.text), findsNothing);
    });

    testWidgets('the last step asks for the placement and waits', (
      tester,
    ) async {
      final lesson = _lesson;
      _tallSurface(tester);
      await tester.pumpWidget(_host(lesson));
      await tester.pumpAndSettle();
      await _toFinalStep(tester, lesson);

      // The digits are offered, and nothing has been placed for the player.
      for (var digit = 1; digit <= 9; digit++) {
        expect(
          find.byKey(ValueKey<String>('lesson-digit-$digit')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey<String>('lesson-right')), findsNothing);
      // No Next past the end.
      expect(find.byKey(const ValueKey<String>('lesson-next')), findsNothing);
    });
  });

  group('a wrong placement costs nothing', () {
    testWidgets('it says so and lets the player try again', (tester) async {
      final lesson = _lesson;
      var done = 0;
      _tallSurface(tester);
      await tester.pumpWidget(
        _host(lesson, onDone: ({required bool skipped}) => done++),
      );
      await tester.pumpAndSettle();
      await _toFinalStep(tester, lesson);

      final wrong = lesson.placement.digit == 1 ? 2 : 1;
      await tester.tap(find.byKey(ValueKey<String>('lesson-digit-$wrong')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('lesson-wrong')),
        findsOneWidget,
      );
      // Nothing ended, nothing was reported, and the digits are still there.
      expect(done, 0);
      expect(
        find.byKey(ValueKey<String>('lesson-digit-${lesson.placement.digit}')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(ValueKey<String>('lesson-digit-${lesson.placement.digit}')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('lesson-right')),
        findsOneWidget,
      );
    });

    testWidgets('every wrong digit can be tried, in any order', (tester) async {
      final lesson = _lesson;
      _tallSurface(tester);
      await tester.pumpWidget(_host(lesson));
      await tester.pumpAndSettle();
      await _toFinalStep(tester, lesson);

      for (var digit = 1; digit <= 9; digit++) {
        if (digit == lesson.placement.digit) continue;
        await tester.tap(find.byKey(ValueKey<String>('lesson-digit-$digit')));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>('lesson-right')), findsNothing);
    });
  });

  group('skipping', () {
    testWidgets('is offered on every step and never disabled', (tester) async {
      final lesson = _lesson;
      _tallSurface(tester);
      await tester.pumpWidget(_host(lesson));
      await tester.pumpAndSettle();

      for (var i = 0; i < lesson.steps.length; i++) {
        final skip = tester.widget<Pressable>(
          find.byKey(const ValueKey<String>('lesson-skip')),
        );
        expect(skip.onPressed, isNotNull, reason: 'step $i has no way out');
        if (i < lesson.steps.length - 1) {
          await tester.tap(find.byKey(const ValueKey<String>('lesson-next')));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('reports itself as a skip, and finishing does not', (
      tester,
    ) async {
      final lesson = _lesson;
      final reported = <bool>[];
      _tallSurface(tester);
      await tester.pumpWidget(
        _host(
          lesson,
          onDone: ({required bool skipped}) => reported.add(skipped),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
      await tester.pumpAndSettle();
      expect(reported, <bool>[true]);
    });

    testWidgets('finishing the placement reports a completion, not a skip', (
      tester,
    ) async {
      final lesson = _lesson;
      final reported = <bool>[];
      _tallSurface(tester);
      await tester.pumpWidget(
        _host(
          lesson,
          onDone: ({required bool skipped}) => reported.add(skipped),
        ),
      );
      await tester.pumpAndSettle();
      await _toFinalStep(tester, lesson);

      await tester.tap(
        find.byKey(ValueKey<String>('lesson-digit-${lesson.placement.digit}')),
      );
      await tester.pumpAndSettle();
      // The same control, now reading Done — one way out, whichever route.
      await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
      await tester.pumpAndSettle();

      expect(reported, <bool>[false]);
    });
  });

  group('a lesson reaches nothing outside itself', () {
    test('it carries no repository, no provider, and no puzzle', () {
      // Structural, because the risk is structural: a lesson that could write
      // would be able to move a **rank** or a **mistake** tally from a screen
      // the player was told costs nothing (constraint 1).
      final source = File(
        'lib/features/technique_tutorials/presentation/lesson_view.dart',
      ).readAsStringSync();
      for (final forbidden in const <String>[
        'repository',
        'Repository',
        'riverpod',
        'AppDatabase',
        'PuzzleSession',
        'Board',
      ]) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: 'the lesson view reaches $forbidden',
        );
      }
    });
  });
}
