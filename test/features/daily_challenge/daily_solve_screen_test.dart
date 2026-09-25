import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/application/daily_providers.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/grid_input/presentation/puzzle_grid.dart';
import 'package:doku_duty/features/persistence/application/database_provider.dart';
import 'package:doku_duty/features/persistence/application/settings_providers.dart';
import 'package:doku_duty/features/persistence/data/app_database.dart'
    hide Pack;
import 'package:doku_duty/features/persistence/data/pack_repository.dart';
import 'package:doku_duty/features/platform_shell/application/flavour_provider.dart';
import 'package:doku_duty/features/platform_shell/domain/flavour.dart';
import 'package:doku_duty/features/platform_shell/presentation/app.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_installer.dart';
import 'package:doku_duty/features/puzzle_engine/application/pack_providers.dart';

import '../../support/home_navigation.dart';

const String _clues =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const String _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// Play the open puzzle to a finished board, tapping the real grid.
Future<void> _solveOnScreen(WidgetTester tester) async {
  final box = tester.getRect(find.byType(PuzzleGrid));
  final side = box.width < box.height ? box.width : box.height;
  final origin = Offset(
    box.left + (box.width - side) / 2,
    box.top + (box.height - side) / 2,
  );
  final cellSize = side / 9;

  for (var cell = 0; cell < 81; cell++) {
    if (_clues[cell] != '.') continue;
    await tester.tapAt(
      Offset(
        origin.dx + cellSize * (cell % 9 + 0.5),
        origin.dy + cellSize * (cell ~/ 9 + 0.5),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(_solution[cell]).first);
    await tester.pump();
  }
  // Let the completion sequence and the writes finish.
  await tester.pump(const Duration(seconds: 3));
}

/// A **daily challenge** solved on screen reaches every screen that reports it.
///
/// The bug `wire-completion-events` fixed was invisible from any one layer: the
/// repository, the service and the minting each passed their own tests while
/// the app recorded nothing. So this walks the route a player takes — the
/// daily card, the grid, back — and reads the answer off the screens, with no
/// restart in between.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await PackRepository(db).installPack(
      packId: 'daily',
      version: 1,
      puzzles: <StoredPuzzle>[
        for (final rank in Rank.values)
          StoredPuzzle(
            id: 'q-${rank.name}',
            clues: _clues,
            solution: _solution,
            rank: rank,
            seed: 0,
          ),
      ],
    );
  });
  tearDown(() => db.close());

  testWidgets('the card, the calendar and the cabinet all see the solve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // 2026-03-19 is a Thursday, which the ramp puts at Sheriff (D-116) — so
    // the same solve that marks the day raises the player's **rank**.
    final today = DailyDate(2026, 3, 19);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavourConfigProvider.overrideWithValue(FlavourConfig.dev),
          appDatabaseProvider.overrideWith((ref) => db),
          packInstallationProvider.overrideWith(
            (ref) async => PackInstallOutcome.alreadyInstalled,
          ),
          persistedStrictModeOverride,
          dailyClockProvider.overrideWithValue(
            DailyClock(
              offset: Duration.zero,
              now: () => DateTime(2026, 3, 19, 10),
            ),
          ),
        ],
        child: const DokuDutyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Visited before the solve, so its reads are cached — the case where a
    // missing invalidation shows.
    await goToCabinet(tester);
    await goToDaily(tester);
    expect(find.text('Play today'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('daily-open')));
    await tester.pumpAndSettle();
    // A first puzzle opens on the **notes lesson**; a player may skip it, and
    // this one does.
    await tester.tap(find.byKey(const ValueKey<String>('lesson-skip')));
    await tester.pumpAndSettle();
    await _solveOnScreen(tester);
    // The write itself, so a failure below is about the screens and not about
    // a solve that never landed.
    expect(await DailyRepository(db).wasCompleted(today), isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(
      find.text('Completed today'),
      findsOneWidget,
      reason: 'the daily card still offers a day the player just completed',
    );
    expect(
      find.bySemanticsLabel('Today, sheriff, completed'),
      findsOneWidget,
      reason: 'a screen reader still hears the day offered, not completed',
    );
    expect(
      find.bySemanticsLabel('${today.day} completed'),
      findsOneWidget,
      reason: 'the calendar does not mark the day',
    );

    await goToCabinet(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Sheriff.*, earned$')),
      findsOneWidget,
      reason: 'the cabinet does not show the rank trophy the solve earned',
    );
  });
}
