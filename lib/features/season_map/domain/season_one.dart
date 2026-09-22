import '../../puzzle_engine/domain/rank.dart';
import 'node_type.dart';
import 'season.dart';

/// Season one, Dust Gulch — the **season** compiled into the binary.
///
/// **This is the fallback, not a sample.** A device that has never been online
/// plays this, and so does one whose published **season** is malformed or
/// unreachable. It is the reason `add-season-map` needs no network at any
/// point, and a test asserts it satisfies every rule in [SeasonDefinition]
/// rather than trusting that the one definition nobody reviews is the one that
/// is correct.
abstract final class SeasonOne {
  static const String id = 'dust-gulch';
  static const String name = 'Dust Gulch';

  /// Where the **variant node**s stand, and the only place D-19's pacing is
  /// expressible in this change.
  ///
  /// D-19 wants something meaningful roughly every other **node** through
  /// **node** 8, stretching through the middle, and tightening again for the
  /// final five. The rewards it was written about are `add-stamps` and
  /// `add-season-pass`, neither of which exists yet — and the **chest node**s
  /// and **boss node**s that would otherwise carry the pacing have their
  /// positions fixed by D-18, none of them inside the first eight.
  ///
  /// So the **variant node**s carry it. A change of rule is the one thing this
  /// **season** has that reads as an event, and placing them here gives the
  /// opening eight the cadence D-19 asks for:
  ///
  /// - **Nodes 1–8** — meaningful at 2, 4, and 7: every other node, near enough
  /// - **The middle** — 11, 16, 21, 22, 27, 32: stretched, as asked
  /// - **The final five** — 39, 41, 42: tightened for the completion push
  ///
  /// Worth revisiting when `add-stamps` lands and there are real rewards to
  /// pace. The positions are data, so revisiting it is an edit here and a
  /// republished document, not a redesign.
  static const Set<int> variantPositions = <int>{2, 4, 7, 16, 27, 39};

  /// The **rank** ramp across the **trail**.
  ///
  /// Seven **node**s at each of the first two **rank**s, eight at each of the
  /// next three, and the last four at Legend. The ramp is generous early and
  /// short at the top on purpose: the opening is where a **season** is
  /// abandoned, and the Legend stretch is four **node**s rather than seven
  /// because a player who reaches it has already proved the point.
  ///
  /// A **rank** here is not a gate. A **node** naming a **rank** above the
  /// player's own carries the same mark a **free play** row does and opens on
  /// one tap (D-103).
  static Rank rankAt(int position) => switch (position) {
    <= 7 => Rank.greenhorn,
    <= 14 => Rank.deputy,
    <= 22 => Rank.sheriff,
    <= 30 => Rank.marshal,
    <= 38 => Rank.ranger,
    _ => Rank.legend,
  };

  /// The 42 **node**s, in order.
  static List<NodeSpec> get nodes => <NodeSpec>[
    for (var position = 1; position <= SeasonDefinition.nodeCount; position++)
      if (SeasonDefinition.chestPositions.contains(position))
        // A **chest node** bears no puzzle, so it names no **rank** (D-110).
        const NodeSpec(type: NodeType.chest)
      else
        NodeSpec(type: _typeAt(position), rank: rankAt(position)),
  ];

  /// The **season** itself, checked.
  ///
  /// Built through [SeasonDefinition.parse] like any other, so the compiled-in
  /// **season** takes exactly the path a published one takes. If this ever
  /// stops composing, it throws at first use rather than handing the player a
  /// **trail** that is not a **trail** — and the test at 2.5 fails long before
  /// that.
  static Season get season {
    final parsed = SeasonDefinition.parse(
      nodes,
      id: id,
      name: name,
      startsAt: startsAt,
    );
    return switch (parsed) {
      ValidSeason(:final season) => season,
      MalformedSeason(:final reason) => throw StateError(
        'the compiled-in season does not compose: $reason',
      ),
    };
  }

  /// When season one began.
  ///
  /// A fixed date rather than "the install date", so every player is on the
  /// same **season** clock and a published successor rotates for all of them at
  /// once. It being in the past is not a problem: D-109 holds a **season** open
  /// when its six weeks elapse with no successor, so an install made today
  /// finds a full 42-**node** trail and no countdown.
  static final DateTime startsAt = DateTime.utc(2026, 9, 21);

  static NodeType _typeAt(int position) {
    if (SeasonDefinition.bossPositions.contains(position)) return NodeType.boss;
    if (variantPositions.contains(position)) return NodeType.variant;
    return NodeType.puzzle;
  }
}
