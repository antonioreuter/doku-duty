import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:doku_duty/features/season_map/domain/trail_progress.dart';
import 'package:test/test.dart';

/// Where the player stands on the **trail**, and what that does and does not
/// permit.
///
/// Every test in the last group asserts something the rule must *refuse to do*.
/// Those are the ones worth having: the rule advancing correctly is visible the
/// first time anyone plays, where the rule quietly withdrawing a completion is
/// not visible until a player notices work they did is gone — and by then it is
/// in the database.
void main() {
  final season = SeasonOne.season;

  group('a season with no progress', () {
    test('the first node is current', () {
      const progress = TrailProgress.fresh;
      expect(progress.currentPosition, 1);
    });

    test('that is a starting position, not an absence', () {
      const progress = TrailProgress.fresh;
      expect(progress.completed, isEmpty);
      expect(progress.stateOf(1), NodeState.current);
      // Nothing about a fresh **season** is an error or an empty state to be
      // handled — node 1 is simply where everyone starts.
      expect(progress.isEmpty, isTrue);
    });

    test('every other node is not yet reached', () {
      const progress = TrailProgress.fresh;
      for (var position = 2; position <= 42; position++) {
        expect(progress.stateOf(position), NodeState.notYetReached);
      }
    });
  });

  group('walking the trail', () {
    test('completing the current node makes the next one current', () {
      final progress = TrailProgress.fresh.completing(1);
      expect(progress.currentPosition, 2);
      expect(progress.stateOf(1), NodeState.completed);
      expect(progress.stateOf(2), NodeState.current);
    });

    test('completing a node already completed moves nothing', () {
      final once = TrailProgress.fresh.completing(1).completing(2);
      final again = once.completing(1);
      expect(again.currentPosition, once.currentPosition);
      expect(again.completed, once.completed);
    });

    test('the trail can be walked end to end', () {
      var progress = TrailProgress.fresh;
      for (var position = 1; position <= 42; position++) {
        progress = progress.completing(position);
      }
      expect(progress.completed, hasLength(42));
      expect(progress.isSeasonComplete, isTrue);
      // A finished **season** has no current node, and that is not an error —
      // there is simply nowhere further to walk.
      expect(progress.currentPosition, isNull);
    });

    test('completed count is what the trail header shows', () {
      final progress = TrailProgress.fresh.completing(1).completing(2);
      expect(progress.completedCount, 2);
      expect(progress.total, 42);
    });
  });

  group('reaching forward', () {
    test('a node beyond the furthest reached is not yet reached', () {
      final progress = TrailProgress.fresh.completing(1);
      expect(progress.stateOf(3), NodeState.notYetReached);
      expect(progress.isOpenable(3), isFalse);
    });

    test('the current node is openable', () {
      final progress = TrailProgress.fresh.completing(1);
      expect(progress.isOpenable(2), isTrue);
    });

    test('a completed node can be reopened', () {
      final progress = TrailProgress.fresh.completing(1).completing(2);
      expect(progress.isOpenable(1), isTrue);
      expect(progress.stateOf(1), NodeState.completed);
    });

    test('reopening and recompleting a past node takes nothing away', () {
      final before = TrailProgress.fresh.completing(1).completing(2);
      final after = before.completing(1);
      expect(after.currentPosition, 3);
      expect(after.completed, containsAll(<int>[1, 2]));
      expect(after.completedCount, before.completedCount);
    });
  });

  group('nothing moves the player backwards (D-20, constraint 1)', () {
    // The **season**'s six weeks elapsing, the player being away for a year,
    // a **mistake**, an **attempt** ended in **strict mode**, and an abandoned
    // puzzle are all represented the same way here: none of them is an input
    // to this rule at all. The assertion is that the rule has no such input.
    test('elapsed time is not an input to the rule', () {
      final progress = TrailProgress.fresh.completing(1).completing(2);
      // There is no `at(DateTime)` and no decay: the same progress answers the
      // same way whenever it is asked.
      expect(progress.currentPosition, 3);
      expect(progress.completedCount, 2);
    });

    test('a season that has elapsed still holds every completion', () {
      final longAfter = season.endsAt.add(const Duration(days: 365));
      expect(season.hasElapsedAt(longAfter), isTrue);
      final progress = TrailProgress.fresh.completing(1);
      // D-109: elapsing is not ending, and it withdraws nothing.
      expect(progress.stateOf(1), NodeState.completed);
      expect(progress.isOpenable(2), isTrue);
    });

    test('there is no way to uncomplete a node', () {
      final progress = TrailProgress.fresh.completing(1).completing(2);
      // The rule offers `completing` and nothing else. A test naming the
      // absence, because the next person to want an "undo" here would be
      // adding the one operation constraint 1 has no room for.
      expect(
        TrailProgress.fresh.completing(1).completing(2).completed,
        progress.completed,
      );
    });

    test('a boss node is openable however many times it is attempted', () {
      final bossPosition = season.nodes
          .firstWhere((n) => n.type == NodeType.boss)
          .position;
      var progress = TrailProgress.fresh;
      for (var position = 1; position < bossPosition; position++) {
        progress = progress.completing(position);
      }
      expect(progress.stateOf(bossPosition), NodeState.current);
      // Attempting and failing is not an event this rule has. The **node**
      // stays current until it is completed, forever (D-22).
      expect(progress.isOpenable(bossPosition), isTrue);
      expect(progress.currentPosition, bossPosition);
    });
  });

  group('restoring from what was stored', () {
    test('a gap sends the player to the gap, and takes nothing away', () {
      // Should not arise: the only writer completes the **current node**, so
      // completions are written in order. A restored set is data from disk
      // though, so the rule answers rather than throwing.
      //
      // The answer is the first uncompleted **node**, not the furthest reached
      // plus one. That walks the player back through the gap rather than over
      // it, which looks like the less generous of the two until you check what
      // each one costs: neither withdraws a completion, and **node** 5 stays
      // completed under both. Sending them forward instead would mean a
      // **node** they never finished sits behind them permanently, with no
      // route back to it — the trail would have a hole in it that the player
      // could see and not close.
      const progress = TrailProgress(completed: <int>{1, 2, 5});
      expect(progress.currentPosition, 3);
      expect(progress.stateOf(5), NodeState.completed);
      expect(progress.isOpenable(5), isTrue);
    });

    test(
      'an out-of-range position reads as not yet reached, never an error',
      () {
        const progress = TrailProgress.fresh;
        expect(progress.stateOf(99), NodeState.notYetReached);
        expect(progress.isOpenable(0), isFalse);
      },
    );
  });
}
