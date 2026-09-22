import 'daily_date.dart';

/// What a day on the **calendar** shows.
enum DayState {
  completed,

  /// Missed, but bridged by a **streak freeze** — the run continued through it.
  frozen,

  missed,

  /// Ahead of today. Not missed; simply not yet.
  notYet,

  /// Before the player's first recorded day.
  ///
  /// **Not a miss**, and the distinction is constraint 1 rather than pedantry.
  /// A player installing on the 21st would otherwise open the **calendar** to
  /// twenty "missed" days — the app opening the relationship by telling them
  /// they have already failed at something they could not have done. Nothing is
  /// claimed about a day before they arrived.
  untracked,
}

/// The days the **daily challenge** was completed, and the days a **streak
/// freeze** covered.
///
/// **Two sets, and no number.** The **streak** is derived from these on demand
/// (`docs/TECH_STACK.md` §3b): sets union cleanly when two devices meet, a
/// count does not, and a stored count can drift from the days it claims to
/// describe with nothing to detect it. Deriving costs a walk of a few dozen
/// entries and removes an entire class of conflict.
class DailyCalendar {
  DailyCalendar({
    required Set<DailyDate> completed,
    Set<DailyDate> frozen = const <DailyDate>{},
  }) : completed = Set<DailyDate>.unmodifiable(completed),
       frozen = Set<DailyDate>.unmodifiable(frozen);

  DailyCalendar.empty()
    : completed = const <DailyDate>{},
      frozen = const <DailyDate>{};

  final Set<DailyDate> completed;
  final Set<DailyDate> frozen;

  bool wasCompleted(DailyDate date) => completed.contains(date);

  bool wasFrozen(DailyDate date) => frozen.contains(date);

  /// Merges two devices' records. Union, never last-write-wins.
  DailyCalendar union(DailyCalendar other) => DailyCalendar(
    completed: <DailyDate>{...completed, ...other.completed},
    frozen: <DailyDate>{...frozen, ...other.frozen},
  );

  DailyCalendar withCompleted(DailyDate date) =>
      DailyCalendar(completed: <DailyDate>{...completed, date}, frozen: frozen);

  DailyCalendar withFrozen(Iterable<DailyDate> dates) => DailyCalendar(
    completed: completed,
    frozen: <DailyDate>{...frozen, ...dates},
  );

  /// The earliest day on record, or null if the player has never played.
  DailyDate? get firstRecorded {
    DailyDate? earliest;
    for (final date in <DailyDate>{...completed, ...frozen}) {
      if (earliest == null || date < earliest) earliest = date;
    }
    return earliest;
  }

  DayState stateOf(DailyDate date, {DailyDate? today}) {
    if (completed.contains(date)) return DayState.completed;
    if (frozen.contains(date)) return DayState.frozen;
    if (today != null && date > today) return DayState.notYet;

    // Before they ever played, nothing was missed (constraint 1). A player who
    // has never played at all has missed nothing anywhere.
    final first = firstRecorded;
    if (first == null || date < first) return DayState.untracked;

    return DayState.missed;
  }

  /// The run of consecutive days ending at or just before [today].
  ///
  /// **Yesterday is allowed to be the last day of the run.** Counting from
  /// today alone would show a player zero every morning until they played,
  /// which reads as having lost the **streak** rather than as not having
  /// extended it yet — and that is the moment somebody gives up on a
  /// hundred-day run they still have.
  ///
  /// Days after [today] are skipped rather than counted or treated as breaks.
  /// A clock wound forward and back leaves them behind, and D-117's rule is
  /// that a wrong clock never costs a **streak**.
  int streakOn(DailyDate today) {
    var cursor = today;
    if (!_counts(cursor)) {
      cursor = cursor.previous;
      if (!_counts(cursor)) return 0;
    }

    var run = 0;
    while (_counts(cursor)) {
      run++;
      cursor = cursor.previous;
    }
    return run;
  }

  /// A day is part of a run if it was played, or if a freeze bridged it.
  bool _counts(DailyDate date) =>
      completed.contains(date) || frozen.contains(date);
}
