import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

Lesson get _lesson =>
    lessonCatalogue.firstWhere((lesson) => lesson.id == 'nakedPair');

/// The three states a **lesson** passes through.
///
/// A golden rather than a widget assertion because what is under test is what
/// the player *sees*: which cells are marked, that the mark carries a ring and
/// not only a fill (constraint 5), and that the placement prompt reads as an
/// invitation rather than a test.
void main() {
  setUpAll(_loadFont);

  Future<void> pumpAndMatch(
    WidgetTester tester,
    String name, {
    int advance = 0,
    bool place = false,
  }) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final lesson = _lesson;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonView(lesson: lesson, onDone: ({required bool skipped}) {}),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < advance; i++) {
      await tester.tap(find.byKey(const ValueKey<String>('lesson-next')));
      await tester.pumpAndSettle();
    }
    if (place) {
      await tester.tap(
        find.byKey(ValueKey<String>('lesson-digit-${lesson.placement.digit}')),
      );
      await tester.pumpAndSettle();
    }

    await expectLater(
      find.byType(LessonView),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('the first step', (tester) async {
    await pumpAndMatch(tester, 'lesson_first_step');
  });

  testWidgets('mid-walkthrough, with cells marked', (tester) async {
    await pumpAndMatch(tester, 'lesson_marked', advance: 1);
  });

  testWidgets('the placement prompt', (tester) async {
    await pumpAndMatch(tester, 'lesson_placement', advance: 2);
  });

  testWidgets('the placement made', (tester) async {
    await pumpAndMatch(tester, 'lesson_placed', advance: 2, place: true);
  });
}
