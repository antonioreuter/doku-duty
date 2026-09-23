/// What earns an **award**.
///
/// A closed set, because every one of these is an event some other capability
/// already records — this capability adds no new way to earn anything, it only
/// says which recorded events are worth keeping.
enum AwardTrigger {
  /// A **boss node** completed. Two per **season** (D-18).
  boss,

  /// The last **node** of a **season** completed.
  ///
  /// D-119 frames this as the case *closing* rather than the map expiring. The
  /// **trophy** captures the territory and the date so that `add-deputy-avatar`
  /// can draw it as a closed case later without re-deriving anything.
  seasonComplete,

  /// Every day of a calendar month on the **calendar** (`docs/SPEC.md` §5.3).
  perfectMonth,

  /// A **rank** reached. Permanent: it belongs to no **season**.
  rankReached,
}

/// A **trophy** a **season** offers, or a permanent one on offer always.
///
/// Before it is earned it is **unfiled** (D-21); once earned it is a
/// **trophy**. The distinction is the player's state, not the **award**'s —
/// this type is the *offer*, and it is identical whether or not anyone has
/// taken it up.
class Award {
  const Award({
    required this.id,
    required this.name,
    required this.trigger,
    this.seasonId,
    this.nodePosition,
    this.rankName,
  });

  /// Stable across publishes. **Progress is keyed to it**, so changing an id
  /// orphans every **trophy** already minted under the old one.
  final String id;

  /// What the **cabinet** shows. "Ace's ledger, recovered".
  final String name;

  final AwardTrigger trigger;

  /// The **season** this belongs to, or null for a permanent **award**.
  ///
  /// A permanent one is always on offer and survives every rotation without
  /// needing a document to declare it.
  final String? seasonId;

  /// Which **node** earns it, for [AwardTrigger.boss].
  final int? nodePosition;

  /// Which **rank** earns it, for [AwardTrigger.rankReached].
  final String? rankName;

  bool get isPermanent => seasonId == null;

  /// Whether this **award** mints a new **trophy** each time it is earned.
  ///
  /// Only a perfect month does: `docs/SPEC.md` §5.3 gives "a trophy for that
  /// month", so April and May are two **trophy**s, not one earned twice. Every
  /// other **award** marks a thing that happens once.
  bool get isRepeatable => trigger == AwardTrigger.perfectMonth;

  /// The **trophy** this repeatable **award** mints for one month.
  ///
  /// Its id extends this one, so the **cabinet** can find every month under
  /// the offer that earned it; minting the same month twice still collides
  /// with itself and mints once.
  Award forMonth(int year, int month) {
    assert(isRepeatable, '$id mints once, not per month');
    final key = '$year-${month.toString().padLeft(2, '0')}';
    return Award(
      id: '$id.$key',
      name: '${_monthNames[month - 1]} $year, without a gap',
      trigger: trigger,
      seasonId: seasonId,
    );
  }

  /// Whether [trophyId] was minted by this **award** — itself, or one of its
  /// months.
  bool minted(String trophyId) =>
      trophyId == id || (isRepeatable && trophyId.startsWith('$id.'));

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Reads one published entry, or null if it cannot be read.
  ///
  /// **Per entry, never per document.** A publishing mistake costs one
  /// **award** and leaves the rest of the **cabinet** whole — the same refusal
  /// rule the **season** document and the daily schedule already use (D-125).
  static Award? fromJson(Object? raw, {required String seasonId}) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final trigger = raw['trigger'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    if (trigger is! String) return null;

    final parsed = switch (trigger) {
      'boss' => AwardTrigger.boss,
      'season_complete' => AwardTrigger.seasonComplete,
      _ => null,
    };
    if (parsed == null) return null;

    // A boss award without a position cannot be matched to the completion that
    // earns it, so it is refused rather than left unearnable.
    final position = raw['node_position'];
    if (parsed == AwardTrigger.boss && position is! int) return null;

    return Award(
      id: id,
      name: name,
      trigger: parsed,
      seasonId: seasonId,
      nodePosition: position is int ? position : null,
    );
  }

  /// Reads the `awards` key of a published **season**.
  ///
  /// An absent or unreadable list yields none, which the catalogue treats as
  /// "fall back", not as "this **season** offers nothing".
  static List<Award> listFromJson(Object? raw, {required String seasonId}) {
    if (raw is! List) return const <Award>[];
    return <Award>[
      for (final entry in raw)
        if (Award.fromJson(entry, seasonId: seasonId) case final Award a) a,
    ];
  }

  @override
  bool operator ==(Object other) => other is Award && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Award($id)';
}
