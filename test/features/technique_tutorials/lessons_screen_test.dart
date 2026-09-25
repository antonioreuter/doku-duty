import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/technique_tutorials/data/lesson_repository.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lessons_screen.dart';

Widget _app(AppDatabase db) => ProviderScope(
  overrides: [appDatabaseProvider.overrideWith((ref) => db)],
  child: const MaterialApp(home: LessonsScreen()),
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('the list', () {
    testWidgets('holds every lesson', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      for (final lesson in lessonCatalogue) {
        expect(
          find.byKey(ValueKey<String>('lesson-row-${lesson.id}')),
          findsOneWidget,
          reason: lesson.id,
        );
      }
    });

    // Named rather than left to the loop above: cage combination is a
    // Greenhorn technique, the one kind that otherwise has no **lesson**, and
    // a filter by **rank** would drop it without any test here noticing
    // (D-128).
    testWidgets('holds both killer lessons, and each replays', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      for (final id in const <String>['cageCombination', 'fortyFiveRule']) {
        final lesson = lessonCatalogue.singleWhere((l) => l.id == id);
        await tester.tap(find.byKey(ValueKey<String>('lesson-row-$id')));
        await tester.pumpAndSettle();
        expect(find.byType(LessonView), findsOneWidget, reason: id);
        expect(find.text(lesson.steps.first.text), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('says not yet seen, never locked', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      expect(find.text('Not yet seen'), findsWidgets);
      expect(find.textContaining('Locked'), findsNothing);
      expect(find.textContaining('locked'), findsNothing);
    });

    testWidgets('a seen lesson says so', (tester) async {
      await LessonRepository(db).markSeen(Lesson.notes.id);
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(ValueKey<String>('lesson-row-${Lesson.notes.id}')),
          matching: find.text('Seen'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('nothing in the list is disabled', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      for (final lesson in lessonCatalogue) {
        final tile = tester.widget<ListTile>(
          find.byKey(ValueKey<String>('lesson-row-${lesson.id}')),
        );
        expect(tile.onTap, isNotNull, reason: '${lesson.id} is not replayable');
        expect(tile.enabled, isTrue);
      }
    });
  });

  group('replaying', () {
    testWidgets('an unmet lesson plays from the first step', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      final lesson = lessonCatalogue.firstWhere((l) => l.id == 'xWing');
      await tester.tap(find.byKey(const ValueKey<String>('lesson-row-xWing')));
      await tester.pumpAndSettle();

      expect(find.byType(LessonView), findsOneWidget);
      expect(find.text(lesson.steps.first.text), findsOneWidget);
    });

    testWidgets('it disturbs no progression record', (tester) async {
      // A player mid-ladder. Replaying must leave every number where it was:
      // a **lesson** is teaching, not an achievement (constraint 1, D-104).
      await PackRepository(db).installPack(
        packId: 'test',
        version: 1,
        puzzles: <StoredPuzzle>[
          StoredPuzzle(
            id: 'q1',
            clues:
                '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79',
            solution:
                '534678912672195348198342567859761423426853791713924856961537284287419635345286179',
            rank: Rank.sheriff,
            seed: 1,
          ),
        ],
      );
      final progression = ProgressionRepository(db);
      await progression.record(
        puzzleId: 'q1',
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
      );

      final rankBefore = await progression.playerRank();
      final unlockedBefore = await progression.unlockedTechniques();
      final statsBefore = await StatisticsRepository(db).lifetime();

      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('lesson-row-xWing')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(await progression.playerRank(), rankBefore);
      expect(await progression.unlockedTechniques(), unlockedBefore);
      final after = await StatisticsRepository(db).lifetime();
      expect(after.puzzlesSolved, statsBefore.puzzlesSolved);
      expect(after.perfectSolves, statsBefore.perfectSolves);
      // The X-wing was replayed and is still not a **technique unlock** — it
      // was read about, not demonstrated.
      expect(unlockedBefore.contains(Technique.xWing), isFalse);
      expect(
        (await progression.unlockedTechniques()).contains(Technique.xWing),
        isFalse,
      );
    });

    testWidgets('replaying a seen lesson leaves it seen, once', (tester) async {
      await LessonRepository(db).markSeen('xWing');
      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('lesson-row-xWing')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(await LessonRepository(db).seen(), <String>{'xWing'});
    });
  });
}
