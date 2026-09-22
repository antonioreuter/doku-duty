import '../../puzzle_engine/domain/rank.dart';
import 'daily_date.dart';

/// What the **daily challenge** should offer on a given date.
sealed class DailyResolution {
  const DailyResolution();
}

/// The schedule named a puzzle. This is the ordinary case and the one that
/// keeps the capability's promise: every player on this date gets this board.
class NamedPuzzle extends DailyResolution {
  const NamedPuzzle(this.puzzleId);

  final String puzzleId;

  @override
  bool operator ==(Object other) =>
      other is NamedPuzzle && other.puzzleId == puzzleId;

  @override
  int get hashCode => puzzleId.hashCode;

  @override
  String toString() => 'NamedPuzzle($puzzleId)';
}

/// No entry covered the date, so the board is picked out of the installed
/// **pack** by a seed fixed by that date (D-115).
///
/// Sameness across players is what is given up here, and it is given up
/// knowingly: a player this far past the schedule has been offline for months,
/// there are no leaderboards in v1, and the alternative is withholding the
/// **daily challenge** from exactly the player with least else to do.
class DerivedFromPack extends DailyResolution {
  const DerivedFromPack({required this.rank, required this.seed});

  /// From the weekly ramp, so the fallback keeps the curve (D-116).
  final Rank rank;

  /// A function of the date alone. Stable across restarts and reinstalls.
  final int seed;

  @override
  bool operator ==(Object other) =>
      other is DerivedFromPack && other.rank == rank && other.seed == seed;

  @override
  int get hashCode => Object.hash(rank, seed);

  @override
  String toString() => 'DerivedFromPack(${rank.name}, $seed)';
}

/// The published list of which puzzle is which day's.
///
/// Absent is valid and common, exactly as it is for the **season** document —
/// a schedule that covers nothing still resolves every date, through the
/// fallback.
class DailySchedule {
  DailySchedule({required Map<DailyDate, String> entries})
    : _entries = Map<DailyDate, String>.unmodifiable(entries);

  DailySchedule.empty() : _entries = const <DailyDate, String>{};

  /// Reads a published document, refusing anything malformed into the empty
  /// schedule rather than throwing.
  ///
  /// **Refusing, never throwing**, and per-day rather than per-document: one
  /// bad row loses that day and no other. A publish mistake degrades to the
  /// derived board, which is the same thing no publish at all does, so there is
  /// no failure here a player can be shown.
  factory DailySchedule.fromJson(Object? document) {
    if (document is! Map<String, Object?>) return DailySchedule.empty();
    final days = document['days'];
    if (days is! List) return DailySchedule.empty();

    final entries = <DailyDate, String>{};
    for (final day in days) {
      if (day is! Map) continue;
      final date = day['date'];
      final puzzleId = day['puzzle_id'];
      if (date is! String || puzzleId is! String || puzzleId.isEmpty) continue;
      try {
        entries[DailyDate.parse(date)] = puzzleId;
      } on FormatException {
        continue;
      }
    }
    return DailySchedule(entries: entries);
  }

  final Map<DailyDate, String> _entries;

  bool get isEmpty => _entries.isEmpty;

  bool covers(DailyDate date) => _entries.containsKey(date);

  /// Today's board, by whichever route is available.
  DailyResolution resolve(DailyDate date) {
    final named = _entries[date];
    if (named != null) return NamedPuzzle(named);
    return DerivedFromPack(rank: rankFor(date), seed: seedFor(date));
  }

  /// The weekly ramp (D-116): easier early in the week, hardest at its end.
  ///
  /// Monday sits at Greenhorn so a new player has a day they can finish —
  /// a **streak** nobody can start is not a habit, it is a rebuke. Saturday
  /// and Sunday carry the hard boards, where there is time for one.
  static Rank rankFor(DailyDate date) => switch (date.weekday) {
    DateTime.monday => Rank.greenhorn,
    DateTime.tuesday => Rank.deputy,
    DateTime.wednesday => Rank.deputy,
    DateTime.thursday => Rank.sheriff,
    DateTime.friday => Rank.marshal,
    DateTime.saturday => Rank.ranger,
    _ => Rank.legend,
  };

  /// A seed fixed by the date and nothing else.
  ///
  /// Deliberately *not* a hash of the device, the install, or the clock: the
  /// same date must pick the same board after a reinstall, or a player's
  /// **calendar** would disagree with itself.
  static int seedFor(DailyDate date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
