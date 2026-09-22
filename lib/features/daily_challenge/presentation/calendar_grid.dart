import 'package:flutter/material.dart';

import '../../design_system/domain/palette.dart';
import '../../design_system/presentation/doku_colours.dart';
import '../../design_system/presentation/doku_type.dart';
import '../domain/daily_calendar.dart';
import '../domain/daily_date.dart';

/// The month grid.
///
/// **Every day state is carried twice** (constraint 5): a fill *and* a glyph,
/// with the date always legible underneath. A **calendar** whose only signal is
/// colour would be unreadable to a player with a colour vision deficiency and
/// silent to a screen reader — and this screen is the whole record of a habit,
/// so it is the last place to spend the one signal.
///
/// The colours come from the tokens by their documented jobs: `cactusGreen` for
/// a completed day, which is completion; `badgeGold` for a day a **streak
/// freeze** bridged, which is "reward, progress"; and a `bone` surface for a
/// day that was missed. A missed day gets **no state colour at all** — it is
/// not an error, and giving it `sunsetRed` would say the player did something
/// wrong by having a life (constraint 1).
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    required this.month,
    required this.calendar,
    required this.today,
    super.key,
  });

  /// Any date within the month to draw.
  final DailyDate month;
  final DailyCalendar calendar;
  final DailyDate today;

  @override
  Widget build(BuildContext context) {
    final days = _daysOf(month);

    return Column(
      key: const ValueKey<String>('daily-calendar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(_monthName(month), style: TypeRole.body.style),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: <Widget>[
            for (final date in days)
              _DayCell(
                date: date,
                state: calendar.stateOf(date, today: today),
              ),
          ],
        ),
      ],
    );
  }

  static List<DailyDate> _daysOf(DailyDate any) {
    final days = <DailyDate>[];
    var cursor = DailyDate(any.year, any.month, 1);
    while (cursor.month == any.month) {
      days.add(cursor);
      cursor = cursor.next;
    }
    return days;
  }

  static String _monthName(DailyDate date) => switch (date.month) {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    _ => 'December',
  };
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.state});

  final DailyDate date;
  final DayState state;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // The whole state in words. This is the only route a screen reader has to
      // the **calendar**, so every day says what it is rather than being a
      // coloured square with a number in it.
      label: '${date.day} $_stateWord',
      excludeSemantics: true,
      child: Container(
        key: ValueKey<String>('daily-day-${date.toIso()}'),
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Text(
              '${date.day}',
              style: TypeRole.label.style.copyWith(color: DokuColours.duskInk),
            ),
            if (_glyph != null)
              Positioned(
                right: 2,
                top: 2,
                child: Icon(_glyph, size: 10, color: DokuColours.duskInk),
              ),
          ],
        ),
      ),
    );
  }

  String get _stateWord => switch (state) {
    DayState.completed => 'completed',
    DayState.frozen => 'streak freeze used',
    DayState.missed => 'missed',
    DayState.notYet => 'not yet',
    DayState.untracked => 'no record',
  };

  /// The second channel, so the state survives greyscale and a reader.
  IconData? get _glyph => switch (state) {
    DayState.completed => Icons.check,
    DayState.frozen => Icons.ac_unit,
    // A missed day and a future day carry no glyph. Neither is something the
    // player did; one has not happened and the other simply did not.
    DayState.missed || DayState.notYet || DayState.untracked => null,
  };

  Color get _fill => switch (state) {
    DayState.completed => PaletteToken.cactusGreen.paleColour!,
    DayState.frozen => PaletteToken.badgeGold.paleColour!,
    DayState.missed ||
    DayState.notYet ||
    DayState.untracked => PaletteToken.bone.colour,
  };

  Color get _border => switch (state) {
    DayState.completed => PaletteToken.cactusGreen.colour,
    DayState.frozen => PaletteToken.badgeGold.colour,
    DayState.missed => DokuColours.inkSoft,
    // A day nothing is claimed about is drawn faintest of all — whether it is
    // still to come or was before the player arrived.
    DayState.notYet || DayState.untracked => DokuColours.hairline,
  };
}
