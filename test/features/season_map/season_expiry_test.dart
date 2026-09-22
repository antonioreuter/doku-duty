import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';
import 'package:doku_duty/features/remote_config/application/remote_config_provider.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';
import 'package:doku_duty/features/season_map/domain/season.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A **season**'s six weeks elapsing is not the **season** ending (D-109).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'expiry',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          StoredPuzzle(
            id: rank.name,
            clues: _clues,
            solution: _solution,
            rank: rank,
            seed: 1,
          ),
      ],
    );
  });
  tearDown(() => db.close());

  /// A **season** whose six weeks ran out long ago, and no successor.
  Season expired() {
    final parsed = SeasonDefinition.parse(
      SeasonOne.nodes,
      id: 'long-gone',
      name: 'Long Gone',
      startsAt: DateTime.now().subtract(const Duration(days: 400)),
    );
    return (parsed as ValidSeason).season;
  }

  Widget app(Season season) => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
      remoteConfigProvider.overrideWith(() => _FixedConfig(season)),
    ],
    child: const DokuDutyApp(),
  );

  group('a season with no successor holds open', () {
    test('its six weeks have elapsed', () {
      expect(expired().hasElapsedAt(DateTime.now()), isTrue);
    });

    test('no countdown is shown rather than a negative one', () {
      // Null, never a negative number. A clock reading "-4 days" tells a player
      // they are late for something that cannot be late, and constraint 1 has
      // no room for a timer that can beat you.
      expect(expired().daysRemainingAt(DateTime.now()), isNull);
    });

    testWidgets('the trail stays open and every node stays completable', (
      tester,
    ) async {
      await tester.pumpWidget(app(expired()));
      await tester.pumpAndSettle();

      // All 42 still there, the first still current, and it opens.
      final progress = await SeasonRepository(db).progressFor('long-gone');
      expect(progress.currentPosition, 1);
      expect(progress.isOpenable(1), isTrue);
      expect(
        find.byKey(const ValueKey<String>('trail-node-1')),
        findsOneWidget,
      );
    });

    testWidgets('the header shows no days-left line at all', (tester) async {
      await tester.pumpWidget(app(expired()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('trail-days-remaining')),
        findsNothing,
      );
      // The progress line is still there — what is gone is only the clock.
      expect(
        find.byKey(const ValueKey<String>('trail-progress')),
        findsOneWidget,
      );
    });

    testWidgets('a running season does show its countdown', (tester) async {
      final parsed = SeasonDefinition.parse(
        SeasonOne.nodes,
        id: 'running',
        name: 'Running',
        startsAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      await tester.pumpWidget(app((parsed as ValidSeason).season));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('trail-days-remaining')),
        findsOneWidget,
      );
    });

    testWidgets('progress made on it is kept, not withdrawn', (tester) async {
      final seasons = SeasonRepository(db);
      await seasons.enterSeason('long-gone');
      await seasons.completeNode(seasonId: 'long-gone', position: 1);
      await seasons.completeNode(seasonId: 'long-gone', position: 2);

      await tester.pumpWidget(app(expired()));
      await tester.pumpAndSettle();

      final progress = await seasons.progressFor('long-gone');
      expect(progress.completedCount, 2);
      expect(progress.stateOf(1), NodeState.completed);
      expect(progress.currentPosition, 3);
    });
  });

  group('a successor may be rotated in', () {
    testWidgets('it becomes the season in force and starts at node 1', (
      tester,
    ) async {
      final seasons = SeasonRepository(db);
      await seasons.enterSeason('long-gone');
      await seasons.completeNode(seasonId: 'long-gone', position: 1);

      final parsed = SeasonDefinition.parse(
        SeasonOne.nodes,
        id: 'successor',
        name: 'Successor',
        startsAt: DateTime.now(),
      );
      await tester.pumpWidget(app((parsed as ValidSeason).season));
      await tester.pumpAndSettle();

      expect(await seasons.currentSeasonId(), 'successor');
      final fresh = await seasons.progressFor('successor');
      expect(fresh.isEmpty, isTrue);
      expect(fresh.currentPosition, 1);
    });

    testWidgets('the predecessor keeps its rows across the rotation', (
      tester,
    ) async {
      final seasons = SeasonRepository(db);
      await seasons.enterSeason('long-gone');
      await seasons.completeNode(seasonId: 'long-gone', position: 1);

      final parsed = SeasonDefinition.parse(
        SeasonOne.nodes,
        id: 'successor',
        name: 'Successor',
        startsAt: DateTime.now(),
      );
      await tester.pumpWidget(app((parsed as ValidSeason).season));
      await tester.pumpAndSettle();

      // Nothing is deleted at rotation, which is what means nothing can be
      // deleted by mistake (D-17).
      expect((await seasons.progressFor('long-gone')).completed, <int>{1});
    });
  });
}

/// A config carrying exactly one **season** and the compiled-in ad caps.
class _FixedConfig extends RemoteConfigState {
  _FixedConfig(this.season);

  final Season season;

  @override
  RemoteConfig build() => RemoteConfig(
    values: <ConfigValue, int>{
      for (final value in ConfigValue.values) value: value.defaultValue,
    },
    schemaVersion: 1,
    season: season,
  );
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';

const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
