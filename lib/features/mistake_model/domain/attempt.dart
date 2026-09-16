import '../../puzzle_engine/domain/placement.dart';
import 'mistake.dart';

/// One run at a puzzle, and what happened to the player during it.
///
/// Immutable and pure. It sits *beside* the board rather than inside it: a
/// board is what is on the grid now, and an **attempt** is what the player did
/// to get there. Putting the tally in [Board] would make it part of the state
/// undo restores, and the count is deliberately not that.
///
/// **The count only ever rises.** Neither correcting a cell nor erasing it nor
/// undoing the placement lowers it (D-96). A tally that undo could walk back
/// measures nothing — the player would learn to undo rather than to look, and
/// "solved with no **mistake**s" would mean "solved with no **mistake**s left
/// on screen", which is a different and much easier thing. Starting the puzzle
/// again is the only route back to zero, and that is [fresh].
///
/// A **mistake** is one wrong *placement*, not one wrong cell: the same wrong
/// digit put down twice is two of them. The tally is what the player did.
final class Attempt {
  const Attempt({this.mistakes = 0});

  /// A run with nothing recorded against it yet.
  static const Attempt fresh = Attempt();

  /// How many **mistake**s **strict mode** allows before the **attempt** ends
  /// (D-04).
  ///
  /// Three, and only ever consulted when the player has opted in. Outside
  /// **strict mode** there is no limit at all — not a larger one (constraint 1).
  static const int strictLimit = 3;

  /// How many **mistake**s the player has made in this run.
  final int mistakes;

  /// How many **mistake**s remain before the **attempt** would end, never
  /// below zero.
  ///
  /// A number rather than a colour: how much is left is exactly the kind of
  /// state colour cannot carry, and a bar that reddened would be the signal
  /// resting on hue alone (constraint 5).
  int get remainingInStrictMode {
    final left = strictLimit - mistakes;
    return left < 0 ? 0 : left;
  }

  /// Whether this run has reached the **strict mode** limit.
  ///
  /// Asked of the run, and answered the same whether or not stakes are on —
  /// what *happens* at the limit is the session's business, and outside
  /// **strict mode** nothing happens at all.
  bool get hasReachedStrictLimit => mistakes >= strictLimit;

  /// Whether the puzzle has been played without a single **mistake**.
  ///
  /// Asked of the run rather than of the board, which is why an
  /// already-corrected error still costs the perfect solve.
  bool get isPerfect => mistakes == 0;

  /// The attempt after [report], counting it if [isMistake] says so.
  ///
  /// Takes the engine's report rather than a board and a digit, so this cannot
  /// reach a conclusion the engine did not supply the facts for — and cannot be
  /// handed a note at all (D-14).
  Attempt recording(PlacementReport report) =>
      isMistake(report) ? Attempt(mistakes: mistakes + 1) : this;

  @override
  bool operator ==(Object other) =>
      other is Attempt && other.mistakes == mistakes;

  @override
  int get hashCode => mistakes.hashCode;

  @override
  String toString() => 'Attempt(mistakes: $mistakes)';
}
