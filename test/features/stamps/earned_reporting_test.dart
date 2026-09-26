import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_origin.dart';
import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';

import '../grid_input/support/production_solve.dart';

/// What a completion earned reaches the puzzle screen.
///
/// Through the production `boardSinkProvider`, never a sink built by hand: an
/// **earning** that is written and tested but never reported is the gap
/// `wire-completion-events` closed for the **calendar**, one layer up.
void main() {
  late ProductionSolve app;

  setUp(() async => app = await ProductionSolve.open());
  tearDown(() => app.close());

  PuzzleOriginNotifier opener() =>
      app.container.read(puzzleOriginProvider.notifier);

  test('a perfect daily reports 5', () async {
    opener().openDaily(
      DatedDay(date: DailyDate(2026, 4, 9), isVerified: false),
    );

    await app.solve(Rank.deputy);

    expect(app.lastEarned, 5);
  });

  test('a perfect free-play solve reports 3', () async {
    opener().openFreePlay();

    await app.solve(Rank.deputy);

    expect(app.lastEarned, 3);
  });

  test('a board completed again reports 0, so no notice shows', () async {
    opener().openFreePlay();
    await app.solve(Rank.deputy);

    await app.solve(Rank.deputy);

    expect(app.lastEarned, 0);
  });
}
