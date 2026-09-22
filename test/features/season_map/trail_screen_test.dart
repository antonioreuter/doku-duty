import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/platform_shell/application/clock_provider.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:doku_duty/features/season_map/presentation/trail_node_marker.dart';
import 'package:doku_duty/features/season_map/presentation/trail_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/trail_navigation.dart';

/// The **trail**: what it shows, what it lets the player do, and — mostly —
/// what it refuses to say.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // A pack holding every **rank**, so a **node** always resolves a puzzle.
    await PackRepository(db).installPack(
      packId: 'trail-fixture',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          for (var i = 0; i < 3; i++)
            StoredPuzzle(
              id: '${rank.name}-$i',
              clues: _clues,
              solution: _solution,
              rank: rank,
              seed: i,
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

  Future<void> walkTo(int position) async {
    final seasons = SeasonRepository(db);
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < position; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }
  }

  Finder trailNode(int position) =>
      find.byKey(ValueKey<String>('trail-node-$position'), skipOffstage: false);

  TrailNodeMarker markerAt(WidgetTester tester, int position) =>
      tester.widget<TrailNodeMarker>(trailNode(position));

  Future<TrailNodeMarker> markerAfterScroll(
    WidgetTester tester,
    int position,
  ) async {
    await scrollToNode(tester, position);
    return markerAt(tester, position);
  }

  group('the trail shows a season', () {
    testWidgets('all 42 nodes are built', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byType(TrailScreen), findsOneWidget);
      // Walked rather than asserted in one go, because the list builds lazily
      // and that is deliberate — see `scrollTo`. Every one of the 42 is
      // reachable, in order, and none is missing from the middle.
      for (var position = 1; position <= 42; position++) {
        await scrollToNode(tester, position);
        expect(
          trailNode(position),
          findsOneWidget,
          reason: 'node $position was not on the trail',
        );
      }
    });

    testWidgets('the header names the season and counts the trail', (
      tester,
    ) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Dust Gulch'), findsOneWidget);
      expect(find.text('Trail progress  3 / 42'), findsOneWidget);
    });
  });

  group('node state, and none of it carried by colour alone', () {
    testWidgets('completed, current, and not yet reached', (tester) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(markerAt(tester, 1).state, NodeState.completed);
      expect(markerAt(tester, 3).state, NodeState.completed);
      expect(markerAt(tester, 4).state, NodeState.current);
      expect(markerAt(tester, 5).state, NodeState.notYetReached);
    });

    testWidgets('every state says what it is, in words', (tester) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(markerAt(tester, 1).semanticLabel, contains('Completed'));
      expect(markerAt(tester, 4).semanticLabel, contains('Current'));
      expect(markerAt(tester, 5).semanticLabel, contains('Not yet reached'));
    });

    testWidgets('every node says what type it is, in words', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final season = SeasonOne.season;
      final chest = season.nodes.firstWhere((n) => n.type == NodeType.chest);
      final boss = season.nodes.firstWhere((n) => n.type == NodeType.boss);
      final variant = season.nodes.firstWhere(
        (n) => n.type == NodeType.variant,
      );

      expect(
        (await markerAfterScroll(tester, chest.position)).semanticLabel,
        contains('Chest'),
      );
      expect(
        (await markerAfterScroll(tester, boss.position)).semanticLabel,
        contains('Boss'),
      );
      expect(
        (await markerAfterScroll(tester, variant.position)).semanticLabel,
        contains('Variant puzzle'),
      );
    });

    testWidgets('the current node is drawn larger than the others', (
      tester,
    ) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      Size sizeOf(int position) => tester.getSize(
        find
            .descendant(
              of: find.byKey(
                ValueKey<String>('trail-node-$position'),
                skipOffstage: false,
              ),
              matching: find.byType(Container),
            )
            .first,
      );

      // `docs/pages/screens.html` §4: size carries the state as well as
      // colour, so someone returning after three days finds their place
      // without reading anything.
      expect(sizeOf(4).width, greaterThan(sizeOf(3).width));
      expect(sizeOf(4).width, greaterThan(sizeOf(5).width));
    });
  });

  group('no node is ever called locked (D-108)', () {
    testWidgets('not one player-facing string says it', (tester) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Everything currently built. Walking all 42 is the next test's job;
      // this one is about the header and the labels around them too.
      for (final element in find.byType(Text, skipOffstage: false).evaluate()) {
        final text = (element.widget as Text).data ?? '';
        expect(
          text.toLowerCase(),
          isNot(contains('lock')),
          reason: '"$text" calls a node locked',
        );
      }
    });

    testWidgets('every semantic label avoids it too', (tester) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      for (var position = 1; position <= 42; position++) {
        final marker = await markerAfterScroll(tester, position);
        expect(
          marker.semanticLabel.toLowerCase(),
          isNot(contains('lock')),
          reason: 'node $position is announced as locked',
        );
      }
    });

    testWidgets('a node ahead reads as not yet reached', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        (await markerAfterScroll(tester, 9)).semanticLabel,
        contains('Not yet reached'),
      );
    });
  });

  group('the rank mark is carried onto the trail (D-103)', () {
    testWidgets('a node above the players rank is marked', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // A new player is at Greenhorn, so every **node** naming a harder
      // **rank** carries the mark, and node 1 — a Greenhorn node — does not.
      expect(markerAt(tester, 1).isAbovePlayerRank, isFalse);
      expect(markerAt(tester, 1).semanticLabel, isNot(contains('Above')));

      final deputyNode = SeasonOne.season.nodes.firstWhere(
        (n) => n.rank == Rank.deputy,
      );
      final marker = await markerAfterScroll(tester, deputyNode.position);
      expect(marker.isAbovePlayerRank, isTrue);
      expect(marker.semanticLabel, contains('Above your rank'));
    });

    testWidgets('the mark changes no behaviour — it is a label', (
      tester,
    ) async {
      await walkTo(9);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Node 9 is a Deputy node, above a new player's Greenhorn. It is the
      // **current node**, and it is openable on one tap like any other.
      final marker = await markerAfterScroll(tester, 9);
      expect(marker.isAbovePlayerRank, isTrue);
      expect(marker.state, NodeState.current);
      expect(marker.onTap, isNotNull);
    });
  });

  group('walking the trail', () {
    testWidgets('only the current node and completed ones are tappable', (
      tester,
    ) async {
      await walkTo(4);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(markerAt(tester, 1).onTap, isNotNull, reason: 'completed');
      expect(markerAt(tester, 4).onTap, isNotNull, reason: 'current');
      expect(markerAt(tester, 5).onTap, isNull, reason: 'not yet reached');
      expect(
        (await markerAfterScroll(tester, 42)).onTap,
        isNull,
        reason: 'not yet reached',
      );
    });

    testWidgets('opening a puzzle node opens a puzzle of its rank', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('trail-node-1')));
      await tester.pumpAndSettle();

      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    testWidgets('a rank with nothing left is an absence, not a wall', (
      tester,
    ) async {
      // Every Greenhorn puzzle already solved, so node 1 has nothing to hand
      // over. Constraint 1: that is reported and nothing is blocked.
      final packs = PackRepository(db);
      for (var i = 0; i < 3; i++) {
        await packs.markSolved('${Rank.greenhorn.name}-$i');
      }

      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('trail-node-1')));
      await tester.pumpAndSettle();

      expect(find.byType(PuzzleGrid), findsNothing);
      expect(find.text('Nothing left at this rank for now'), findsOneWidget);
      // Still on the trail, still able to tap it again.
      expect(find.byType(TrailScreen), findsOneWidget);
      expect(markerAt(tester, 1).onTap, isNotNull);
    });
  });

  group('the countdown is read from an injected clock', () {
    // The guard for a bug that shipped twice unnoticed. The header used to call
    // `DateTime.now()` directly, so `trail_golden_test.dart` captured whatever
    // "N days left" read on the afternoon it was generated and failed the next
    // morning — every morning, for the life of the **season**. A golden that
    // fails daily gets ignored, and an ignored golden guards nothing.
    //
    // If anyone reverts the header to the wall clock, these overrides stop
    // having any effect and this test fails.
    Widget appAt(DateTime now) => ProviderScope(
      overrides: [
        flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
        appDatabaseProvider.overrideWith((ref) => db),
        packInstallationProvider.overrideWith(
          (ref) async => PackInstallOutcome.alreadyInstalled,
        ),
        nowProvider.overrideWithValue(() => now),
      ],
      child: const DokuDutyApp(),
    );

    String? daysTextAfter(WidgetTester tester) {
      final finder = find.byKey(const ValueKey<String>('trail-days-remaining'));
      if (finder.evaluate().isEmpty) return null;
      return tester.widget<Text>(finder).data;
    }

    testWidgets('the same day always renders the same countdown', (
      tester,
    ) async {
      await tester.pumpWidget(appAt(SeasonOne.startsAt));
      await tester.pumpAndSettle();
      final first = daysTextAfter(tester);

      await tester.pumpWidget(appAt(SeasonOne.startsAt));
      await tester.pumpAndSettle();

      expect(daysTextAfter(tester), first);
      expect(first, isNotNull);
    });

    testWidgets('a later day renders a smaller countdown', (tester) async {
      await tester.pumpWidget(appAt(SeasonOne.startsAt));
      await tester.pumpAndSettle();
      final atStart = daysTextAfter(tester);

      await tester.pumpWidget(
        appAt(SeasonOne.startsAt.add(const Duration(days: 10))),
      );
      await tester.pumpAndSettle();

      expect(
        daysTextAfter(tester),
        isNot(atStart),
        reason: 'the header ignored the injected clock',
      );
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
