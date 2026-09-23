import '../../daily_challenge/domain/daily_calendar.dart';
import '../../daily_challenge/domain/daily_date.dart';
import '../../persistence/data/app_database.dart';
import '../../season_map/data/season_repository.dart';
import '../data/trophy_repository.dart';
import '../domain/award.dart';
import '../domain/award_catalogue.dart';

/// Turns recorded events into **trophy**s.
///
/// **Every method here wraps its write and its minting in one transaction**, so
/// a **trophy** and the thing that earned it commit together or not at all
/// (constraint 9, D-124). A **trophy** without its cause is a lie about what
/// the player did; a cause without its **trophy** is a reward silently
/// withheld, and the player cannot tell that either happened.
///
/// It sits in `trophy_cabinet` rather than in the capabilities it serves so
/// that `season-map` and `daily-challenge` stay unaware of the **cabinet** —
/// the dependency points this way, never back.
class MintingService {
  const MintingService({
    required AppDatabase database,
    required this.seasons,
    required this.trophies,
  }) : _db = database;

  final AppDatabase _db;
  final SeasonRepository seasons;
  final TrophyRepository trophies;

  /// Completes a **node** and mints whatever that earns.
  ///
  /// Two **award**s can fall out of one completion: the **boss node** at this
  /// position, and — if this was the last **node** — closing the **season**
  /// (D-119).
  Future<void> completeNode({
    required String seasonId,
    required String seasonName,
    required int position,
    required int nodeCount,
    required AwardCatalogue catalogue,
  }) {
    return _db.transaction(() async {
      await seasons.completeNode(seasonId: seasonId, position: position);

      for (final award in catalogue.seasonal) {
        if (award.trigger == AwardTrigger.boss &&
            award.nodePosition == position) {
          await trophies.mint(award: award, seasonName: seasonName);
        }
      }

      final progress = await seasons.progressFor(seasonId);
      if (progress.completedCount >= nodeCount) {
        for (final award in catalogue.seasonal) {
          if (award.trigger == AwardTrigger.seasonComplete) {
            await trophies.mint(award: award, seasonName: seasonName);
          }
        }
      }
    });
  }

  /// Mints a **trophy** for [day]'s month if that month is now complete — one
  /// per month, never one for the first month and nothing after.
  ///
  /// Called after a **daily challenge** is recorded, with the **calendar** as
  /// it stands. A month is complete when every one of its days is on the
  /// **calendar** — a day a **streak freeze** bridged does not count, because
  /// the **award** is for turning up (`docs/SPEC.md` §5.3).
  Future<void> afterDailyCompleted({
    required DailyCalendar calendar,
    required DailyDate day,
  }) {
    return _db.transaction(() async {
      var cursor = DailyDate(day.year, day.month, 1);
      while (cursor.month == day.month) {
        if (!calendar.wasCompleted(cursor)) return;
        cursor = cursor.next;
      }

      for (final award in AwardCatalogue.permanent) {
        if (award.trigger == AwardTrigger.perfectMonth) {
          await trophies.mint(
            award: award.forMonth(day.year, day.month),
            seasonName: null,
          );
        }
      }
    });
  }

  /// Mints every **rank** **award** at or below [rank].
  ///
  /// Called after a **solve record**, because a **rank** is derived from the
  /// technique counters a solve moves (D-104). Minting every one at or below
  /// rather than only the newest covers the player who jumps two **rank**s at
  /// once, and idempotence makes the repetition free.
  Future<void> afterRankReached(Rank rank) {
    return _db.transaction(() async {
      for (final award in AwardCatalogue.permanent) {
        if (award.trigger != AwardTrigger.rankReached) continue;
        final named = Rank.values.where((r) => r.name == award.rankName);
        if (named.isEmpty) continue;
        if (named.first.index <= rank.index) {
          await trophies.mint(award: award, seasonName: null);
        }
      }
    });
  }
}
