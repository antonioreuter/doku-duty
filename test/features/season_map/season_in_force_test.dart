import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/remote_config/application/remote_config_provider.dart';
import 'package:doku_duty/features/remote_config/domain/config_value.dart';
import 'package:doku_duty/features/remote_config/domain/remote_config.dart';
import 'package:doku_duty/features/season_map/application/season_providers.dart';
import 'package:doku_duty/features/season_map/domain/season.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which **season** the player is walking, and when that is allowed to change.
void main() {
  late AppDatabase db;

  ProviderContainer containerWith(RemoteConfig config) {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    container.read(remoteConfigProvider.notifier).apply(config);
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('with no configuration ever fetched', () {
    test('the compiled-in season is in force', () {
      final container = containerWith(RemoteConfig.defaults());
      final season = container.read(currentSeasonProvider);
      expect(season.id, SeasonOne.id);
      expect(season.name, SeasonOne.name);
    });

    test('all 42 nodes are there and every one is a real node', () {
      final container = containerWith(RemoteConfig.defaults());
      final season = container.read(currentSeasonProvider);
      expect(season.nodes, hasLength(42));
      for (var position = 1; position <= 42; position++) {
        expect(season.nodeAt(position).position, position);
      }
    });

    test('the player stands at node 1 and can open it', () async {
      final container = containerWith(RemoteConfig.defaults());
      final progress = await container.read(trailProgressProvider.future);
      expect(progress.currentPosition, 1);
      expect(progress.isOpenable(1), isTrue);
    });

    test('reading the season needs no await', () {
      // The signature is the requirement. A future here would put a spinner
      // where the map goes on every cold start, for a value already in memory.
      final container = containerWith(RemoteConfig.defaults());
      expect(container.read(currentSeasonProvider), isA<Season>());
    });
  });

  group('with a season published', () {
    final published = _publishedSeason();

    test('it is the season in force', () {
      final container = containerWith(
        RemoteConfig(
          values: const <ConfigValue, int>{},
          schemaVersion: 1,
          season: published,
        ),
      );
      expect(container.read(currentSeasonProvider).id, 'copper-hollow');
    });

    test('entering it records it against the player', () async {
      final container = containerWith(
        RemoteConfig(
          values: const <ConfigValue, int>{},
          schemaVersion: 1,
          season: published,
        ),
      );
      await container.read(trailProgressProvider.future);
      final seasons = container.read(seasonRepositoryProvider);
      expect(await seasons.currentSeasonId(), 'copper-hollow');
    });
  });

  group('a season arriving mid-play does not disturb one in progress', () {
    test('the trail does not swap under a player walking it', () async {
      final container = containerWith(RemoteConfig.defaults());
      expect(container.read(currentSeasonProvider).id, SeasonOne.id);

      // The player is three nodes in.
      final seasons = container.read(seasonRepositoryProvider);
      await container.read(trailProgressProvider.future);
      for (final position in <int>[1, 2, 3]) {
        await seasons.completeNode(seasonId: SeasonOne.id, position: position);
      }
      // What the real completion path does, and what D-105 exists to remember:
      // the read is cached and the screen holding it stays mounted, so the
      // write has to say so. Without this the assertion below reads zero.
      container.invalidate(trailProgressProvider);

      // A refresh lands mid-session carrying a different season.
      container
          .read(remoteConfigProvider.notifier)
          .apply(
            RemoteConfig(
              values: const <ConfigValue, int>{},
              schemaVersion: 2,
              season: _publishedSeason(),
            ),
          );

      // The season in force is unchanged, and so is where the player stands.
      // The published one takes effect at the next launch, which is the next
      // moment nobody is mid-node.
      expect(container.read(currentSeasonProvider).id, SeasonOne.id);
      final progress = await container.read(trailProgressProvider.future);
      expect(progress.completedCount, 3);
      expect(progress.currentPosition, 4);
    });

    test('the next launch picks the published season up', () async {
      final config = RemoteConfig(
        values: const <ConfigValue, int>{},
        schemaVersion: 2,
        season: _publishedSeason(),
      );
      // A fresh container is a fresh launch.
      final relaunched = containerWith(config);
      expect(relaunched.read(currentSeasonProvider).id, 'copper-hollow');

      // And it starts at its own first node, carrying nothing over (D-17).
      final progress = await relaunched.read(trailProgressProvider.future);
      expect(progress.isEmpty, isTrue);
      expect(progress.currentPosition, 1);
    });

    test('rotating back finds the old seasons progress still there', () async {
      final first = containerWith(RemoteConfig.defaults());
      final seasons = first.read(seasonRepositoryProvider);
      await first.read(trailProgressProvider.future);
      await seasons.completeNode(seasonId: SeasonOne.id, position: 1);

      final rotated = containerWith(
        RemoteConfig(
          values: const <ConfigValue, int>{},
          schemaVersion: 2,
          season: _publishedSeason(),
        ),
      );
      expect(
        (await rotated.read(trailProgressProvider.future)).isEmpty,
        isTrue,
      );

      // Rotation deletes nothing, so the predecessor's rows are still there.
      final back = containerWith(RemoteConfig.defaults());
      final progress = await back.read(trailProgressProvider.future);
      expect(progress.completed, <int>{1});
    });
  });
}

/// A valid **season** that is not the compiled-in one.
Season _publishedSeason() {
  final parsed = SeasonDefinition.parse(
    SeasonOne.nodes,
    id: 'copper-hollow',
    name: 'Copper Hollow',
    startsAt: DateTime.utc(2026, 11, 2),
  );
  return (parsed as ValidSeason).season;
}
