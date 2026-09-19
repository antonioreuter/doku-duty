import '../../puzzle_engine/domain/rank.dart';

/// The player's **rank**, derived from what they have solved (D-102).
///
/// Pure Dart with no Flutter import, and no state of its own: the **rank** is
/// read from the **solve record**s rather than stored beside them, so there is
/// no second fact that could disagree with the records or survive a failed
/// write.
final class PlayerRank {
  const PlayerRank._();

  /// Where a player who has completed nothing stands.
  ///
  /// A starting position, not an absence. The rule always answers with a
  /// **rank** — never null, never a throw — because a caller left to handle
  /// "no rank yet" would invent its own answer and the two would drift.
  static const Rank starting = Rank.greenhorn;

  /// The hardest **rank** among [solved], or [starting] when there is none.
  static Rank from(Iterable<Rank> solved) {
    var hardest = starting;
    for (final rank in solved) {
      if (rank.isHarderThan(hardest)) hardest = rank;
    }
    return hardest;
  }

  /// The **rank**s harder than [rank].
  ///
  /// The picker marks these (D-103) and nothing locks them. Asked here rather
  /// than by comparing enum indices at the call site, so the one question
  /// "is this above the player?" has one answer — and so a later change that
  /// wants it cannot quietly arrive at a different one.
  static Set<Rank> above(Rank rank) => <Rank>{
    for (final other in Rank.values)
      if (other.isHarderThan(rank)) other,
  };
}
