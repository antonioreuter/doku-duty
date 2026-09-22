import '../../design_system/domain/season_theme.dart';
import '../../puzzle_engine/domain/rank.dart';
import 'node_type.dart';

/// One **node** as a **season** document describes it, before it is placed.
///
/// A [NodeSpec] names a [NodeType] and, where the type bears a puzzle, a
/// [Rank]. **It has nowhere to put a puzzle id, and that absence is the
/// decision** (D-110): a **season** that named its 42 boards would be pinned to
/// a **pack** version, and a top-up would strand its **node**s or silently
/// repoint them.
class NodeSpec {
  const NodeSpec({required this.type, this.rank});

  final NodeType type;

  /// The **rank** a puzzle-bearing **node** is played at, or null for a
  /// **chest node**, which bears no puzzle.
  final Rank? rank;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.key,
    if (rank != null) 'rank': rank!.name,
  };

  static NodeSpec? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final type = NodeType.fromKey('${raw['type']}');
    if (type == null) return null;
    final rankKey = raw['rank'];
    if (rankKey == null) return NodeSpec(type: type);
    for (final rank in Rank.values) {
      if (rank.name == rankKey) return NodeSpec(type: type, rank: rank);
    }
    // A named **rank** that does not resolve is a malformed **node**, not a
    // **node** with no **rank** — falling back to "none" would turn a typo into
    // a puzzle-bearing node nobody can open.
    return null;
  }
}

/// A **node** in a **season**, at its position on the **trail**.
///
/// Position is 1-based, because every player-facing reference to a **node** is
/// ("Node 14") and an off-by-one between the label and the index is the kind of
/// defect that survives review.
class SeasonNode {
  const SeasonNode({required this.position, required this.type, this.rank});

  /// 1 … 42.
  final int position;
  final NodeType type;
  final Rank? rank;

  Map<String, Object?> toJson() => <String, Object?>{
    'position': position,
    'type': type.key,
    if (rank != null) 'rank': rank!.name,
  };
}

/// A **season**: 42 **node**s, a name, a start, and a length.
///
/// Constructed only through [SeasonDefinition.parse], so an instance of this
/// class has already been checked against D-18's composition. Nothing else may
/// build one — a **season** that skipped the check is the one the player would
/// walk.
class Season {
  const Season._({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.length,
    required this.nodes,
    required this.theme,
  });

  final String id;

  /// The territory's name, shown on the **trail**. "Dust Gulch".
  final String name;

  final DateTime startsAt;

  /// Six weeks (D-18). Carried rather than assumed so a **season** document can
  /// state it, and so nothing computes six weeks from a constant in two places.
  final Duration length;

  final List<SeasonNode> nodes;

  /// What this territory repaints.
  ///
  /// **[SeasonTheme] has a field for each of the two surfaces and no field of
  /// any kind for a state colour** — so D-55 is kept by the type rather than by
  /// this class remembering to. A **season** document asking to repaint
  /// `cactusGreen` is not refused so much as unable to say it: there is nowhere
  /// for the value to go.
  final SeasonTheme theme;

  DateTime get endsAt => startsAt.add(length);

  /// The **node** at [position], 1-based.
  SeasonNode nodeAt(int position) => nodes[position - 1];

  /// How many days remain, or null once the **season** has run out.
  ///
  /// Null rather than a negative number, and the distinction is D-109: a
  /// **season** with no successor holds open, and a countdown reading "-4 days"
  /// would tell a player they are late for something that cannot be late.
  /// Callers show nothing where this is null; they never show the negative.
  int? daysRemainingAt(DateTime now) {
    final remaining = endsAt.difference(now);
    if (remaining.isNegative) return null;
    return remaining.inDays;
  }

  /// Whether the **season**'s six weeks have elapsed.
  ///
  /// This is *not* "the **season** is over". A **season** ends when there is a
  /// successor to rotate to, never on the calendar alone (D-109).
  bool hasElapsedAt(DateTime now) => !now.isBefore(endsAt);
}

/// The result of reading a **season** definition.
sealed class SeasonDefinition {
  const SeasonDefinition();

  /// Checks [specs] against D-18 and places them on the **trail**.
  ///
  /// **Rejects rather than repairs.** A definition that does not compose comes
  /// back [MalformedSeason] and the caller keeps whatever **season** was already
  /// in force. Trimming 44 **node**s to 42, or padding 40 up to it, would
  /// produce a **season** no one authored and no one reviewed.
  static SeasonDefinition parse(
    List<NodeSpec> specs, {
    String id = 'season-1',
    String name = 'Dust Gulch',
    DateTime? startsAt,
    Duration length = sixWeeks,
    SeasonTheme? theme,
  }) {
    if (specs.length != nodeCount) {
      return MalformedSeason(
        'a season is $nodeCount nodes, not ${specs.length}',
      );
    }

    final counts = <NodeType, int>{};
    for (final spec in specs) {
      counts[spec.type] = (counts[spec.type] ?? 0) + 1;
    }
    for (final entry in composition.entries) {
      if (counts[entry.key] != entry.value) {
        return MalformedSeason(
          'a season holds ${entry.value} ${entry.key.key} nodes, '
          'not ${counts[entry.key] ?? 0}',
        );
      }
    }

    for (var i = 0; i < specs.length; i++) {
      final position = i + 1;
      final spec = specs[i];

      final expected = _typeRequiredAt(position);
      if (expected != null && spec.type != expected) {
        return MalformedSeason(
          'node $position must be a ${expected.key} node, '
          'not a ${spec.type.key} one',
        );
      }
      if (expected == null &&
          (spec.type == NodeType.chest || spec.type == NodeType.boss)) {
        return MalformedSeason(
          'node $position is a ${spec.type.key} node, and no '
          '${spec.type.key} node stands there',
        );
      }
      if (spec.type.bearsPuzzle && spec.rank == null) {
        return MalformedSeason(
          'node $position bears a puzzle and names no rank',
        );
      }
    }

    return ValidSeason(
      Season._(
        id: id,
        name: name,
        startsAt: startsAt ?? DateTime.utc(2026, 1, 1),
        length: length,
        theme: theme ?? SeasonTheme.defaultTheme,
        nodes: <SeasonNode>[
          for (var i = 0; i < specs.length; i++)
            SeasonNode(
              position: i + 1,
              type: specs[i].type,
              rank: specs[i].rank,
            ),
        ],
      ),
    );
  }

  /// Reads a **season** straight from a decoded document.
  static SeasonDefinition fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) {
      return const MalformedSeason('a season is a JSON object');
    }
    final rawNodes = raw['nodes'];
    if (rawNodes is! List) {
      return const MalformedSeason('a season carries a list of nodes');
    }

    final specs = <NodeSpec>[];
    for (final entry in rawNodes) {
      final spec = NodeSpec.fromJson(entry);
      if (spec == null) {
        return const MalformedSeason('a node is malformed');
      }
      specs.add(spec);
    }

    final id = raw['id'];
    final name = raw['name'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return const MalformedSeason('a season carries an id and a name');
    }

    final startsAt = DateTime.tryParse('${raw['starts_at']}');
    if (startsAt == null) {
      return const MalformedSeason('a season carries an ISO-8601 starts_at');
    }

    final rawDays = raw['length_days'];
    final days = rawDays is int
        ? rawDays
        : rawDays is double && rawDays == rawDays.roundToDouble()
        ? rawDays.toInt()
        : rawDays is String
        ? int.tryParse(rawDays)
        : null;
    if (days == null || days <= 0) {
      return const MalformedSeason('a season lasts a whole number of days');
    }

    return parse(
      specs,
      id: id,
      name: name,
      startsAt: startsAt,
      length: Duration(days: days),
      theme: _theme(raw['palette'], id: id, name: name),
    );
  }

  /// The territory's repaint, or the default one.
  ///
  /// Absent is the common case and is not a degradation — most **season**s will
  /// ship with the default surfaces. A malformed palette falls back the same
  /// way, because a **season** is worth having with the wrong sand colour and
  /// is not worth losing over one.
  static SeasonTheme? _theme(
    Object? raw, {
    required String id,
    required String name,
  }) {
    if (raw is! Map<String, Object?>) return null;
    final bone = _rgb(raw['bone']);
    final sand = _rgb(raw['sand']);
    if (bone == null || sand == null) return null;
    return SeasonTheme(
      id: id,
      name: name,
      bone: bone,
      sand: sand,
      hairline: _rgb(raw['hairline']),
      surfaceDepth: _rgb(raw['surface_depth']),
    );
  }

  /// A `0xRRGGBB` value, written as a number or as a `"#RRGGBB"` string.
  static int? _rgb(Object? raw) {
    final value = switch (raw) {
      final int v => v,
      final double v when v == v.roundToDouble() => v.toInt(),
      final String v => int.tryParse(v.replaceFirst('#', ''), radix: 16),
      _ => null,
    };
    if (value == null || value < 0 || value > 0xFFFFFF) return null;
    return value;
  }

  /// Six weeks (D-18).
  static const Duration sixWeeks = Duration(days: 42);

  /// 42 **node**s (D-18). The same number as the days, and a coincidence — one
  /// is a count of stops, the other a length of time.
  static const int nodeCount = 42;

  /// What a **season** is made of (D-18).
  static const Map<NodeType, int> composition = <NodeType, int>{
    NodeType.puzzle: 30,
    NodeType.variant: 6,
    NodeType.chest: 4,
    NodeType.boss: 2,
  };

  /// Where the **chest node**s stand: 25/50/75/100% of the **trail** (D-18).
  ///
  /// Rounded up, so the quarter marks land on 11, 21, 32, and 42 rather than
  /// on a fraction. The last is the finale's chest and is deliberately the
  /// 42nd — 100% means the end of the trail, not near it.
  static const Set<int> chestPositions = <int>{11, 21, 32, 42};

  /// Where the **boss node**s stand: the midpoint and the finale (D-18).
  ///
  /// 41 rather than 42 because the 42nd is the completion chest. The finale
  /// boss is the last thing played; the chest behind it is the reward for it.
  static const Set<int> bossPositions = <int>{22, 41};

  static NodeType? _typeRequiredAt(int position) {
    if (chestPositions.contains(position)) return NodeType.chest;
    if (bossPositions.contains(position)) return NodeType.boss;
    return null;
  }
}

final class ValidSeason extends SeasonDefinition {
  const ValidSeason(this.season);

  final Season season;
}

final class MalformedSeason extends SeasonDefinition {
  const MalformedSeason(this.reason);

  /// Why it was refused. For a log and for a test — never for the player, who
  /// is told nothing and keeps playing the **season** already in force.
  final String reason;
}
