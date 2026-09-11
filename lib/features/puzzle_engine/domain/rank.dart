/// The six ranks, in order (D-57).
///
/// A rank is the hardest technique a puzzle requires, never its clue count
/// (D-07). Nothing is graded by how many digits are given.
///
/// Shared vocabulary, owned by the engine because the grader is what decides a
/// puzzle's rank. It lived in the persistence layer only while persistence was
/// the first capability that had to name it. The names are written into the
/// database as text, so renaming one is a silent data migration; the order and
/// the names are fixed by D-57 and appear in the glossary.
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
