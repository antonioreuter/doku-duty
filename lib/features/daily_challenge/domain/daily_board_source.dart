import '../../puzzle_engine/domain/rank.dart';

/// What the **daily challenge** needs of a board.
///
/// Narrower than the stored puzzle row on purpose: the domain layer of this
/// capability takes no Flutter and no Drift import, so the resolver can be
/// tested against a list in memory.
abstract interface class DailyBoard {
  String get id;
  Rank get rank;
  String get clues;
  String get solution;

  /// Whether this is a **killer** board. The **daily challenge** never offers
  /// one (D-127), so the resolver refuses it rather than trusting a schedule.
  bool get isKiller;
}

/// Where boards come from: the installed **pack**, and nowhere else.
///
/// **There is deliberately no route to the generator or the grader here.**
/// D-32 puts both off the device, and constraint 8 depends on every board
/// having been uniqueness-checked before it shipped. Widening this interface
/// with anything that *makes* a puzzle would break both without any test
/// noticing, so it stays two lookups.
abstract interface class DailyBoardSource {
  /// The board with this id, or null if the installed **pack**s lack it.
  Future<DailyBoard?> byId(String id);

  /// A classic board of [rank] chosen by [seed], deterministically — never a
  /// **killer** one (D-127).
  ///
  /// Must not consider whether the puzzle is already solved. `nextUnsolved` is
  /// the right call for **free play** and the wrong one here: what a player has
  /// solved differs between players, and the **daily challenge** is supposed to
  /// be the same board for everybody who still has the schedule.
  Future<DailyBoard?> byRankAndSeed(Rank rank, int seed);
}
