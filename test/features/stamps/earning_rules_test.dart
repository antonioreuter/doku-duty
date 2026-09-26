import 'package:flutter_test/flutter_test.dart';

import 'package:doku_duty/features/daily_challenge/domain/daily_date.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/stamps/domain/earning.dart';
import 'package:doku_duty/features/stamps/domain/earning_rules.dart';

/// What each completion pays, at D-66's values, under D-133's keys.
void main() {
  const firstClean = SolveFacts(
    puzzleId: 'p-1',
    isFirstSolve: true,
    isPerfect: true,
  );
  final april9 = DailyDate(2026, 4, 9);

  Map<String, int> paid(Completion completion) => <String, int>{
    for (final e in EarningRules.earningsFor(completion)) e.key: e.amount,
  };

  group('each event pays its D-66 value under its key', () {
    test('a completed daily pays 2', () {
      expect(
        paid(Completion(day: DayFacts(date: april9, streak: 1))),
        <String, int>{'daily:2026-04-09': 2},
      );
    });

    test('a first solve with no mistake pays 3', () {
      expect(paid(const Completion(solve: firstClean)), <String, int>{
        'perfect:p-1': 3,
      });
    });

    test('the seventh day of a streak pays 10 beside the day', () {
      // A run of 7 ending on 9 April began on 3 April.
      expect(
        paid(Completion(day: DayFacts(date: april9, streak: 7))),
        <String, int>{'daily:2026-04-09': 2, 'streak:2026-04-03:7': 10},
      );
    });

    test('a chest pays 12', () {
      expect(
        paid(
          const Completion(
            node: NodeFacts(
              seasonId: 'dust-gulch',
              position: 11,
              type: NodeType.chest,
            ),
          ),
        ),
        <String, int>{'chest:dust-gulch:11': 12},
      );
    });

    test('a boss pays 20', () {
      expect(
        paid(
          const Completion(
            node: NodeFacts(
              seasonId: 'dust-gulch',
              position: 22,
              type: NodeType.boss,
            ),
          ),
        ),
        <String, int>{'boss:dust-gulch:22': 20},
      );
    });
  });

  group('earnings stack', () {
    test('a perfect daily is two earnings, 5 in all', () {
      final earnings = EarningRules.earningsFor(
        Completion(
          solve: firstClean,
          day: DayFacts(date: april9, streak: 1),
        ),
      );

      expect(earnings, hasLength(2));
      expect(earnings.fold<int>(0, (sum, e) => sum + e.amount), 5);
    });

    test('a perfect boss is two earnings, 23 in all', () {
      final earnings = EarningRules.earningsFor(
        const Completion(
          solve: firstClean,
          node: NodeFacts(
            seasonId: 'dust-gulch',
            position: 42,
            type: NodeType.boss,
          ),
        ),
      );

      expect(earnings, hasLength(2));
      expect(earnings.fold<int>(0, (sum, e) => sum + e.amount), 23);
    });
  });

  group('what does not pay', () {
    test('a solve with a mistake pays nothing, and takes nothing', () {
      expect(
        EarningRules.earningsFor(
          const Completion(
            solve: SolveFacts(
              puzzleId: 'p-1',
              isFirstSolve: true,
              isPerfect: false,
            ),
          ),
        ),
        isEmpty,
      );
    });

    test('a clean replay of a puzzle already solved pays nothing (D-133)', () {
      expect(
        EarningRules.earningsFor(
          const Completion(
            solve: SolveFacts(
              puzzleId: 'p-1',
              isFirstSolve: false,
              isPerfect: true,
            ),
          ),
        ),
        isEmpty,
      );
    });

    for (final type in <NodeType>[NodeType.puzzle, NodeType.variant]) {
      test('a ${type.name} node earns only through the perfect solve', () {
        final node = NodeFacts(seasonId: 'dust-gulch', position: 5, type: type);

        expect(EarningRules.earningsFor(Completion(node: node)), isEmpty);
        expect(paid(Completion(node: node, solve: firstClean)), <String, int>{
          'perfect:p-1': 3,
        });
      });
    }
  });

  group('the streak milestone', () {
    for (final length in <int>[7, 14, 21]) {
      test('a streak of $length pays', () {
        expect(
          paid(
            Completion(
              day: DayFacts(date: april9, streak: length),
            ),
          ).keys.where((k) => k.startsWith('streak:')),
          hasLength(1),
        );
      });
    }

    for (final length in <int>[6, 8, 13]) {
      test('a streak of $length does not', () {
        expect(
          paid(
            Completion(
              day: DayFacts(date: april9, streak: length),
            ),
          ).keys.where((k) => k.startsWith('streak:')),
          isEmpty,
        );
      });
    }

    test('two runs that each reach 7 are different events', () {
      final first = paid(
        Completion(day: DayFacts(date: DailyDate(2026, 4, 9), streak: 7)),
      );
      final second = paid(
        Completion(day: DayFacts(date: DailyDate(2026, 5, 20), streak: 7)),
      );

      final firstKey = first.keys.singleWhere((k) => k.startsWith('streak:'));
      final secondKey = second.keys.singleWhere((k) => k.startsWith('streak:'));
      expect(firstKey, isNot(secondKey));
    });
  });

  test('nothing completed pays nothing', () {
    expect(EarningRules.earningsFor(const Completion()), isEmpty);
  });

  test('an earning is a value', () {
    expect(
      const Earning(key: 'daily:x', amount: 2),
      const Earning(key: 'daily:x', amount: 2),
    );
  });
}
