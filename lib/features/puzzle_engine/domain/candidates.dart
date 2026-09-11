import 'grid_geometry.dart';

/// The digits still possible in one cell, held as a nine-bit mask.
///
/// A mask rather than a `Set<int>`: elimination is the solver's inner loop, and
/// a mask makes it one bitwise operation with no allocation. The grader runs the
/// whole technique ladder over a puzzle, and a hint will run one step while a
/// player waits.
extension type const Candidates(int mask) {
  /// Every digit one to nine.
  static const Candidates all = Candidates(0x1FF);

  /// No digit at all — an exhausted cell, or a cell that already holds a value.
  static const Candidates none = Candidates(0);

  factory Candidates.of(Iterable<int> digits) {
    var mask = 0;
    for (final digit in digits) {
      mask |= _bit(digit);
    }
    return Candidates(mask);
  }

  /// The single digit [digit], for building a set one bit at a time.
  factory Candidates.only(int digit) => Candidates(_bit(digit));

  static int _bit(int digit) {
    assert(digit >= GridGeometry.minDigit && digit <= GridGeometry.maxDigit);
    return 1 << (digit - 1);
  }

  bool contains(int digit) => mask & _bit(digit) != 0;

  bool containsAll(Candidates other) => mask & other.mask == other.mask;

  bool get isEmpty => mask == 0;

  bool get isNotEmpty => mask != 0;

  int get length {
    var count = 0;
    for (var bits = mask; bits != 0; bits &= bits - 1) {
      count++;
    }
    return count;
  }

  /// The digits, ascending.
  List<int> get digits => <int>[
    for (
      var digit = GridGeometry.minDigit;
      digit <= GridGeometry.maxDigit;
      digit++
    )
      if (contains(digit)) digit,
  ];

  /// The only digit left, or null when there is more than one or none.
  int? get single {
    if (mask == 0 || mask & (mask - 1) != 0) return null;
    return mask.bitLength;
  }

  /// The same set without [digit]. Every other digit keeps its bit, so removing
  /// a candidate never disturbs the ones that remain.
  Candidates without(int digit) => Candidates(mask & ~_bit(digit));

  // Named with a trailing underscore because `with` is a reserved word.
  Candidates with_(int digit) => Candidates(mask | _bit(digit));

  Candidates union(Candidates other) => Candidates(mask | other.mask);

  Candidates intersection(Candidates other) => Candidates(mask & other.mask);

  Candidates difference(Candidates other) => Candidates(mask & ~other.mask);
}
