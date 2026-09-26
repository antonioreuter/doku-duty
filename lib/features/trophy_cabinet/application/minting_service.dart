import '../../daily_challenge/application/daily_service.dart';
import '../../daily_challenge/domain/daily_calendar.dart';
import '../../daily_challenge/domain/daily_date.dart';
import '../../persistence/data/app_database.dart';
import '../../season_map/data/season_repository.dart';
import '../../season_map/domain/node_type.dart';
import '../../stamps/data/stamp_repository.dart';
import '../../stamps/domain/earning.dart';
import '../../stamps/domain/earning_rules.dart';
import '../data/trophy_repository.dart';
import '../domain/award.dart';
import '../domain/award_catalogue.dart';

/// Turns recorded events into **trophy**s and **stamp** **earning**s.
///
/// **Every method here wraps its write and its minting in one transaction**, so
/// a **trophy** or an **earning** and the thing that earned it commit together
/// or not at all (constraint 9, D-124, D-133). A **trophy** without its cause is a lie about what
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
    required this.daily,
    required this.stamps,
  }) : _db = database;

  final AppDatabase _db;
  final SeasonRepository seasons;
  final TrophyRepository trophies;
  final DailyService daily;
  final StampRepository stamps;

  /// Completes a **node** and mints whatever that earns, returning the
  /// **earning**s it newly wrote.
  ///
  /// Two **award**s can fall out of one completion: the **boss node** at this
  /// position, and — if this was the last **node** — closing the **season**
  /// (D-119). A **chest node** or a **boss node** also pays its **stamp**s
  /// (D-66); [type] is what tells them apart.
  Future<List<Earning>> completeNode({
    required String seasonId,
    required String seasonName,
    required int position,
    required NodeType type,
    required int nodeCount,
    required AwardCatalogue catalogue,
  }) {
    return _db.transaction(() async {
      await seasons.completeNode(seasonId: seasonId, position: position);
      final earned = await stamps.earn(
        EarningRules.earningsFor(
          Completion(
            node: NodeFacts(seasonId: seasonId, position: position, type: type),
          ),
        ),
      );

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
      return earned;
    });
  }

  /// Records a **daily challenge** as completed on [day] and mints whatever
  /// that earns, returning the **earning**s it newly wrote.
  ///
  /// The day, its **stamp**s and the month's **trophy** commit together, and —
  /// called from the board sink inside the **solve record**'s transaction —
  /// with the solve as well. Drift nests this transaction into that one.
  ///
  /// The `DailyCompletion` is the signal the **daily challenge** promised for
  /// whoever else is counting (`daily-challenge` spec): it is read here, where
  /// both of its consumers live, and its **streak** is the one the **calendar**
  /// holds after this day — so the seventh-day **earning** is never recomputed
  /// from a second read that could disagree.
  Future<List<Earning>> completeDay(DatedDay day) {
    return _db.transaction(() async {
      final completion = await daily.complete(day);
      final earned = await stamps.earn(
        EarningRules.earningsFor(
          Completion(
            day: DayFacts(date: completion.date, streak: completion.streak),
          ),
        ),
      );
      await _mintPerfectMonth(
        calendar: await daily.repository.calendar(),
        day: day.date,
      );
      return earned;
    });
  }

  /// What a **solve record** earns, returning the **earning**s newly written:
  /// the **rank** **trophy**s the player now holds, and the perfect-solve
  /// **stamp**s.
  ///
  /// [isFirstSolve] is whether this completion wrote the puzzle's **solve
  /// record**. Only that one can be the perfect solve (D-133) — a clean replay
  /// of a board first solved with a **mistake** is the same puzzle — while the
  /// **rank** **trophy**s mint on every solve, so a player who held a **rank**
  /// before its **trophy** could mint receives it on their next one.
  Future<List<Earning>> afterSolve({
    required String puzzleId,
    required bool isFirstSolve,
    required bool isPerfect,
    required Rank rank,
  }) {
    return _db.transaction(() async {
      await afterRankReached(rank);
      return stamps.earn(
        EarningRules.earningsFor(
          Completion(
            solve: SolveFacts(
              puzzleId: puzzleId,
              isFirstSolve: isFirstSolve,
              isPerfect: isPerfect,
            ),
          ),
        ),
      );
    });
  }

  /// Mints a **trophy** for [day]'s month if that month is now complete — one
  /// per month, never one for the first month and nothing after.
  ///
  /// Private, and reached only through [completeDay], because a public
  /// version was exactly how the perfect month went unminted: it was tested,
  /// correct, and called by nothing. A month is complete when every one of its
  /// days is on the **calendar** — a day a **streak freeze** bridged does not
  /// count, because the **award** is for turning up (`docs/SPEC.md` §5.3).
  Future<void> _mintPerfectMonth({
    required DailyCalendar calendar,
    required DailyDate day,
  }) async {
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
