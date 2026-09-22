import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/technique_tutorials/data/lesson_repository.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';

import '../../support/home_navigation.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// A puzzle from the shipped **pack** that genuinely needs a hidden single.
///
/// The fixture above does not: it grades Greenhorn and uses only full house and
/// naked single, neither of which has a **lesson**. A test that wanted to see a
/// technique **lesson** fire on it was asserting against a board with nothing
/// to teach — which is what the first draft of this file did.
const String _deputyClues =
    '.6.......83..19....42.....7.....6.89...8..17...7.91.4.2.8.....4..........1.5..8.6';

Future<AppDatabase> _seeded(
  Set<Rank> ranks, {
  bool needsTechnique = false,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  await PackRepository(db).installPack(
    packId: 'test',
    version: 1,
    puzzles: <StoredPuzzle>[
      for (final rank in ranks)
        StoredPuzzle(
          id: 'q-${rank.name}',
          clues: needsTechnique ? _deputyClues : _clues,
          solution: _solution,
          rank: rank,
          seed: 1,
        ),
    ],
  );
  return db;
}

Widget _app(AppDatabase db) => ProviderScope(
  overrides: [
    flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
    appDatabaseProvider.overrideWith((ref) => db),
    packInstallationProvider.overrideWith(
      (ref) async => PackInstallOutcome.alreadyInstalled,
    ),
    persistedStrictModeOverride,
  ],
  child: const DokuDutyApp(),
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(500, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _open(WidgetTester tester, AppDatabase db, Rank rank) async {
  _tall(tester);
  await tester.pumpWidget(_app(db));
  await tester.pumpAndSettle();
  await goToFreePlay(tester);
  await tester.tap(find.byKey(ValueKey<String>('rank-${rank.name}')));
  await tester.pumpAndSettle();
}

/// Leave whatever lesson is on screen, and wait for the write behind it.
Future<void> _skip(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('a lesson stands in front of the grid', () {
    testWidgets('and the puzzle opens once it is skipped', (tester) async {
      final db = await _seeded(<Rank>{Rank.sheriff});
      addTearDown(db.close);

      await _open(tester, db, Rank.sheriff);
      expect(find.byType(LessonView), findsOneWidget);
      expect(find.byType(PuzzleGrid), findsNothing);

      await _skip(tester);
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    testWidgets('skipping marks it seen, before the puzzle opens', (
      tester,
    ) async {
      final db = await _seeded(<Rank>{Rank.sheriff});
      addTearDown(db.close);

      await _open(tester, db, Rank.sheriff);
      expect(await LessonRepository(db).seen(), isEmpty);

      await _skip(tester);

      // Written, and written by the time the grid is up (constraint 9).
      expect(await LessonRepository(db).hasSeen(Lesson.notes.id), isTrue);
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    testWidgets('a completed lesson is marked seen too', (tester) async {
      final db = await _seeded(<Rank>{Rank.sheriff});
      addTearDown(db.close);

      await _open(tester, db, Rank.sheriff);
      final lesson = lessonCatalogue.firstWhere((l) => l.id == Lesson.notes.id);
      for (var i = 0; i < lesson.steps.length - 1; i++) {
        await tester.tap(find.byKey(const ValueKey<String>('lesson-next')));
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.byKey(ValueKey<String>('lesson-digit-${lesson.placement.digit}')),
      );
      await tester.pumpAndSettle();
      await _skip(tester); // the same control, now reading Done

      expect(await LessonRepository(db).hasSeen(Lesson.notes.id), isTrue);
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });
  });

  group('at most one per opening', () {
    testWidgets('a second due lesson waits for the next opening', (
      tester,
    ) async {
      final db = await _seeded(<Rank>{Rank.sheriff}, needsTechnique: true);
      addTearDown(db.close);

      // Notes and a technique lesson are both due on this board.
      await _open(tester, db, Rank.sheriff);
      await _skip(tester);
      expect(find.byType(PuzzleGrid), findsOneWidget);
      expect(await LessonRepository(db).seen(), hasLength(1));

      // Leaving and coming back offers the next one, not a queue of them.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('rank-sheriff')));
      await tester.pumpAndSettle();

      expect(find.byType(LessonView), findsOneWidget);
      await _skip(tester);
      expect(await LessonRepository(db).seen(), hasLength(2));
    });
  });

  group('nothing due', () {
    testWidgets('a puzzle needing nothing new opens straight to the grid', (
      tester,
    ) async {
      final db = await _seeded(<Rank>{Rank.greenhorn});
      addTearDown(db.close);

      // Greenhorn techniques have no lesson, and notes are not owed until
      // Sheriff — so there is nothing to teach and no pause.
      await _open(tester, db, Rank.greenhorn);

      expect(find.byType(LessonView), findsNothing);
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    testWidgets('a technique already solved is not taught', (tester) async {
      final db = await _seeded(<Rank>{Rank.sheriff});
      addTearDown(db.close);

      // Everything this board needs has been demonstrated already, and notes
      // have been seen — so the board opens directly (D-104).
      await LessonRepository(db).markSeen(Lesson.notes.id);
      for (final technique in Technique.values) {
        await ProgressionRepository(db).record(
          puzzleId: 'q-${Rank.sheriff.name}',
          techniquesRequired: <Technique>{technique},
          timeTaken: const Duration(minutes: 1),
          attempt: Attempt.fresh,
        );
      }

      await _open(tester, db, Rank.sheriff);
      expect(find.byType(LessonView), findsNothing);
    });
  });

  group('the notes lesson', () {
    testWidgets('is what a Sheriff-rank puzzle teaches first', (tester) async {
      final db = await _seeded(<Rank>{Rank.sheriff});
      addTearDown(db.close);

      await _open(tester, db, Rank.sheriff);
      expect(find.text('Notes'), findsWidgets);
    });

    testWidgets('has landed before a Marshal puzzle is opened', (tester) async {
      final db = await _seeded(<Rank>{Rank.sheriff, Rank.marshal});
      addTearDown(db.close);

      await _open(tester, db, Rank.sheriff);
      await _skip(tester);
      expect(await LessonRepository(db).hasSeen(Lesson.notes.id), isTrue);
    });
  });

  group('skipping everything blocks nothing', () {
    testWidgets('every rank still opens for a player who skips it all', (
      tester,
    ) async {
      final db = await _seeded(Rank.values.toSet());
      addTearDown(db.close);

      _tall(tester);
      await tester.pumpWidget(_app(db));
      await tester.pumpAndSettle();
      await goToFreePlay(tester);

      for (final rank in Rank.values) {
        await tester.tap(find.byKey(ValueKey<String>('rank-${rank.name}')));
        await tester.pumpAndSettle();

        while (find.byType(LessonView).evaluate().isNotEmpty) {
          await _skip(tester);
        }

        expect(
          find.byType(PuzzleGrid),
          findsOneWidget,
          reason: '${rank.name} did not open for a player who skips lessons',
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });
  });

  group('no grading is added to the input path', () {
    test('the lesson layer never imports the grader', () {
      // The technique set comes from the grade the open already took
      // (`add-rank-progression`), so nothing here needs to solve anything. An
      // import would be how that quietly stopped being true — a solver run has
      // no room inside constraint 2's budget.
      final offenders = <String>[];
      for (final dir in const <String>[
        'lib/features/technique_tutorials/application',
        'lib/features/technique_tutorials/presentation',
        'lib/features/technique_tutorials/data',
      ]) {
        for (final entity in Directory(dir).listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          for (final line in entity.readAsLinesSync()) {
            if (line.trim().startsWith('import ') &&
                line.contains('grader.dart')) {
              offenders.add(entity.path);
            }
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
