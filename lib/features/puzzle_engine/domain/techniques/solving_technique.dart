import '../deduction.dart';
import '../solver_state.dart';
import '../technique.dart';

/// One named technique from the D-57 ladder, able to run on its own.
///
/// Runnable in isolation on purpose: an over-eager technique grades puzzles
/// *easier* than they are, and the symptom is a player finding a Ranger puzzle
/// trivial — which nobody reports as a bug. The only way to catch that is to ask
/// one technique, on a position where it must say nothing.
abstract base class SolvingTechnique {
  const SolvingTechnique();

  /// The name this technique deduces under. Never a name outside the ladder.
  Technique get technique;

  /// The first deduction this technique justifies in [state], or null when it
  /// justifies none. Never returns a deduction that changes nothing.
  Deduction? deduce(SolverState state);
}

/// Number of digits in a candidate mask.
int bitCount(int mask) {
  var count = 0;
  for (var bits = mask; bits != 0; bits &= bits - 1) {
    count++;
  }
  return count;
}

/// The digits in a candidate mask, ascending.
List<int> digitsOf(int mask) => <int>[
  for (var digit = 1; digit <= 9; digit++)
    if (mask & (1 << (digit - 1)) != 0) digit,
];

/// Every combination of [size] items from [items], in index order.
Iterable<List<T>> combinations<T>(List<T> items, int size) sync* {
  if (size > items.length) return;
  final indices = List<int>.generate(size, (i) => i);
  while (true) {
    yield <T>[for (final index in indices) items[index]];
    var pivot = size - 1;
    while (pivot >= 0 && indices[pivot] == items.length - size + pivot) {
      pivot--;
    }
    if (pivot < 0) return;
    indices[pivot]++;
    for (var i = pivot + 1; i < size; i++) {
      indices[i] = indices[i - 1] + 1;
    }
  }
}
