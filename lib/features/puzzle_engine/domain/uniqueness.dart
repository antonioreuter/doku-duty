import 'grid.dart';
import 'grid_geometry.dart';

/// Whether a puzzle has no solution, exactly one, or more than one.
///
/// Deliberately three answers rather than a boolean. "Not unique" collapses two
/// different faults — a grid nobody can finish and a grid anybody can finish two
/// ways — and constraint 8 needs them apart.
sealed class UniquenessResult {
  const UniquenessResult();
}

/// The clues cannot all be true at once, or cannot be completed at all.
final class NoSolution extends UniquenessResult {
  const NoSolution();
}

/// Exactly one completion exists (D-08).
final class UniqueSolution extends UniquenessResult {
  const UniqueSolution(this.solution);

  final Grid solution;
}

/// More than one completion exists. Two of them are carried as the evidence.
final class AmbiguousSolutions extends UniquenessResult {
  const AmbiguousSolutions({required this.first, required this.second});

  final Grid first;
  final Grid second;
}

/// Answer whether [grid] has exactly one solution, by exhaustive search.
///
/// **Independent of the technique solver, on purpose.** A technique solver that
/// fails to finish tells you it ran out of techniques, not that the puzzle is
/// ambiguous — the two answer different questions, and constraint 8 rests on the
/// one asked here. Nothing in this file consults a named technique.
///
/// The search stops as soon as a second solution appears, so the empty grid
/// returns immediately rather than counting its 6.67e21 completions.
UniquenessResult checkUniqueness(Grid grid) {
  final search = _Search(grid);
  if (!search.seedFromClues()) return const NoSolution();
  search.run();
  return switch (search.found.length) {
    0 => const NoSolution(),
    1 => UniqueSolution(search.found.first),
    _ => AmbiguousSolutions(first: search.found[0], second: search.found[1]),
  };
}

/// Depth-first search over the least-constrained-cell-last ordering.
///
/// Candidates are nine-bit masks and placement is a mask operation, so the hot
/// loop allocates nothing.
final class _Search {
  _Search(this.grid)
    : _digits = List<int>.filled(GridGeometry.cellCount, Grid.blank),
      _candidates = List<int>.filled(GridGeometry.cellCount, _allDigits);

  static const int _allDigits = 0x1FF;

  final Grid grid;
  final List<int> _digits;
  final List<int> _candidates;

  /// At most two: the search stops there.
  final List<Grid> found = <Grid>[];

  /// Place every clue, rejecting the grid if two of them conflict.
  bool seedFromClues() {
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      final digit = grid.digitAt(cell);
      if (digit == Grid.blank) continue;
      if (_candidates[cell] & _bit(digit) == 0) return false;
      if (!_place(cell, digit)) return false;
    }
    return true;
  }

  void run() => _descend();

  void _descend() {
    var target = -1;
    var fewest = 10;
    for (var cell = 0; cell < GridGeometry.cellCount; cell++) {
      if (_digits[cell] != Grid.blank) continue;
      final count = _bitCount(_candidates[cell]);
      if (count == 0) return; // A dead end; a contradiction, not a solution.
      if (count < fewest) {
        fewest = count;
        target = cell;
        if (count == 1) break;
      }
    }

    if (target == -1) {
      found.add(Grid.fromDigits(List<int>.of(_digits)));
      return;
    }

    for (
      var digit = GridGeometry.minDigit;
      digit <= GridGeometry.maxDigit;
      digit++
    ) {
      if (_candidates[target] & _bit(digit) == 0) continue;
      final undo = _snapshot();
      if (_place(target, digit)) {
        _descend();
        if (found.length >= 2) return; // Two is the whole answer.
      }
      _restore(undo);
    }
  }

  bool _place(int cell, int digit) {
    _digits[cell] = digit;
    _candidates[cell] = 0;
    final removed = ~_bit(digit);
    for (final peer in GridGeometry.peersOf(cell)) {
      if (_digits[peer] != Grid.blank) continue;
      final before = _candidates[peer];
      final after = before & removed;
      if (after == 0) return false;
      _candidates[peer] = after;
    }
    return true;
  }

  _Snapshot _snapshot() =>
      _Snapshot(List<int>.of(_digits), List<int>.of(_candidates));

  void _restore(_Snapshot snapshot) {
    _digits.setAll(0, snapshot.digits);
    _candidates.setAll(0, snapshot.candidates);
  }

  static int _bit(int digit) => 1 << (digit - 1);

  static int _bitCount(int mask) {
    var count = 0;
    for (var bits = mask; bits != 0; bits &= bits - 1) {
      count++;
    }
    return count;
  }
}

final class _Snapshot {
  const _Snapshot(this.digits, this.candidates);

  final List<int> digits;
  final List<int> candidates;
}
