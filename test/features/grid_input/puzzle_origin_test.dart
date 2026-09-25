import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/grid_input/application/puzzle_origin.dart';

void main() {
  late ProviderContainer container;
  final day = DatedDay(date: DailyDate(2026, 3, 14), isVerified: false);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  PuzzleOrigin origin() => container.read(puzzleOriginProvider);
  PuzzleOriginNotifier opener() =>
      container.read(puzzleOriginProvider.notifier);

  test('nothing opened is free play, which completes nothing', () {
    expect(origin(), isA<FreePlayOrigin>());
  });

  test('the last board opened is the only origin', () {
    opener().openNode(7);
    expect(origin(), const TrailOrigin(7));

    opener().openDaily(day);
    expect(origin(), DailyOrigin(day));

    // The failure one value exists to prevent: a daily marker left standing
    // would credit this **free play** solve to the **calendar**.
    opener().openFreePlay();
    expect(origin(), isA<FreePlayOrigin>());
  });

  test('the daily carries the day it was opened for (D-132)', () {
    opener().openDaily(day);

    final opened = origin() as DailyOrigin;
    expect(opened.day.date, DailyDate(2026, 3, 14));
    expect(opened.day.isVerified, isFalse);
  });
}
