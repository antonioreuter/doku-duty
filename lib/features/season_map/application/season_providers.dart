import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/presentation/doku_theme.dart';
import '../../persistence/application/database_provider.dart';
import '../../persistence/data/pack_repository.dart';
import '../../puzzle_engine/application/pack_providers.dart';
import '../../remote_config/application/remote_config_provider.dart';
import '../data/season_repository.dart';
import '../domain/node_type.dart';
import '../domain/season.dart';
import '../domain/season_one.dart';
import '../domain/trail_progress.dart';

final seasonRepositoryProvider = Provider<SeasonRepository>(
  (ref) => SeasonRepository(ref.watch(appDatabaseProvider)),
);

/// The **season** in force, resolved once per session.
///
/// Synchronous, and that is the requirement rather than a convenience: the
/// **trail** is the first screen and its 42 **node**s must be on the first
/// frame. A future here would put a spinner where the map goes, on every cold
/// start, for a value that is already in memory.
///
/// **Resolved once and held.** It reads the config at build and does not
/// re-read it, so a **season** published mid-session does not swap the
/// **trail** out from under a player walking it. The published one takes effect
/// at the next launch, which is the next moment nobody is mid-**node**. Using
/// `ref.watch` here instead would rebuild the map the instant a refresh landed
/// — potentially while the player is looking at it, and potentially renumbering
/// the **node** they just finished.
class CurrentSeason extends Notifier<Season> {
  @override
  Season build() {
    // `read`, deliberately, not `watch`. See the note above: this must not
    // rebuild when the config does.
    final published = ref.read(remoteConfigProvider).season;
    // A published **season** has already been through `SeasonDefinition`, so it
    // composes. Null means none was published, or the one that was could not be
    // read — both answered the same way, with the compiled-in trail.
    return published ?? SeasonOne.season;
  }
}

final currentSeasonProvider = NotifierProvider<CurrentSeason, Season>(
  CurrentSeason.new,
);

/// What the player has completed on the **season** in force.
///
/// Read after the first frame, never on the path to it. Until it resolves the
/// **trail** paints its structure with no state applied, which is the same
/// pattern **free play** uses for the **rank** mark.
final trailProgressProvider = FutureProvider<TrailProgress>((ref) async {
  final season = ref.watch(currentSeasonProvider);
  final seasons = ref.watch(seasonRepositoryProvider);
  // Recorded before the progress is read, so the **season** a player is walking
  // is written the first time they see it rather than the first time they
  // finish something. Idempotent, so this costs a query on every launch after
  // the first.
  await seasons.enterSeason(season.id);
  return seasons.progressFor(season.id);
});

/// The puzzle behind a **node**, resolved at open time (D-110).
///
/// Null where the **node**'s **rank** has nothing unsolved left in the
/// **pack**. That is an ordinary absence and the **trail** says so — running
/// out is how a top-up is triggered, not a wall (constraint 1).
///
/// A **chest node** has no puzzle and never reaches here.
final nodePuzzleProvider = FutureProvider.family<StoredPuzzle?, int>((
  ref,
  position,
) async {
  final season = ref.watch(currentSeasonProvider);
  final node = season.nodeAt(position);
  final rank = node.rank;
  if (!node.type.bearsPuzzle || rank == null) return null;

  // Before the first query, not after: the install and this read both start
  // after the first frame, and a **rank** queried mid-install comes back empty.
  await ref.watch(packInstallationProvider.future);

  // A **variant node** plays **killer** and every other **node** classic
  // (D-127). Running out of **killer** is null like any other absence — a
  // classic board in its place would be a **variant node** with no rule.
  final row = await ref
      .watch(packRepositoryProvider)
      .nextUnsolved(
        rank,
        kind: node.type == NodeType.variant
            ? PuzzleKind.killer
            : PuzzleKind.classic,
      );
  if (row == null) return null;
  return StoredPuzzle(
    id: row.id,
    clues: row.clues,
    solution: row.solution,
    rank: row.rank,
    seed: row.seed,
    cages: row.cages,
  );
});

/// How many times this **boss node** has been attempted.
///
/// For display and for `add-trophy-cabinet`. **Nothing consults it to decide
/// whether an attempt may happen** (D-22).
final bossAttemptsProvider = FutureProvider.family<int, int>((
  ref,
  position,
) async {
  final season = ref.watch(currentSeasonProvider);
  return ref
      .watch(seasonRepositoryProvider)
      .bossAttempts(seasonId: season.id, position: position);
});

/// Paints the app in the **season**'s colours.
///
/// Wired as an override rather than as a default inside `design-system`,
/// because the design system is the bottom of the stack and must not depend on
/// a capability five changes above it — the same reason the persisted settings
/// are overridden in `bootstrap.dart` rather than inside either feature.
///
/// What a **season** may repaint is settled by the type it repaints *into*:
/// `SeasonTheme` has a field for each of the two surfaces and none of any kind
/// for a state colour (D-55, constraint 4). A **season** document asking for a
/// different completion green is not refused so much as unable to ask.
final seasonThemeOverride = seasonThemeProvider.overrideWith(
  (ref) => ref.watch(currentSeasonProvider).theme,
);
