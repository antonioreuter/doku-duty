import '../data/daily_repository.dart';
import '../domain/daily_board_source.dart';
import '../domain/daily_calendar.dart';
import '../domain/daily_date.dart';
import '../domain/daily_resolver.dart';

/// What the **daily challenge** screen needs to know.
class DailyStatus {
  const DailyStatus({
    required this.date,
    required this.board,
    required this.isCompleted,
    required this.streak,
    required this.freezeIsHeld,
    required this.calendar,
  });

  final DailyDate date;

  /// Null only when nothing is installed at any **rank**.
  final DailyBoard? board;

  final bool isCompleted;
  final int streak;
  final bool freezeIsHeld;
  final DailyCalendar calendar;
}

/// What completing a day produced, for whoever else is counting.
///
/// **Nothing in this change consumes it.** `add-stamps` (18) mints the 2 and
/// the 10 that D-66 prices, and `add-trophy-cabinet` (16) files the full-month
/// trophy. The signal exists now so neither has to invent its own trigger, and
/// a test asserts nothing is minted today.
class DailyCompletion {
  const DailyCompletion({
    required this.date,
    required this.streak,
    required this.isStreakMilestone,
  });

  final DailyDate date;
  final int streak;

  /// Every seventh day, which is the milestone D-66 prices at 10 **stamp**s.
  final bool isStreakMilestone;
}

/// Ties the date, the schedule, the **pack**, and the **calendar** together.
class DailyService {
  const DailyService({
    required this.repository,
    required this.resolver,
    required this.clock,
  });

  final DailyRepository repository;
  final DailyResolver resolver;
  final DailyClock clock;

  /// Where the player stands today.
  ///
  /// Reading this also settles any absence: a missed day is noticed the next
  /// time the player opens the app, and the **streak freeze** is spent then,
  /// automatically and without being offered (D-20). That is the only moment
  /// there is — there is no background process, and a freeze the player has to
  /// remember to use is the trap D-20 names.
  Future<DailyStatus> today() async {
    final today = clock.today();
    await _settleAbsence(today.date);

    final calendar = await repository.calendar();
    final ledger = await repository.ledger(today.date);

    return DailyStatus(
      date: today.date,
      board: await resolver.boardFor(today.date),
      isCompleted: calendar.wasCompleted(today.date),
      streak: calendar.streakOn(today.date),
      freezeIsHeld: ledger.isHeld,
      calendar: calendar,
    );
  }

  /// Records today as completed.
  ///
  /// **The write lands before this returns**, which is what lets the caller
  /// show the celebration afterwards and know the day is safe. Doing it the
  /// other way round — celebrate, then write — loses the day to an app kill
  /// during the animation, and the player has every reason to believe it
  /// counted (constraint 9).
  Future<DailyCompletion> complete() async {
    final today = clock.today();

    await repository.completeDay(today);

    final calendar = await repository.calendar();
    final streak = calendar.streakOn(today.date);

    return DailyCompletion(
      date: today.date,
      streak: streak,
      isStreakMilestone: streak > 0 && streak % 7 == 0,
    );
  }

  /// Spends a **streak freeze** on a missed day, if one is held and exactly one
  /// day was missed.
  ///
  /// Called on the way into [today] rather than on a schedule. A player who was
  /// away for a month comes back to a broken **streak** and one held freeze,
  /// which is D-117's intent: absence does not compound into credit.
  Future<void> _settleAbsence(DailyDate today) async {
    final calendar = await repository.calendar();
    if (calendar.completed.isEmpty && calendar.frozen.isEmpty) return;

    final yesterday = today.previous;
    // Nothing to settle: yesterday is accounted for, or today already is.
    if (calendar.wasCompleted(yesterday) ||
        calendar.wasFrozen(yesterday) ||
        calendar.wasCompleted(today)) {
      return;
    }

    // One missed day is bridgeable; the run must have been alive the day
    // before it, or there is no **streak** left to protect.
    final dayBefore = yesterday.previous;
    if (!calendar.wasCompleted(dayBefore) && !calendar.wasFrozen(dayBefore)) {
      return;
    }

    final ledger = await repository.ledger(today);
    final outcome = ledger.applyTo(missed: <DailyDate>[yesterday]);
    if (outcome.frozen.isEmpty) return;

    await repository.recordFrozen(outcome.frozen);
    await repository.saveLedger(outcome.ledger);
  }
}
