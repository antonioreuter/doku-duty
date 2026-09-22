import 'dart:io';

import 'package:doku_duty/features/daily_challenge/domain/daily_calendar.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/daily_challenge/presentation/calendar_grid.dart';
import 'package:doku_duty/features/design_system/domain/palette.dart';
import 'package:doku_duty/features/design_system/domain/season_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_colours.dart';
import 'package:doku_duty/features/design_system/presentation/doku_theme.dart';
import 'package:doku_duty/features/design_system/presentation/doku_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The **calendar** in its day states.
///
/// The golden is the check that constraint 5 holds where it matters most: this
/// screen is the whole record of a habit, and a grid whose only signal is
/// colour says nothing to a player who cannot separate the hues. Each state
/// carries a fill, a border, and — for the two that are *events* — a glyph.
///
/// **Nothing here reads the clock.** Every date is passed in, so the images do
/// not encode the day they were generated on. D-118 records why that matters:
/// the **trail**'s goldens did read it, and failed the next morning.
void main() {
  setUpAll(() async {
    await _loadFonts();
  });

  Widget grid(DailyCalendar calendar, {required DailyDate today}) =>
      MaterialApp(
        theme: DokuTheme.from(SeasonPalette(SeasonTheme.defaultTheme)),
        home: Scaffold(
          backgroundColor: PaletteToken.sand.colour,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CalendarGrid(
              month: DailyDate(2026, 3, 1),
              calendar: calendar,
              today: today,
            ),
          ),
        ),
      );

  testWidgets('a month with every state in it', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final calendar = DailyCalendar(
      completed: <DailyDate>{
        for (var day = 1; day <= 8; day++) DailyDate(2026, 3, day),
        // A gap at 9 and 10, bridged at 9 by a freeze.
        for (var day = 11; day <= 16; day++) DailyDate(2026, 3, day),
      },
      frozen: <DailyDate>{DailyDate(2026, 3, 9)},
    );

    await tester.pumpWidget(grid(calendar, today: DailyDate(2026, 3, 16)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CalendarGrid),
      matchesGoldenFile('goldens/calendar_mixed.png'),
    );
  });

  testWidgets('a month nobody has played', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      grid(DailyCalendar.empty(), today: DailyDate(2026, 3, 1)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CalendarGrid),
      matchesGoldenFile('goldens/calendar_empty.png'),
    );
  });

  testWidgets('a perfect month', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final calendar = DailyCalendar(
      completed: <DailyDate>{
        for (var day = 1; day <= 31; day++) DailyDate(2026, 3, day),
      },
    );

    await tester.pumpWidget(grid(calendar, today: DailyDate(2026, 3, 31)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CalendarGrid),
      matchesGoldenFile('goldens/calendar_perfect.png'),
    );
  });

  group('the states are told apart without colour', () {
    test('each carries a different non-colour signal', () {
      final calendar = DailyCalendar(
        completed: <DailyDate>{DailyDate(2026, 3, 1)},
        frozen: <DailyDate>{DailyDate(2026, 3, 2)},
      );
      final today = DailyDate(2026, 3, 3);

      // Four states, four distinct answers, computed rather than painted —
      // which is what the widget renders its glyph and its words from.
      expect(
        <DayState>{
          calendar.stateOf(DailyDate(2026, 3, 1), today: today),
          calendar.stateOf(DailyDate(2026, 3, 2), today: today),
          calendar.stateOf(DailyDate(2026, 3, 3), today: today),
          calendar.stateOf(DailyDate(2026, 3, 4), today: today),
        },
        <DayState>{
          DayState.completed,
          DayState.frozen,
          DayState.missed,
          DayState.notYet,
        },
      );
    });
  });
}

/// The bundled face, so the goldens are text rather than boxes.
Future<void> _loadFonts() async {
  final loader = FontLoader(DokuType.family);
  for (final weight in <String>['Regular', 'Medium', 'SemiBold']) {
    final bytes = File('assets/fonts/Nunito-$weight.ttf').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
