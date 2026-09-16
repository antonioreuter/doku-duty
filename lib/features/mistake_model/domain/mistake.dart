import '../../puzzle_engine/domain/placement.dart';

/// Whether a placement counts as a **mistake**.
///
/// Pure Dart with no Flutter import, and it takes a [PlacementReport] rather
/// than a board on purpose: the engine already establishes the facts, and a
/// rule that re-derived them from a grid could disagree with the layer that
/// reported them.
///
/// Two rules, and both are about telling a wrong answer from a wrong finger:
///
/// - A placement that disagrees with the solution is a **mistake**.
/// - Unless the cell already held the value the solution gives it, in which
///   case it never is, in either mode (D-05). The player did not get a logic
///   problem wrong; they mis-tapped.
///
/// The exemption is deliberately narrow. Overwriting a *wrong* value with
/// another wrong one is an ordinary wrong placement — only a correct value
/// being replaced is exempt.
///
/// A **unit** clash is not consulted. A digit can break no **unit** and still
/// be wrong, and it can clash with a **peer** and still be right; the engine
/// reports conflict and disagreement apart so this rule can ignore the first.
///
/// Nothing here can be asked about a note. A candidate is thinking out loud and
/// is never a **mistake** in either mode (D-14), so no note action reaches this
/// function at all — [PlacementReport] describes a placed value and nothing
/// else.
bool isMistake(PlacementReport report) =>
    !report.agreesWithSolution && !report.overwritesCorrectValue;
