import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_grid.dart';

Future<void> _loadFont() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// The two **killer** **lesson**s at their first step. The copy says "the
/// dashed outline" — so the outline has to be there, which no other test sees.
void main() {
  setUpAll(_loadFont);

  for (final id in const <String>['cageCombination', 'fortyFiveRule']) {
    testWidgets('the $id lesson draws its cages', (tester) async {
      final lesson = lessonCatalogue.singleWhere((l) => l.id == id);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: DokuColours.sand,
            child: Center(
              child: SizedBox(
                width: 360,
                child: LessonGrid(
                  grid: lesson.grid,
                  cages: lesson.cageSet,
                  marked: lesson.steps.first.cells,
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(LessonGrid),
        matchesGoldenFile('goldens/lesson_$id.png'),
      );
    });
  }
}
