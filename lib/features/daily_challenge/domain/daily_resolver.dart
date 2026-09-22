import '../../puzzle_engine/domain/rank.dart';
import 'daily_board_source.dart';
import 'daily_date.dart';
import 'daily_schedule.dart';

/// Turns a date into the board the **daily challenge** offers.
///
/// Every branch here ends in a board wherever one exists at all. That is the
/// shape constraint 1 asks for: running out of schedule, a publish naming a
/// puzzle this install lacks, or a **pack** with nothing at today's **rank**
/// are all ordinary absences to route around, never conditions to report.
class DailyResolver {
  const DailyResolver({required this.schedule, required this.source});

  final DailySchedule schedule;
  final DailyBoardSource source;

  /// Today's board, or null only when nothing is installed at all.
  Future<DailyBoard?> boardFor(DailyDate date) async {
    final resolution = schedule.resolve(date);

    if (resolution is NamedPuzzle) {
      final named = await source.byId(resolution.puzzleId);
      if (named != null) return named;
      // The schedule named something this install does not have — an older
      // **pack**, or a publish that ran ahead of one. Falling through is the
      // same answer as an uncovered date (D-115).
    }

    return _derived(date);
  }

  Future<DailyBoard?> _derived(DailyDate date) async {
    final seed = DailySchedule.seedFor(date);
    final wanted = DailySchedule.rankFor(date);

    final atRank = await source.byRankAndSeed(wanted, seed);
    if (atRank != null) return atRank;

    // The **pack** has nothing at today's **rank**. Widen outward to the
    // nearest **rank** that can supply one rather than offering no **daily
    // challenge**: a missing rank is the **pack**'s problem and constraint 1
    // says the player does not pay for it.
    for (final rank in _byDistanceFrom(wanted)) {
      final board = await source.byRankAndSeed(rank, seed);
      if (board != null) return board;
    }

    // Nothing installed at any **rank**. There is no puzzle in the app to
    // offer, which is an absence rather than a fault.
    return null;
  }

  /// Every other **rank**, closest to [wanted] first, easier side winning ties.
  ///
  /// Easier first because a board below the day's **rank** is disappointing and
  /// a board above it can be unsolvable for the player looking at it.
  static Iterable<Rank> _byDistanceFrom(Rank wanted) {
    final others = Rank.values.where((r) => r != wanted).toList()
      ..sort((a, b) {
        final da = (a.index - wanted.index).abs();
        final db = (b.index - wanted.index).abs();
        if (da != db) return da.compareTo(db);
        return a.index.compareTo(b.index);
      });
    return others;
  }
}
