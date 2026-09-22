import 'daily_date.dart';

/// One day on the **calendar**, and whether the clock that recorded it was
/// answerable to a server.
class DayEntry {
  const DayEntry({required this.date, required this.isVerified});

  final DailyDate date;

  /// False when the day was recorded with no known server-time offset — the
  /// ordinary offline case, not a suspicion.
  final bool isVerified;

  @override
  bool operator ==(Object other) =>
      other is DayEntry && other.date == date && other.isVerified == isVerified;

  @override
  int get hashCode => Object.hash(date, isVerified);
}

/// Reconciling recorded days against the server's date.
///
/// **This exists to stop fabrication, not to catch travellers**
/// (`docs/TECH_STACK.md` §3b), and the asymmetry is the whole design. A day can
/// only be discarded when it is *unverified* **and** dated ahead of the
/// server's own today — the single pattern a wound-forward clock produces and
/// an honest player cannot. Everything else is kept.
///
/// That leaves the rule strictly one-directional: there is no input to this
/// function that lowers a **streak** for a player who merely changed timezone,
/// flew, or went offline. A player who games the clock loses the days they
/// invented; nobody else loses anything.
abstract final class ClockTrust {
  static List<DayEntry> reconcile({
    required List<DayEntry> entries,
    required DailyDate serverToday,
  }) {
    return entries.where((e) => e.isVerified || e.date <= serverToday).toList();
  }
}
