/// Which **unit**s are complete, and which a single change just completed or
/// broke.
///
/// Pure Dart with no Flutter import, so the rule that decides when the game
/// celebrates can be exercised by the plain test runner. Everything visible —
/// the lasso, the dynamite, the **cascade**, the **completion tint** — is
/// downstream of the two questions answered here.
///
/// **Completion is a structural fact, never a verdict.** A **unit** is complete
/// when it holds nine distinct digits, and nothing in this file can see the
/// puzzle's solution. That is deliberate: a board that celebrated only correct
/// **unit**s would be auto-check wearing a party hat, and auto-check is off by
/// default (D-04, constraint 1). A player who fills a row with nine distinct
/// digits has done something, whether or not it is the something the solution
/// had in mind, and the row tells them nothing more than that it is full.
library;

import '../../grid_input/domain/board.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';

/// What one change did to the completeness of the **unit**s around it.
final class CompletionChange {
  const CompletionChange({required this.completed, required this.broken});

  static const CompletionChange none = CompletionChange(
    completed: <Unit>[],
    broken: <Unit>[],
  );

  /// The **unit**s that became complete, ordered row, then column, then block.
  ///
  /// The order is the order a **cascade** chains in (D-47), fixed here rather
  /// than at the point the effects are scheduled, so there is one place it can
  /// be got wrong.
  final List<Unit> completed;

  /// The **unit**s that stopped being complete.
  final List<Unit> broken;

  bool get isEmpty => completed.isEmpty && broken.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Whether this change completed more than one **unit**, and so chains
  /// (D-47).
  bool get isCascade => completed.length > 1;
}

abstract final class UnitCompletion {
  /// Whether [unit] holds nine distinct digits on [board].
  ///
  /// Givens count exactly as placed values do. A **unit** made of nine givens
  /// is complete the moment the puzzle opens, which is why [forChange] asks
  /// what *became* complete rather than what is.
  static bool isComplete(Board board, Unit unit) {
    var seen = 0;
    for (final cell in unit.cells) {
      final digit = board.digitAt(cell);
      if (digit == Board.empty) return false;
      final bit = 1 << (digit - 1);
      if (seen & bit != 0) return false;
      seen |= bit;
    }
    return true;
  }

  /// What changing [cell] did to its row, its column, and its block.
  ///
  /// Only those three. A placement cannot change the completeness of a **unit**
  /// it is not in, so scanning the other twenty-four would be twenty-four
  /// answers already known — and this runs on the input path, where the budget
  /// is 100ms for everything (constraint 2).
  static CompletionChange forChange({
    required Board before,
    required Board after,
    required int cell,
  }) {
    List<Unit>? completed;
    List<Unit>? broken;

    // `unitsOf` returns the row, then the column, then the block, so walking it
    // in order is what puts a cascade in its D-47 order.
    for (final unit in GridGeometry.unitsOf(cell)) {
      final was = isComplete(before, unit);
      final is_ = isComplete(after, unit);
      if (was == is_) continue;
      if (is_) {
        (completed ??= <Unit>[]).add(unit);
      } else {
        (broken ??= <Unit>[]).add(unit);
      }
    }

    if (completed == null && broken == null) return CompletionChange.none;
    return CompletionChange(
      completed: List<Unit>.unmodifiable(completed ?? const <Unit>[]),
      broken: List<Unit>.unmodifiable(broken ?? const <Unit>[]),
    );
  }

  /// Every cell carrying a **completion tint**: the cells of every complete
  /// **unit**.
  ///
  /// A set, and that is the whole of D-48. A cell belonging to a complete row
  /// *and* column *and* block appears once, because a set has no second place
  /// to put it — so there is no count for a painter to read and no way for the
  /// tint to stack into mud on a nearly finished board. Making it structurally
  /// impossible beats remembering not to do it.
  ///
  /// Derived rather than stored. Nothing is written when a **unit** completes,
  /// so nothing can be written wrongly, and a reopened puzzle shows its tints
  /// because the board it restored says so (constraint 9 is untouched by this
  /// capability).
  static Set<int> tintedCells(Board board) {
    final tinted = <int>{};
    for (final unit in GridGeometry.allUnits) {
      if (!isComplete(board, unit)) continue;
      tinted.addAll(unit.cells);
    }
    return tinted;
  }

  /// Every cell holds a value and no **unit** repeats a digit.
  ///
  /// Asked of the board, which asks the engine, so there is one definition of
  /// finished in the codebase. A board that is full and repeats a digit is not
  /// finished — and this reports only that, never which cell is wrong. Saying
  /// that is **strict mode**'s job and nothing else's (constraint 1).
  static bool isBoardComplete(Board board) => board.isComplete;
}
