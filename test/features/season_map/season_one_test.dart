import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season.dart';
import 'package:doku_duty/features/season_map/domain/season_one.dart';
import 'package:test/test.dart';

/// The compiled-in **season** is checked like any other.
///
/// It is the one definition no reviewer sees published, and every offline
/// install plays it. A **season** that ships malformed would reach every player
/// who has never been online — which is all of them on first launch.
void main() {
  test('season one composes', () {
    expect(SeasonDefinition.parse(SeasonOne.nodes), isA<ValidSeason>());
  });

  test('season one holds 42 nodes in D-18 composition', () {
    final season = SeasonOne.season;
    expect(season.nodes, hasLength(42));

    final counts = <NodeType, int>{};
    for (final node in season.nodes) {
      counts[node.type] = (counts[node.type] ?? 0) + 1;
    }
    expect(counts, SeasonDefinition.composition);
  });

  test('every puzzle-bearing node names a rank, and no chest does', () {
    for (final node in SeasonOne.season.nodes) {
      if (node.type.bearsPuzzle) {
        expect(node.rank, isNotNull, reason: 'node ${node.position}');
      } else {
        expect(node.rank, isNull, reason: 'node ${node.position}');
      }
    }
  });

  test('the ramp reaches all six ranks, easiest first', () {
    final ranks = <Rank>[
      for (final node in SeasonOne.season.nodes)
        if (node.rank != null) node.rank!,
    ];
    expect(ranks.toSet(), Rank.values.toSet());
    // Never goes backwards: a trail that eased off mid-season would make the
    // ramp meaningless and the mark flicker on and off as the player walked.
    for (var i = 1; i < ranks.length; i++) {
      expect(
        ranks[i].index >= ranks[i - 1].index,
        isTrue,
        reason: 'the ramp goes backwards at ${ranks[i - 1]} -> ${ranks[i]}',
      );
    }
  });

  test('the trail opens at Greenhorn and its last puzzle is Legend', () {
    final season = SeasonOne.season;
    expect(season.nodeAt(1).rank, Rank.greenhorn);
    final lastPuzzle = season.nodes.lastWhere((n) => n.rank != null);
    expect(lastPuzzle.rank, Rank.legend);
  });

  test('the finale boss is the last thing played, the chest behind it', () {
    final season = SeasonOne.season;
    expect(season.nodeAt(41).type, NodeType.boss);
    expect(season.nodeAt(42).type, NodeType.chest);
  });

  group("D-19's pacing", () {
    // The positions a player would read as an event: a change of rule, a
    // reward, or a boss.
    Set<int> meaningful() => <int>{
      ...SeasonOne.variantPositions,
      ...SeasonDefinition.chestPositions,
      ...SeasonDefinition.bossPositions,
    };

    test('the opening eight carry something roughly every other node', () {
      final early = meaningful().where((p) => p <= 8).toList()..sort();
      expect(early, <int>[2, 4, 7]);
    });

    test('the final five tighten again', () {
      final late = meaningful().where((p) => p >= 38).toList()..sort();
      expect(late, <int>[39, 41, 42]);
    });

    test('the middle is stretched relative to both ends', () {
      final all = meaningful().toList()..sort();
      final middle = all.where((p) => p > 8 && p < 38).toList();
      // Six events across twenty-nine nodes, against three across eight at
      // each end: the middle is demonstrably the thinner stretch.
      expect(middle.length / 29, lessThan(3 / 8));
    });
  });

  test('the season is dated in the past and still holds a full trail', () {
    // D-109: elapsing is not ending. An install made long after the start date
    // finds 42 completable **node**s, not a closed map.
    final season = SeasonOne.season;
    final longAfter = season.endsAt.add(const Duration(days: 365));
    expect(season.hasElapsedAt(longAfter), isTrue);
    expect(season.daysRemainingAt(longAfter), isNull);
    expect(season.nodes, hasLength(42));
  });
}
