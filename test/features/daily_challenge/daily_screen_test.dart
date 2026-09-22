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
import 'package:doku_duty/features/season_map/application/season_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The **daily challenge** screen.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'daily',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          for (var i = 0; i < 3; i++)
            StoredPuzzle(
              id: 'q-${rank.name}-$i',
              clues: _clues,
              solution: _solution,
              rank: rank,
              seed: i,
            ),
      ],
    );
  });
  tearDown(() => db.close());

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

  group('the screen shows where the player stands', () {
    testWidgets('a new player has no streak and a freeze ready', (
      tester,
    ) async {
      await tester.pumpWidget(appOn(DateTime(2026, 3, 20, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey<String>('daily-streak')))
            .data,
        'No streak yet',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey<String>('daily-freeze')))
            .data,
        'Streak freeze ready',
      );
    });

    testWidgets('a run of days is counted', (tester) async {
      final repository = DailyRepository(db);
      for (var day = 18; day <= 20; day++) {
        await repository.completeDay(
          DatedDay(date: DailyDate(2026, 3, day), isVerified: true),
        );
      }

      await tester.pumpWidget(appOn(DateTime(2026, 3, 20, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey<String>('daily-streak')))
            .data,
        '3 days in a row',
      );
    });

    testWidgets('one day reads in the singular', (tester) async {
      await DailyRepository(
        db,
      ).completeDay(DatedDay(date: DailyDate(2026, 3, 20), isVerified: true));

      await tester.pumpWidget(appOn(DateTime(2026, 3, 20, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey<String>('daily-streak')))
            .data,
        '1 day in a row',
      );
    });
  });

  group('midnight', () {
    testWidgets('the day rolls over while the app is open', (tester) async {
      // Before midnight.
      await tester.pumpWidget(appOn(DateTime(2026, 3, 20, 23, 59)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(
        find.byKey(const ValueKey<String>('daily-day-2026-03-20')),
        findsOneWidget,
      );

      // After it. Rebuilding with the later clock is what a rollover looks
      // like to this screen: the date it is drawing has changed underneath it.
      await tester.pumpWidget(appOn(DateTime(2026, 3, 21, 0, 1)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('daily-day-2026-03-21')),
        findsOneWidget,
      );
    });

    testWidgets('resuming after the day moved re-reads it', (tester) async {
      // The bug a real device found, and the reason the task asked for the
      // check on hardware. The status is a cached read, so a phone left open
      // across midnight — or carried into another timezone — came back showing
      // yesterday's board at yesterday's **rank**. Rebuilding the whole tree,
      // which the test above does, hides it completely: only a *resume* with
      // the same tree still mounted reproduces it.
      var now = DateTime(2026, 3, 16, 10); // Monday — Greenhorn.

      await tester.pumpWidget(
        ProviderScope(
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
        ),
      );
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(find.text('Greenhorn rank'), findsOneWidget);

      // The clock moves under the running app, then it is resumed.
      now = DateTime(2026, 3, 18, 10); // Wednesday — Deputy.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        find.text('Deputy rank'),
        findsOneWidget,
        reason: 'the daily came back showing the previous day',
      );
    });

    testWidgets('resuming on the same day does not re-read', (tester) async {
      // The other half: re-reading the database on every app switch would be
      // a cost with nothing to show for it, so the refresh is guarded on the
      // date actually having moved.
      await tester.pumpWidget(appOn(DateTime(2026, 3, 16, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Greenhorn rank'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a completed day stays completed across the rollover', (
      tester,
    ) async {
      await DailyRepository(
        db,
      ).completeDay(DatedDay(date: DailyDate(2026, 3, 20), isVerified: true));

      await tester.pumpWidget(appOn(DateTime(2026, 3, 21, 0, 1)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      // Yesterday is still on the **calendar**, and today is open again rather
      // than inheriting yesterday's completion.
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey<String>('daily-streak')))
            .data,
        '1 day in a row',
      );
      expect(find.text('Play today'), findsOneWidget);
    });
  });

  group('opening the board', () {
    testWidgets('it does not advance the trail', (tester) async {
      // The trap this capability had to avoid. `season_map` completes a
      // **node** by whatever `activeNodeProvider` is holding, so a
      // **daily challenge** board opened with a **node** still active would
      // quietly walk the player's **trail** forward when they solved it.
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
            appDatabaseProvider.overrideWith((ref) => db),
            packInstallationProvider.overrideWith(
              (ref) async => PackInstallOutcome.alreadyInstalled,
            ),
            dailyClockProvider.overrideWithValue(
              DailyClock(
                offset: Duration.zero,
                now: () => DateTime(2026, 3, 20, 10),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const DokuDutyApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stand on a **node**, as though the player had just opened one.
      capturedRef.read(activeNodeProvider.notifier).enter(7);
      expect(capturedRef.read(activeNodeProvider), 7);

      await openDaily(tester);
      await tester.tap(find.byKey(const ValueKey<String>('daily-open')));
      await tester.pumpAndSettle();

      expect(
        capturedRef.read(activeNodeProvider),
        isNull,
        reason: 'the daily opened a board while a node was still active',
      );
    });

    testWidgets('the rank of the day is named', (tester) async {
      // 2026-03-16 is a Monday, which the ramp puts at Greenhorn (D-116).
      await tester.pumpWidget(appOn(DateTime(2026, 3, 16, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(find.text('Greenhorn rank'), findsOneWidget);
    });

    testWidgets('a Legend day is offered to a Greenhorn player', (
      tester,
    ) async {
      // 2026-03-22 is a Sunday — the hardest board of the week, offered to
      // everybody at the same rank whatever ladder they are on (D-116), and
      // never withheld (D-103).
      await tester.pumpWidget(appOn(DateTime(2026, 3, 22, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(find.text('Legend rank'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('daily-open')), findsOneWidget);
    });
  });

  group('the calendar', () {
    testWidgets('every day of the month is drawn', (tester) async {
      await tester.pumpWidget(appOn(DateTime(2026, 3, 20, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      // March has 31 days and every one is on the grid, including the ones
      // still to come.
      for (final day in <int>[1, 15, 31]) {
        expect(
          find.byKey(
            ValueKey<String>(
              'daily-day-2026-03-${day.toString().padLeft(2, '0')}',
            ),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('a February in a leap year has 29 days', (tester) async {
      await tester.pumpWidget(appOn(DateTime(2028, 2, 10, 10)));
      await tester.pumpAndSettle();
      await openDaily(tester);

      expect(
        find.byKey(const ValueKey<String>('daily-day-2028-02-29')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('daily-day-2028-03-01')),
        findsNothing,
      );
    });
  });
}

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';
