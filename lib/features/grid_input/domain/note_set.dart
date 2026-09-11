import '../../puzzle_engine/domain/candidates.dart';

/// The candidates the player has written in one cell.
///
/// A nine-bit mask, the same shape the engine's [Candidates] uses — but a
/// distinct type, because these are two different facts. [Candidates] is what
/// the solver has deduced; this is what the player believes, and the two are
/// allowed to disagree. A wrong candidate is thinking out loud, not an error
/// (D-14).
///
/// **Constraint 3 is structural here, not careful.** A digit's slot is
/// [slotOf], a pure function of the digit — so a candidate cannot move when
/// another is removed, whatever order they were marked in and however many the
/// cell holds. There is no list to compact and no index to renumber.
///
/// Eighteen bits, not nine: the low nine say which digits are marked, the high
/// nine say which of them **auto-notes** put there rather than the player
/// (D-15). Packed into the one value rather than tracked in a second map
/// beside it, because two structures that must agree about the same cell are
/// how they come to disagree. A digit can only be generated if it is present,
/// and every route that marks one by hand clears its generated bit — the
/// player has made that call themselves.
///
/// The origin is invisible on screen. Both kinds draw in the **settled note**
/// ink, in the slot the digit owns.
extension type const NoteSet(int mask) {
  static const NoteSet none = NoteSet(0);

  /// How far the generated bits sit above the presence bits.
  static const int _originShift = 9;

  factory NoteSet.of(Iterable<int> digits) {
    var mask = 0;
    for (final digit in digits) {
      mask |= _bit(digit);
    }
    return NoteSet(mask);
  }

  /// A set holding [digits], every one of them generated.
  factory NoteSet.generatedOf(Iterable<int> digits) {
    var value = 0;
    for (final digit in digits) {
      value |= _bit(digit) | (_bit(digit) << _originShift);
    }
    return NoteSet(value);
  }

  static int _bit(int digit) {
    assert(digit >= 1 && digit <= 9);
    return 1 << (digit - 1);
  }

  /// Which digits are marked, origin stripped off.
  int get _present => mask & 0x1FF;

  int get _generated => (mask >> _originShift) & 0x1FF;

  /// Where [digit] sits in the cell's three-by-three arrangement (D-10).
  ///
  /// 1 top-left, 5 centre, 9 bottom-right — always, in every cell, in every
  /// puzzle. Asked of the digit and never of the set, so there is no way for a
  /// cell's contents to influence where one of them is drawn.
  static ({int row, int column}) slotOf(int digit) {
    assert(digit >= 1 && digit <= 9);
    final index = digit - 1;
    return (row: index ~/ 3, column: index % 3);
  }

  bool contains(int digit) => _present & _bit(digit) != 0;

  /// Whether [digit] is marked *and* **auto-notes** was what marked it.
  bool isGenerated(int digit) =>
      contains(digit) && _generated & _bit(digit) != 0;

  bool get isEmpty => _present == 0;

  bool get isNotEmpty => _present != 0;

  int get length {
    var count = 0;
    for (var bits = _present; bits != 0; bits &= bits - 1) {
      count++;
    }
    return count;
  }

  /// The digits marked, ascending.
  List<int> get digits => <int>[
    for (var digit = 1; digit <= 9; digit++)
      if (contains(digit)) digit,
  ];

  /// The digits **auto-notes** marked, ascending.
  List<int> get generated => <int>[
    for (var digit = 1; digit <= 9; digit++)
      if (isGenerated(digit)) digit,
  ];

  /// The digits the player marked, ascending.
  List<int> get manual => <int>[
    for (var digit = 1; digit <= 9; digit++)
      if (contains(digit) && !isGenerated(digit)) digit,
  ];

  /// Mark [digit] if it is absent, remove it if it is there.
  ///
  /// One control both marks and unmarks: a separate remove would be a second
  /// thing to find on a pad that has to stay reachable one-handed. Either way
  /// the digit ends up the player's — marking takes over what **auto-notes**
  /// put there, and removing takes the origin with it.
  NoteSet toggle(int digit) => contains(digit) ? without(digit) : with_(digit);

  /// Remove [digit], and its origin with it.
  NoteSet without(int digit) =>
      NoteSet(mask & ~(_bit(digit) | (_bit(digit) << _originShift)));

  /// Mark [digit] as the player's, whatever it was before.
  NoteSet with_(int digit) =>
      NoteSet((mask | _bit(digit)) & ~(_bit(digit) << _originShift));

  /// Mark [digit] as **auto-notes**'s work, unless the player already holds it.
  ///
  /// A candidate the player marked stays theirs: the fill adds what is missing
  /// and never takes over what is there.
  NoteSet withGenerated(int digit) => contains(digit)
      ? this
      : NoteSet(mask | _bit(digit) | (_bit(digit) << _originShift));
}
