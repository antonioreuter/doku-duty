import '../../daily_challenge/domain/daily_date.dart';
import '../../season_map/domain/node_type.dart';
import 'earning.dart';

/// A finished puzzle, as far as **stamp**s are concerned.
final class SolveFacts {
  const SolveFacts({
    required this.puzzleId,
    required this.isFirstSolve,
    required this.isPerfect,
  });

  final String puzzleId;

  /// Whether this completion wrote the puzzle's **solve record**. A replay of a
  /// solved board is the same puzzle and pays nothing more (D-133).
  final bool isFirstSolve;

  /// Solved with no **mistake**.
  final bool isPerfect;
}

/// A **daily challenge** recorded as completed.
final class DayFacts {
  const DayFacts({required this.date, required this.streak});

  final DailyDate date;

  /// The **streak** this day makes, as the **calendar** reads it afterwards.
  final int streak;
}

/// A **node** completed or opened on the **trail**.
final class NodeFacts {
  const NodeFacts({
    required this.seasonId,
    required this.position,
    required this.type,
  });

  final String seasonId;
  final int position;
  final NodeType type;
}

/// Everything one completion did. Any part may be absent: a **free play**
/// solve has no day and no **node**, and a **chest node** has no solve.
final class Completion {
  const Completion({this.solve, this.day, this.node});

  final SolveFacts? solve;
  final DayFacts? day;
  final NodeFacts? node;
}

/// D-66's values, keyed as D-133 sets out.
///
/// The values are compiled in and nothing reads them from a config key, so
/// no publish can raise a price that does not exist or sell what D-66 says
/// money cannot reach.
abstract final class EarningRules {
  static const int daily = 2;
  static const int perfectSolve = 3;
  static const int streakMilestone = 10;
  static const int chest = 12;
  static const int boss = 20;

  /// Every seventh day of a run, not only the first seventh (D-134).
  static const int streakInterval = 7;

  static List<Earning> earningsFor(Completion completion) {
    final earnings = <Earning>[];

    final solve = completion.solve;
    if (solve != null && solve.isFirstSolve && solve.isPerfect) {
      earnings.add(
        Earning(key: 'perfect:${solve.puzzleId}', amount: perfectSolve),
      );
    }

    final day = completion.day;
    if (day != null) {
      earnings.add(Earning(key: 'daily:${day.date.toIso()}', amount: daily));
      if (day.streak > 0 && day.streak % streakInterval == 0) {
        // Keyed by the run's first day, so a **streak** that breaks and
        // reaches seven again is a new event and pays again (D-133).
        earnings.add(
          Earning(
            key: 'streak:${_runStart(day).toIso()}:${day.streak}',
            amount: streakMilestone,
          ),
        );
      }
    }

    final node = completion.node;
    if (node != null) {
      final amount = switch (node.type) {
        NodeType.chest => chest,
        NodeType.boss => boss,
        // Paid through the perfect solve alone; D-66 prices no **node** of
        // these types.
        NodeType.puzzle || NodeType.variant => null,
      };
      if (amount != null) {
        earnings.add(
          Earning(
            key: '${node.type.name}:${node.seasonId}:${node.position}',
            amount: amount,
          ),
        );
      }
    }

    return earnings;
  }

  /// The day the run ending on [day] began. A day a **streak freeze** bridged
  /// is part of the run, as it is part of the **streak**, so counting back is
  /// exact.
  static DailyDate _runStart(DayFacts day) {
    var cursor = day.date;
    for (var i = 1; i < day.streak; i++) {
      cursor = cursor.previous;
    }
    return cursor;
  }
}
