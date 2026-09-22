import 'package:doku_duty/features/puzzle_engine/domain/rank.dart';
import 'package:doku_duty/features/season_map/domain/node_type.dart';
import 'package:doku_duty/features/season_map/domain/season.dart';
import 'package:test/test.dart';

/// A **season** definition is 42 **node**s or it is not a **season**.
///
/// Every test here asserts a *rejection* rather than a repair. A definition
/// that does not compose is refused whole: trimming 44 **node**s to 42 or
/// padding 40 up to it would produce a **season** nobody authored, and the
/// player would walk a trail that no reviewer ever saw.
void main() {
  group('composition', () {
    test('a well-formed season is accepted and holds 42 nodes', () {
      final season = SeasonDefinition.parse(wellFormedNodes());
      expect(season, isA<ValidSeason>());
      expect((season as ValidSeason).season.nodes, hasLength(42));
    });

    test('the composition is 30 puzzle, 6 variant, 4 chest, 2 boss (D-18)', () {
      final season = SeasonDefinition.parse(wellFormedNodes()) as ValidSeason;
      final counts = <NodeType, int>{};
      for (final node in season.season.nodes) {
        counts[node.type] = (counts[node.type] ?? 0) + 1;
      }
      expect(counts[NodeType.puzzle], 30);
      expect(counts[NodeType.variant], 6);
      expect(counts[NodeType.chest], 4);
      expect(counts[NodeType.boss], 2);
    });

    test('a season of the wrong length is rejected, not trimmed or padded', () {
      for (final length in const <int>[0, 41, 43]) {
        final nodes = wellFormedNodes();
        final wrong = length < nodes.length
            ? nodes.sublist(0, length)
            : <NodeSpec>[...nodes, nodes.last];
        expect(
          SeasonDefinition.parse(wrong),
          isA<MalformedSeason>(),
          reason: '$length nodes is not a season',
        );
      }
    });

    test('a season with the wrong type mix is rejected', () {
      // 31 puzzle nodes and 5 variant: still 42, still wrong.
      final nodes = wellFormedNodes();
      final index = nodes.indexWhere((n) => n.type == NodeType.variant);
      nodes[index] = NodeSpec(type: NodeType.puzzle, rank: Rank.sheriff);
      expect(SeasonDefinition.parse(nodes), isA<MalformedSeason>());
    });
  });

  group('where chests and bosses fall', () {
    test('chests stand at 25/50/75/100% of the trail', () {
      final season = SeasonDefinition.parse(wellFormedNodes()) as ValidSeason;
      final chests = <int>[
        for (var i = 0; i < 42; i++)
          if (season.season.nodes[i].type == NodeType.chest) i + 1,
      ];
      expect(chests, <int>[11, 21, 32, 42]);
    });

    test('bosses stand at the midpoint and the finale', () {
      final season = SeasonDefinition.parse(wellFormedNodes()) as ValidSeason;
      final bosses = <int>[
        for (var i = 0; i < 42; i++)
          if (season.season.nodes[i].type == NodeType.boss) i + 1,
      ];
      expect(bosses, <int>[22, 41]);
    });

    test('a chest in the wrong position is rejected', () {
      final nodes = wellFormedNodes();
      // Swap the first chest one place earlier: composition still correct.
      nodes[9] = const NodeSpec(type: NodeType.chest);
      nodes[10] = const NodeSpec(type: NodeType.puzzle, rank: Rank.greenhorn);
      expect(SeasonDefinition.parse(nodes), isA<MalformedSeason>());
    });

    test('a boss in the wrong position is rejected', () {
      final nodes = wellFormedNodes();
      nodes[21] = const NodeSpec(type: NodeType.puzzle, rank: Rank.marshal);
      nodes[22] = const NodeSpec(type: NodeType.boss, rank: Rank.marshal);
      expect(SeasonDefinition.parse(nodes), isA<MalformedSeason>());
    });
  });

  group('a node names a rank, never a puzzle (D-110)', () {
    test('every puzzle-bearing node names a rank', () {
      final season = SeasonDefinition.parse(wellFormedNodes()) as ValidSeason;
      for (final node in season.season.nodes) {
        if (!node.type.bearsPuzzle) continue;
        expect(
          node.rank,
          isNotNull,
          reason: 'node ${node.position} bears a puzzle and must name a rank',
        );
      }
    });

    test('a puzzle-bearing node with no rank is rejected', () {
      final nodes = wellFormedNodes();
      nodes[0] = const NodeSpec(type: NodeType.puzzle);
      expect(SeasonDefinition.parse(nodes), isA<MalformedSeason>());
    });

    test('a chest node bears no puzzle and needs no rank', () {
      expect(NodeType.chest.bearsPuzzle, isFalse);
      final season = SeasonDefinition.parse(wellFormedNodes()) as ValidSeason;
      final chest = season.season.nodes.firstWhere(
        (n) => n.type == NodeType.chest,
      );
      expect(chest.rank, isNull);
    });

    test('variant and boss nodes bear a puzzle', () {
      expect(NodeType.variant.bearsPuzzle, isTrue);
      expect(NodeType.boss.bearsPuzzle, isTrue);
    });

    // The negative half of D-110, and the one worth a test of its own: the
    // model has nowhere to *put* a puzzle id, so a definition cannot pin a
    // **season** to a **pack** version even by accident.
    test('a node has no field naming a puzzle', () {
      final season = SeasonDefinition.parse(wellFormedNodes()) as ValidSeason;
      final node = season.season.nodes.first;
      expect(
        node.toJson().keys,
        isNot(contains(anyOf('puzzle', 'puzzleId', 'puzzle_id', 'seed'))),
      );
    });
  });
}

/// 42 **node**s in the composition D-18 requires, for a test to bend.
List<NodeSpec> wellFormedNodes() {
  const chests = <int>{11, 21, 32, 42};
  const bosses = <int>{22, 41};
  const variants = <int>{6, 14, 19, 27, 34, 38};
  return <NodeSpec>[
    for (var position = 1; position <= 42; position++)
      if (chests.contains(position))
        const NodeSpec(type: NodeType.chest)
      else
        NodeSpec(
          type: bosses.contains(position)
              ? NodeType.boss
              : variants.contains(position)
              ? NodeType.variant
              : NodeType.puzzle,
          rank: _rampAt(position),
        ),
  ];
}

Rank _rampAt(int position) => switch (position) {
  <= 7 => Rank.greenhorn,
  <= 14 => Rank.deputy,
  <= 22 => Rank.sheriff,
  <= 30 => Rank.marshal,
  <= 38 => Rank.ranger,
  _ => Rank.legend,
};
