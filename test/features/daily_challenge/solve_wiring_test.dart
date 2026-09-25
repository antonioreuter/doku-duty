import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/grid_input/application/grid_providers.dart';
import 'package:doku_duty/features/mistake_model/domain/attempt.dart';
import 'package:doku_duty/features/puzzle_engine/domain/technique.dart';
import 'package:doku_duty/features/season_map/application/season_providers.dart';
import 'package:doku_duty/features/season_map/data/season_repository.dart';

import 'package:doku_duty/features/daily_challenge/application/daily_providers.dart';
import 'package:doku_duty/features/daily_challenge/data/daily_repository.dart';
import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_origin.dart';

import '../grid_input/support/production_solve.dart';

/// A **daily challenge** solved in the running app reaches the **calendar**.
///
/// Every piece of this had a test before `wire-completion-events` — the
/// repository, the service, the **streak** — and not one of them was called
/// when a player actually solved the daily. These drive the app's own sink.
void main() {
  late ProductionSolve app;
  final today = DailyDate(2026, 3, 20);

  setUp(() async {
    app = await ProductionSolve.open(
      overrides: [
        dailyClockProvider.overrideWith(
          (ref) => DailyClock(
            offset: null,
            now: () => DateTime(today.year, today.month, today.day, 10),
          ),
        ),
      ],
    );
  });
  tearDown(() => app.close());

  /// What the daily card does when it is tapped.
  void openAsTheDaily([DailyDate? date]) {
    app.container
        .read(puzzleOriginProvider.notifier)
        .openDaily(DatedDay(date: date ?? today, isVerified: false));
  }

  test('solving the daily marks its day on the calendar', () async {
    openAsTheDaily();

    await app.solve(Rank.deputy);

    final calendar = await DailyRepository(app.db).calendar();
    expect(calendar.wasCompleted(today), isTrue);
    expect(calendar.streakOn(today), 1);
  });

  test('a daily solved after midnight credits the day it was opened for '
      '(D-132)', () async {
    // The clock reads the 20th; the board was opened on the 19th.
    openAsTheDaily(DailyDate(2026, 3, 19));

    await app.solve(Rank.deputy);

    final calendar = await DailyRepository(app.db).calendar();
    expect(calendar.wasCompleted(DailyDate(2026, 3, 19)), isTrue);
    expect(calendar.wasCompleted(today), isFalse);
  });

  test('the same puzzle solved in free play marks no day', () async {
    app.container.read(puzzleOriginProvider.notifier).openFreePlay();

    await app.solve(Rank.deputy);

    expect((await DailyRepository(app.db).calendar()).completed, isEmpty);
  });

  test('a daily opened after a node completes the day and not the node '
      '(D-111)', () async {
    final seasonId = app.container.read(currentSeasonProvider).id;
    await SeasonRepository(app.db).enterSeason(seasonId);
    app.container.read(puzzleOriginProvider.notifier).openNode(1);
    openAsTheDaily();

    await app.solve(Rank.deputy);

    expect(
      (await DailyRepository(app.db).calendar()).wasCompleted(today),
      isTrue,
    );
    expect(
      (await SeasonRepository(app.db).progressFor(seasonId)).completedCount,
      0,
    );
  });

  test('the day and the solve record commit together or not at all', () async {
    openAsTheDaily();

    // No such puzzle, so the **solve record** throws after the day's write has
    // run inside the same transaction.
    await expectLater(
      app.container
          .read(boardSinkProvider)
          .complete(
            'no-such-puzzle',
            techniquesRequired: const <Technique>{},
            attempt: Attempt.fresh,
          ),
      throwsStateError,
    );

    expect(
      (await DailyRepository(app.db).calendar()).wasCompleted(today),
      isFalse,
      reason: 'the day survived a solve that was rolled back',
    );
  });
}
