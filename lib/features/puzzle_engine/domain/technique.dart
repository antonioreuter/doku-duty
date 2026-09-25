import 'rank.dart';

/// The solving techniques, and the **rank** each one first appears at (D-57).
///
/// A puzzle's rank is the hardest technique it requires, never its clue count
/// (D-07). This table is the mapping that makes that statement mean something,
/// and it is transcribed from D-57 rather than invented — with the two
/// **killer** techniques D-128 adds, each filed at its own **rank** rather than
/// at the end, because the order here is the order of difficulty.
///
/// The engine owns this table because the grader is what decides which of these
/// a puzzle needs. Persistence only counts them, because `add-rank-progression`
/// and `add-trophy-cabinet` both read per-technique statistics — and it stores
/// the names as text, so renaming one is a silent data migration.
enum Technique {
  fullHouse(Rank.greenhorn),
  nakedSingle(Rank.greenhorn),
  cageCombination(Rank.greenhorn, killerOnly: true),
  hiddenSingle(Rank.deputy),
  nakedPair(Rank.sheriff),
  pointingPair(Rank.sheriff),
  fortyFiveRule(Rank.sheriff, killerOnly: true),
  boxLineReduction(Rank.marshal),
  nakedTriple(Rank.marshal),
  hiddenPair(Rank.ranger),
  xWing(Rank.ranger),
  swordfish(Rank.legend),
  xyWing(Rank.legend),
  simpleChain(Rank.legend);

  const Technique(this.introducedAt, {this.killerOnly = false});

  /// The rank at which a puzzle may first require this technique.
  final Rank introducedAt;

  /// Whether it reasons about **cage**s, and so can only ever be required by a
  /// **killer** puzzle (D-128).
  final bool killerOnly;

  /// Every technique a puzzle of [rank] may require — this rank's and all the
  /// easier ones, since the ladder is cumulative.
  static List<Technique> upTo(Rank rank) => <Technique>[
    for (final technique in Technique.values)
      if (!technique.introducedAt.isHarderThan(rank)) technique,
  ];
}
