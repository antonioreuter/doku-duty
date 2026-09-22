/// A calendar day, which is not a duration.
///
/// The **daily challenge** rolls over at midnight local time and a **streak**
/// is a run of consecutive days, so every question this capability asks is
/// "which day?" and never "how many hours?". Those are different quantities:
/// a spring-forward day is 23 hours and an autumn-back day is 25, and code that
/// subtracts two `DateTime`s and divides by 24 gets both wrong — quietly, once
/// a year, in a way that costs somebody a year-long **streak**.
///
/// So this type holds year, month, and day and nothing else. There is no time
/// of day to be wrong about and no timezone to carry.
class DailyDate implements Comparable<DailyDate> {
  DailyDate(this.year, this.month, this.day);

  /// The local day an instant falls in. The time is discarded, deliberately.
  factory DailyDate.from(DateTime instant) =>
      DailyDate(instant.year, instant.month, instant.day);

  /// Reads the stored form. Throws on anything else — a corrupt date is not
  /// something to guess at, because guessing writes a wrong day to the
  /// **calendar**.
  factory DailyDate.parse(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) {
      throw FormatException('not a stored daily date', iso);
    }
    return DailyDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  final int year;
  final int month;
  final int day;

  /// Midday, never midnight.
  ///
  /// Arithmetic is done through `DateTime` to get month lengths and leap years
  /// for free, and midday is what makes that safe: a DST shift of an hour in
  /// either direction cannot push midday across a date boundary, where it would
  /// push midnight onto the previous day.
  DateTime get _noon => DateTime(year, month, day, 12);

  DailyDate get next => DailyDate.from(_noon.add(const Duration(days: 1)));

  DailyDate get previous =>
      DailyDate.from(_noon.subtract(const Duration(days: 1)));

  /// `DateTime.monday` … `DateTime.sunday`, for the weekly ramp (D-116).
  int get weekday => _noon.weekday;

  /// Whole days from this date to [other]. Negative if [other] is earlier.
  ///
  /// Rounded from the midday-to-midday difference, so a 23- or 25-hour day
  /// still counts as one. Truncating instead is the DST bug named above.
  int daysUntil(DailyDate other) =>
      (other._noon.difference(_noon).inHours / 24).round();

  /// `YYYY-MM-DD`. Zero-padded so the stored form sorts in date order, which is
  /// what lets the **calendar** be queried by range.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(DailyDate other) => toIso().compareTo(other.toIso());

  bool operator <(DailyDate other) => compareTo(other) < 0;

  bool operator >(DailyDate other) => compareTo(other) > 0;

  bool operator <=(DailyDate other) => compareTo(other) <= 0;

  bool operator >=(DailyDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is DailyDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// A date, and whether the clock that produced it can be trusted.
///
/// Device clocks are user-editable and the **daily challenge** depends on the
/// date, so a day recorded offline is marked rather than refused. The marking
/// exists to stop fabrication on reconnect, never to catch a traveller
/// (`docs/TECH_STACK.md` §3b) — nothing in this capability may reduce a
/// **streak** because a clock moved.
class DatedDay {
  const DatedDay({required this.date, required this.isVerified});

  final DailyDate date;

  /// True when the date came from a known server-time offset.
  final bool isVerified;
}

/// Where "today" comes from.
///
/// The offset is what a sync last reported; null means none has been seen, so
/// the device clock stands alone and what it produces is unverified.
class DailyClock {
  DailyClock({required this.offset, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Duration? offset;
  final DateTime Function() _now;

  DatedDay today() {
    final local = _now();
    final corrected = offset == null ? local : local.add(offset!);
    return DatedDay(
      date: DailyDate.from(corrected),
      isVerified: offset != null,
    );
  }
}
