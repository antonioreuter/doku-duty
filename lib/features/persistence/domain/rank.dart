/// The six ranks, in order (D-57).
///
/// A rank is the hardest technique a puzzle requires, never its clue count
/// (D-07). Nothing is graded by how many digits are given.
///
/// **Placed here because persistence is the first capability that has to name
/// it.** It is shared vocabulary rather than a persistence concept:
/// `add-puzzle-engine` owns the grader that decides a puzzle's rank, and
/// `add-rank-progression` owns the player's own rank. Either may relocate this
/// file; what must not change is the order or the names, which are fixed by
/// D-57 and appear in the glossary.
///
/// Note the collision the glossary calls out: Sheriff and Deputy are ranks *and*
/// characters, and the player is "the Deputy". In UI copy write "Sheriff rank"
/// and "the Sheriff", and never use a bare rank name as a speaker label.
enum Rank {
  greenhorn,
  deputy,
  sheriff,
  marshal,
  ranger,
  legend;

  /// Ranks below this one, easiest first.
  Iterable<Rank> get easier => Rank.values.take(index);

  bool isHarderThan(Rank other) => index > other.index;
}
