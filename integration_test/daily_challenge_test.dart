import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:doku_duty/features/daily_challenge/application/daily_providers.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart';
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// The **daily challenge** on a real platform.
///
/// The host suite proves the **streak** arithmetic, the **streak freeze**
/// rules, and the ramp. What this adds is the device: a real safe area, a
/// month grid laid out by the platform's own text engine, and a **calendar**
/// read back through a database file the platform wrote.
///
/// **This is the device runner for this change's platform checks.**
///
/// ```
/// flutter test integration_test/daily_challenge_test.dart -d <device> --flavor dev
/// ```
///
/// One thing it cannot do is change the device's timezone — that needs the OS,
/// and doing it by hand on the emulator is what found the bug the resume test
/// in `daily_screen_test.dart` now guards. Run that by hand too, on any phone
/// that reaches this file.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late File file;

  setUp(() async {
    // A real file, not memory: the point of running here is the platform's own
    // SQLite writing to the platform's own disk.
    file = File(
      '${Directory.systemTemp.createTempSync('daily').path}/daily.sqlite',
    );
    db = AppDatabase(NativeDatabase(file));
    await PackRepository(db).installPack(
      packId: 'device',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          for (var i = 0; i < 3; i++)
            StoredPuzzle(
              id: '${rank.name}-$i',
              clues: _clues,
              solution: _solution,
              rank: rank,
              seed: i,
            ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
    if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
  });

  Widget appOn(DateTime now) => ProviderScope(
    overrides: [
      flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
      appDatabaseProvider.overrideWith((ref) => db),
      packInstallationProvider.overrideWith(
        (ref) async => PackInstallOutcome.alreadyInstalled,
      ),
      dailyClockProvider.overrideWithValue(
        DailyClock(offset: Duration.zero, now: () => now),
      ),
    ],
    child: const DokuDutyApp(),
  );

  Future<void> openDaily(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('nav-daily')));
    await tester.pumpAndSettle();
  }

  testWidgets('the daily lays out inside the safe area', (tester) async {
    await tester.pumpWidget(appOn(DateTime(2026, 3, 16, 10)));
    await tester.pumpAndSettle();
    await openDaily(tester);

    final padding = tester.view.padding;
    final top = padding.top / tester.view.devicePixelRatio;
    final bottom = padding.bottom / tester.view.devicePixelRatio;
    debugPrint('safe area — top ${top}pt, bottom ${bottom}pt');

    // The title had drawn under the status bar on the emulator before a
    // `SafeArea` was added, so this is the regression rather than a formality.
    final title = tester.getRect(find.text('Daily challenge'));
    expect(
      title.top,
      greaterThanOrEqualTo(top),
      reason: 'the title drew under the status bar',
    );

    final nav = tester.getRect(find.byKey(const ValueKey<String>('home-nav')));
    expect(
      nav.bottom,
      lessThanOrEqualTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
      reason: 'the navigation ran off the bottom of the screen',
    );
    debugPrint(
      'nav bottom ${nav.bottom} of '
      '${tester.view.physicalSize.height / tester.view.devicePixelRatio}',
    );
  });

  testWidgets('the month grid draws every day', (tester) async {
    await tester.pumpWidget(appOn(DateTime(2026, 3, 16, 10)));
    await tester.pumpAndSettle();
    await openDaily(tester);

    for (final day in <int>[1, 16, 31]) {
      expect(
        find.byKey(
          ValueKey<String>(
            'daily-day-2026-03-${day.toString().padLeft(2, '0')}',
          ),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('the day rolls over across local midnight', (tester) async {
    await tester.pumpWidget(appOn(DateTime(2026, 3, 16, 23, 59)));
    await tester.pumpAndSettle();
    await openDaily(tester);

    // Monday, on the ramp.
    expect(find.text('Greenhorn rank'), findsOneWidget);

    await tester.pumpWidget(appOn(DateTime(2026, 3, 17, 0, 1)));
    await tester.pumpAndSettle();

    // Tuesday.
    expect(find.text('Deputy rank'), findsOneWidget);
  });

  testWidgets('a completed day survives the round trip through real storage', (
    tester,
  ) async {
    await DailyRepository(
      db,
    ).completeDay(DatedDay(date: DailyDate(2026, 3, 15), isVerified: true));
    await DailyRepository(
      db,
    ).completeDay(DatedDay(date: DailyDate(2026, 3, 16), isVerified: true));
    await db.close();

    // A second database over the same file, which is what a relaunch is.
    final reopened = AppDatabase(NativeDatabase(file));
    addTearDown(reopened.close);

    final calendar = await DailyRepository(reopened).calendar();
    expect(calendar.completed, hasLength(2));
    expect(calendar.streakOn(DailyDate(2026, 3, 16)), 2);

    // And the ledger, which is the other half of a **streak** surviving.
    final ledger = await DailyRepository(
      reopened,
    ).ledger(DailyDate(2026, 3, 16));
    expect(ledger.isHeld, isTrue);

    db = reopened;
  });

  testWidgets('a new player is told they have missed nothing', (tester) async {
    await tester.pumpWidget(appOn(DateTime(2026, 3, 16, 10)));
    await tester.pumpAndSettle();
    await openDaily(tester);

    expect(find.text('No streak yet'), findsOneWidget);
    expect(find.text('Streak freeze ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
