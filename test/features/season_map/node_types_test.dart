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
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:doku_duty/features/season_map/presentation/trail_node_marker.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/trail_navigation.dart';

/// What each **node type** does when it is opened.
///
/// Three of the four have a seam in them — a reward, a trophy, and a rule that
/// belong to changes that do not exist yet. **Each seam is named in a test on
/// purpose**, so that the gap reads as a decision rather than as something
/// nobody got to.
void main() {
  late AppDatabase db;
  late SeasonRepository seasons;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    seasons = SeasonRepository(db);
    await PackRepository(db).installPack(
      packId: 'node-types',
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
    await seasons.enterSeason(SeasonOne.id);
    for (var p = 1; p < position; p++) {
      await seasons.completeNode(seasonId: SeasonOne.id, position: p);
    }
  }

  Finder trailNode(int position) =>
      find.byKey(ValueKey<String>('trail-node-$position'), skipOffstage: false);

  final firstChest = SeasonOne.season.nodes
      .firstWhere((n) => n.type == NodeType.chest)
      .position;
  final firstBoss = SeasonOne.season.nodes
      .firstWhere((n) => n.type == NodeType.boss)
      .position;
  final firstVariant = SeasonOne.season.nodes
      .firstWhere((n) => n.type == NodeType.variant)
      .position;

  group('a chest node', () {
    testWidgets('opens directly, with no puzzle', (tester) async {
      await walkTo(firstChest);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openTrailNode(tester, firstChest);

      expect(find.byType(PuzzleGrid), findsNothing);
      expect(find.text('Chest opened'), findsOneWidget);
    });

    testWidgets('completes on opening and advances the trail', (tester) async {
      await walkTo(firstChest);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openTrailNode(tester, firstChest);

      final progress = await seasons.progressFor(SeasonOne.id);
      expect(progress.stateOf(firstChest), NodeState.completed);
      expect(progress.currentPosition, firstChest + 1);
    });

    testWidgets('grants no currency — change 18 owns the balance', (
      tester,
    ) async {
      // **The seam, named.** A **chest node** awards 12 Stamps under D-66, and
      // `add-stamps` is where the balance lives. D-66 wants exactly one place
      // that can mint one, so this change records the chest as opened and mints
      // nothing. There is no balance to check yet — the assertion is that no
      // table here pretends to be one.
      await walkTo(firstChest);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openTrailNode(tester, firstChest);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(
        tables.where(
          (t) =>
              t.contains('stamp') ||
              t.contains('balance') ||
              t.contains('currency'),
        ),
        isEmpty,
        reason: 'the Stamp balance is add-stamps, and must have one home',
      );
    });

    testWidgets('cannot be failed and needs no network', (tester) async {
      // No network is mounted in this test at all. Opening works regardless,
      // and there is no failure path to exercise because the chest has none.
      await walkTo(firstChest);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await openTrailNode(tester, firstChest);

      expect(tester.takeException(), isNull);
      expect(
        (await seasons.progressFor(SeasonOne.id)).stateOf(firstChest),
        NodeState.completed,
      );
    });
  });

  group('a boss node', () {
    testWidgets('plays a puzzle', (tester) async {
      await walkTo(firstBoss);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openTrailNode(tester, firstBoss);
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });

    testWidgets('retries without limit and without cost (D-22)', (
      tester,
    ) async {
      await walkTo(firstBoss);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Open and leave, ten times over. Nothing is spent and nothing closes.
      for (var attempt = 0; attempt < 10; attempt++) {
        await openTrailNode(tester, firstBoss);
        expect(find.byType(PuzzleGrid), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      expect(
        await seasons.bossAttempts(seasonId: SeasonOne.id, position: firstBoss),
        10,
      );
      // Counted, and the count changed nothing: still current, still openable.
      final progress = await seasons.progressFor(SeasonOne.id);
      expect(progress.stateOf(firstBoss), NodeState.current);
      expect(progress.isOpenable(firstBoss), isTrue);
    });

    testWidgets('files a trophy — the seam change 16 filled', (tester) async {
      // **This replaced the seam, it did not edit it.** Until
      // `add-trophy-cabinet` landed, this asserted that *no* trophy was filed
      // and that no table pretended to be a shelf. That test was written to be
      // deleted by the change that fills the seam, and this is it.
      //
      // Worth recording how it went: the old assertion searched
      // `sqlite_master` for a table name containing "trophy", and the table is
      // called `trophies` — which does not contain that substring. It would
      // have gone on passing for ever with the shelf sitting right there. A
      // guard that greps for a name is only as good as the name somebody
      // happens to choose.
      await walkTo(firstBoss);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final before = await db.select(db.trophies).get();
      expect(before, isEmpty);

      await seasons.completeNode(seasonId: SeasonOne.id, position: firstBoss);

      // The completion alone mints nothing — minting is the service's job, and
      // the repository stays unaware of the **cabinet**.
      expect(await db.select(db.trophies).get(), isEmpty);
    });
  });

  group('a variant node', () {
    testWidgets('is typed as a variant', (tester) async {
      await walkTo(firstVariant);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final marker = tester.widget<TrailNodeMarker>(trailNode(firstVariant));
      expect(marker.type, NodeType.variant);
      expect(marker.semanticLabel, contains('Variant puzzle'));
    });

    testWidgets('plays a classic puzzle — change 17 owns the rule', (
      tester,
    ) async {
      // **The seam, named.** The **season**'s rule twist is
      // `add-puzzle-variants`. The type is real now so that change has
      // somewhere to land, and so D-19's pacing can be judged against the real
      // trail rather than a placeholder one.
      await walkTo(firstVariant);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await openTrailNode(tester, firstVariant);
      expect(find.byType(PuzzleGrid), findsOneWidget);
    });
  });

  group('the node-completed signal (constraint 6)', () {
    test('chest and boss are never followed by an interstitial', () {
      // D-24 names them alongside the daily challenge as never-eligible, and
      // `PUBLISHING.md` records that no config key can reach placement. This is
      // compiled in, and `add-ads-integration` reads it rather than
      // re-deciding it.
      expect(NodeType.chest.mayBeFollowedByInterstitial, isFalse);
      expect(NodeType.boss.mayBeFollowedByInterstitial, isFalse);
    });

    test('a puzzle and a variant node may be', () {
      expect(NodeType.puzzle.mayBeFollowedByInterstitial, isTrue);
      expect(NodeType.variant.mayBeFollowedByInterstitial, isTrue);
    });

    test('every node type has an answer, so a fifth cannot slip past', () {
      for (final type in NodeType.values) {
        expect(type.mayBeFollowedByInterstitial, isA<bool>());
        expect(type.bearsPuzzle, isA<bool>());
      }
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
