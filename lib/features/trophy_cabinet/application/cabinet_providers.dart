import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../daily_challenge/application/daily_providers.dart';
import '../../persistence/application/database_provider.dart';
import '../../remote_config/application/remote_config_provider.dart';
import '../../season_map/application/season_providers.dart';
import '../../stamps/application/stamp_providers.dart';
import '../../persistence/data/app_database.dart';
import '../data/statistics_repository.dart';
import '../data/trophy_repository.dart';
import '../domain/award.dart';
import '../domain/award_catalogue.dart';
import 'minting_service.dart';

final trophyRepositoryProvider = Provider<TrophyRepository>(
  (ref) => TrophyRepository(ref.watch(appDatabaseProvider)),
);

/// The **award**s on offer: the **season** in force's, plus the permanent ones.
///
/// Reads the `awards` key of the published **season** where there is one and
/// falls back to the compiled-in list otherwise (D-125) — which is the ordinary
/// case, not a degraded one.
final awardCatalogueProvider = Provider<AwardCatalogue>((ref) {
  final season = ref.watch(currentSeasonProvider);
  final config = ref.watch(remoteConfigProvider);

  return AwardCatalogue.forSeason(
    seasonId: season.id,
    seasonName: season.name,
    published: Award.listFromJson(config.rawSeasonAwards, seasonId: season.id),
  );
});

final mintingServiceProvider = Provider<MintingService>(
  (ref) => MintingService(
    database: ref.watch(appDatabaseProvider),
    seasons: ref.watch(seasonRepositoryProvider),
    trophies: ref.watch(trophyRepositoryProvider),
    daily: ref.watch(dailyServiceProvider),
    stamps: ref.watch(stampRepositoryProvider),
  ),
);

/// Every **trophy** earned, newest first.
final earnedTrophiesProvider = FutureProvider<List<Trophy>>(
  (ref) => ref.watch(trophyRepositoryProvider).earned(),
);

/// The ids already earned, for telling an **unfiled** **award** from a filed
/// one.
final earnedIdsProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(trophyRepositoryProvider).earnedIds(),
);

final statisticsRepositoryProvider = Provider<StatisticsRepository>(
  (ref) => StatisticsRepository(ref.watch(appDatabaseProvider)),
);

/// Lifetime and per-technique counts, read from what already exists.
final cabinetStatisticsProvider = FutureProvider<CabinetStatistics>(
  (ref) => ref.watch(statisticsRepositoryProvider).read(),
);
