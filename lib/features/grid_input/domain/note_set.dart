import '../../persistence/domain/note_enums.dart';
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
/// Twenty-seven bits, not nine, in three nine-bit fields:
///
/// - **presence** — which digits are marked
/// - **origin** — which of them **auto-notes** put there rather than the player
///   (D-15)
/// - **ink** — which of them are a **provisional note** rather than a **settled
///   note** (D-11)
///
/// Three facts about one candidate, packed into the one value rather than
/// tracked in maps beside it, because two structures that must agree about the
/// same cell are how they come to disagree. A digit can carry origin or ink
/// only while it is present, and removing it takes both with it.
///
/// The three are independent. A **generated note** taken into a hypothesis is
/// provisional *and* still generated: which of the two first marked it is not
/// the same question as which ink it now carries.
///
/// Origin is invisible on screen; ink is not. A **settled note** is
/// `nightIndigo` with no rule and a **provisional note** is `turquoise` and
/// underlined — the underline being the signal, because the two hues sit 1.07:1
/// apart under deuteranopia and cannot carry it alone (D-73).
///
/// [NoteKind] comes from the persistence layer rather than being redeclared
/// here. It is pure Dart, it is already the canonical name for this fact, and a
/// second copy would be the very duplication the packing above avoids.
extension type const NoteSet(int mask) {
  static const NoteSet none = NoteSet(0);

  /// How far the generated bits sit above the presence bits.
  static const int _originShift = 9;

  /// How far the provisional-ink bits sit above the presence bits.
  static const int _inkShift = 18;

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

  int get _provisional => (mask >> _inkShift) & 0x1FF;

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

  /// Whether [digit] is marked as a **provisional note**.
  bool isProvisional(int digit) =>
      contains(digit) && _provisional & _bit(digit) != 0;

  /// Which ink [digit] is written in, or null when it is not marked at all.
  NoteKind? inkOf(int digit) => !contains(digit)
      ? null
      : (isProvisional(digit) ? NoteKind.provisional : NoteKind.settled);

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

  /// The digits held as a **settled note**, ascending.
  List<int> get settled => <int>[
    for (var digit = 1; digit <= 9; digit++)
      if (contains(digit) && !isProvisional(digit)) digit,
  ];

  /// The digits held as a **provisional note**, ascending.
  List<int> get provisional => <int>[
    for (var digit = 1; digit <= 9; digit++)
      if (isProvisional(digit)) digit,
  ];

  /// Mark [digit] in [ink], remove it, or change its ink — whichever the cell
  /// calls for.
  ///
  /// Three outcomes from one control (D-90):
  ///
  /// - absent → marked in [ink]
  /// - present in [ink] → removed
  /// - present in the *other* ink → **converted**, not removed
  ///
  /// The third is the one worth arguing for. The workflow that matters is
  /// deriving candidates and *then* testing one of them, so a player who
  /// switches ink and taps a digit they already hold means "take this into the
  /// hypothesis" rather than "throw it away". Removing would make the common
  /// path two taps and a mode change, and the rarer one no cheaper.
  ///
  /// A separate remove control would be a second thing to find on a pad that
  /// has to stay reachable one-handed — and removing is still one tap, in the
  /// ink the candidate already carries.
  NoteSet toggle(int digit, {NoteKind ink = NoteKind.settled}) {
    if (!contains(digit)) return with_(digit, ink: ink);
    return inkOf(digit) == ink ? without(digit) : reInked(digit, ink);
  }

  /// Remove [digit], and its origin and ink with it.
  NoteSet without(int digit) => NoteSet(
    mask &
        ~(_bit(digit) |
            (_bit(digit) << _originShift) |
            (_bit(digit) << _inkShift)),
  );

  /// Mark [digit] as the player's, in [ink], whatever it was before.
  NoteSet with_(int digit, {NoteKind ink = NoteKind.settled}) {
    final marked = (mask | _bit(digit)) & ~(_bit(digit) << _originShift);
    return NoteSet(
      ink == NoteKind.provisional
          ? marked | (_bit(digit) << _inkShift)
          : marked & ~(_bit(digit) << _inkShift),
    );
  }

  /// Change [digit]'s ink, leaving its presence and its origin alone.
  ///
  /// Not a remove followed by a mark: the candidate never stops being there, so
  /// nothing reflows and the origin D-15 records survives the change of ink.
  /// A digit that is not marked cannot be re-inked.
  NoteSet reInked(int digit, NoteKind ink) {
    if (!contains(digit)) return this;
    return NoteSet(
      ink == NoteKind.provisional
          ? mask | (_bit(digit) << _inkShift)
          : mask & ~(_bit(digit) << _inkShift),
    );
  }

  /// Mark [digit] as **auto-notes**'s work, unless the cell already holds it.
  ///
  /// A candidate already there stays exactly as it is, in the ink it carries:
  /// the fill adds what is missing and never takes over — or re-inks — what is
  /// there. A fill states what is legal, never what the player is testing, so
  /// what it adds is always a **settled note**.
  NoteSet withGenerated(int digit) => contains(digit)
      ? this
      : NoteSet(mask | _bit(digit) | (_bit(digit) << _originShift));

  /// Every **provisional note** removed, **settled note**s untouched (D-11).
  NoteSet clearedOfProvisional() => NoteSet(
    mask &
        ~(_provisional |
            (_provisional << _originShift) |
            (_provisional << _inkShift)),
  );

  /// Every **provisional note** turned settled, nothing added or removed
  /// (D-91, **promote**).
  NoteSet promoted() => NoteSet(mask & ~(0x1FF << _inkShift));
}
