import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/persistence/data/statistics_repository.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/rank_progression/data/progression_repository.dart';
import 'package:doku_duty/features/technique_tutorials/domain/lesson_catalogue.dart';
import 'package:doku_duty/features/technique_tutorials/presentation/lesson_view.dart';
import 'package:doku_duty/features/trophy_cabinet/data/trophy_repository.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award.dart';
import 'package:doku_duty/features/trophy_cabinet/domain/award_catalogue.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';

/// The **cabinet** as the player meets it.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'cabinet',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          StoredPuzzle(
            id: 'q-${rank.name}',
            clues: _clues,
            solution: _solution,
            rank: rank,
            seed: 1,
          ),
      ],
    );
  });
  tearDown(() => db.close());

  Widget app() => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
    ],
    child: const DokuDutyApp(),
  );

  group('an unearned award is unfiled, never hidden', () {
    testWidgets('a new player sees the awards in place', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      // D-21: the visible gap is the point. Every **award** the **season**
      // offers is on the shelf before any of them is earned.
      final catalogue = AwardCatalogue.forSeason(
        seasonId: 'dust-gulch',
        seasonName: 'Dust Gulch',
      );
      for (final award in catalogue.awards) {
        expect(
          find.byKey(
            ValueKey<String>('cabinet-award-${award.id}'),
            skipOffstage: false,
          ),
          findsOneWidget,
          reason: '${award.id} was hidden rather than unfiled',
        );
      }
    });

    testWidgets('nothing is called missed, failed, expired or locked', (
      tester,
    ) async {
      // Constraint 1. The word is "Unfiled", and the difference between that
      // and a reproach is entirely in the wording.
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      for (final forbidden in <String>[
        'Missed',
        'Failed',
        'Expired',
        'Locked',
      ]) {
        expect(
          find.textContaining(forbidden, skipOffstage: false),
          findsNothing,
          reason: 'the cabinet said "$forbidden"',
        );
      }
      expect(find.text('Unfiled', skipOffstage: false), findsWidgets);
    });

    testWidgets('an earned award fills the place it was unfiled in', (
      tester,
    ) async {
      const award = Award(
        id: 'permanent.rank.sheriff',
        name: 'Sheriff',
        trigger: AwardTrigger.rankReached,
        rankName: 'sheriff',
      );
      await TrophyRepository(db).mint(award: award, seasonName: null);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      expect(
        find.byKey(
          const ValueKey<String>('cabinet-award-permanent.rank.sheriff'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Earned', skipOffstage: false), findsWidgets);
    });

    testWidgets('an earned trophy keeps the name it was minted with', (
      tester,
    ) async {
      // D-126. The **award** was renamed by a later publish after the player
      // earned it. The **trophy** is a record of what they earned, so it keeps
      // the name on the day — a rename changes only what is still on offer.
      await TrophyRepository(db).mint(
        award: const Award(
          id: 'dust-gulch.boss.22',
          name: 'The name on the day',
          trigger: AwardTrigger.boss,
          seasonId: 'dust-gulch',
          nodePosition: 22,
        ),
        seasonName: 'Dust Gulch',
      );

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      final entry = find.byKey(
        const ValueKey<String>('cabinet-award-dust-gulch.boss.22'),
        skipOffstage: false,
      );
      expect(entry, findsOneWidget);
      expect(
        find.descendant(
          of: entry,
          matching: find.text('The name on the day'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('each perfect month fills the place the offer held', (
      tester,
    ) async {
      // One **trophy** per month (`docs/SPEC.md` §5.3). They take the offer's
      // place on the shelf rather than trailing at the bottom as strays, and
      // the offer stops reading as unfiled once a month has been earned.
      final offer = AwardCatalogue.permanent.firstWhere((a) => a.isRepeatable);
      for (final month in <int>[4, 5]) {
        await TrophyRepository(
          db,
        ).mint(award: offer.forMonth(2026, month), seasonName: null);
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      Finder entry(String id) => find.byKey(
        ValueKey<String>('cabinet-award-$id'),
        skipOffstage: false,
      );
      expect(entry('${offer.id}.2026-04'), findsOneWidget);
      expect(entry('${offer.id}.2026-05'), findsOneWidget);
      expect(entry(offer.id), findsNothing);
      expect(
        find.text('April 2026, without a gap', skipOffstage: false),
        findsOneWidget,
      );

      // In the offer's place: after the season's awards, before the ranks.
      final april = tester.getTopLeft(entry('${offer.id}.2026-04')).dy;
      final sheriff = tester.getTopLeft(entry('permanent.rank.sheriff')).dy;
      expect(april, lessThan(sheriff));
    });
  });

  group('a trophy outlives its season', () {
    testWidgets('one from a rotated season keeps its name and territory', (
      tester,
    ) async {
      // Nothing in the season in force declares this award — its document is
      // gone. The **trophy** was minted with the name and the territory on it,
      // which is the whole reason it was minted (D-124).
      await TrophyRepository(db).mint(
        award: const Award(
          id: 'copper-hollow.closed',
          name: 'Copper Hollow, closed',
          trigger: AwardTrigger.seasonComplete,
          seasonId: 'copper-hollow',
        ),
        seasonName: 'Copper Hollow',
      );

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      expect(
        find.text('Copper Hollow, closed', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Copper Hollow', skipOffstage: false),
        findsWidgets,
      );
    });
  });

  group('statistics are read, not recounted', () {
    testWidgets('a player who has solved nothing reads zero', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      expect(
        find.byKey(
          const ValueKey<String>('cabinet-stat-puzzles-solved'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      // Zero is stated rather than hidden — a gap reads as a number that
      // failed to load.
      expect(find.text('0', skipOffstage: false), findsWidgets);
    });

    testWidgets('the cabinet keeps no counter of its own', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      // Every number on screen comes from `lifetime_stats` and
      // `technique_stats`. There is no third table for the two to disagree
      // with.
      final tables = db.allTables.map((t) => t.actualTableName).toList();
      expect(
        tables.where((t) => t.contains('cabinet') || t.contains('statistic')),
        isEmpty,
      );
    });
  });

  group('the lessons live here now', () {
    testWidgets('the cabinet opens the lesson list', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      // The row is the last thing on the screen and the list builds lazily, so
      // it does not exist until the player scrolls to it — which is what this
      // does rather than reaching past the fold with `skipOffstage`.
      final row = find.byKey(const ValueKey<String>('cabinet-open-lessons'));
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(row, findsOneWidget);
    });

    testWidgets('every lesson replays from here and moves no progression', (
      tester,
    ) async {
      // A player mid-ladder, so there is something for a replay to disturb. A
      // **lesson** is teaching, not an achievement (D-106): replaying every
      // one of them, including techniques never met, leaves the **rank**, the
      // **technique unlock**s, the statistics and the **cabinet** itself
      // exactly where they were.
      final progression = ProgressionRepository(db);
      await progression.record(
        puzzleId: 'q-sheriff',
        techniquesRequired: <Technique>{Technique.nakedPair},
        timeTaken: const Duration(minutes: 3),
        attempt: Attempt.fresh,
      );
      final rankBefore = await progression.playerRank();
      final unlockedBefore = await progression.unlockedTechniques();
      final statsBefore = await StatisticsRepository(db).lifetime();
      final trophiesBefore = await TrophyRepository(db).earnedIds();

      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await goToCabinet(tester);

      final open = find.byKey(const ValueKey<String>('cabinet-open-lessons'));
      await tester.scrollUntilVisible(
        open,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(open);
      await tester.pumpAndSettle();

      for (final lesson in lessonCatalogue) {
        final row = find.byKey(ValueKey<String>('lesson-row-${lesson.id}'));
        await tester.scrollUntilVisible(
          row,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(row);
        await tester.pumpAndSettle();

        expect(
          find.byType(LessonView),
          findsOneWidget,
          reason: '${lesson.id} did not replay',
        );
        expect(find.text(lesson.steps.first.text), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
        await tester.pumpAndSettle();
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(LessonView), findsNothing);
      }

      expect(await progression.playerRank(), rankBefore);
      expect(await progression.unlockedTechniques(), unlockedBefore);
      final statsAfter = await StatisticsRepository(db).lifetime();
      expect(statsAfter.puzzlesSolved, statsBefore.puzzlesSolved);
      expect(statsAfter.perfectSolves, statsBefore.perfectSolves);
      expect(await TrophyRepository(db).earnedIds(), trophiesBefore);
    });

    testWidgets('the settings route is gone, so the list has one home', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('open-lessons'), skipOffstage: false),
        findsNothing,
        reason: 'the lesson list still has two homes',
      );
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
