/// Why every syncable row carries a stamp, a pending flag, and a device.
///
/// **Nothing reads these yet.** They exist because adding them later would mean
/// migrating live saved games, and D-33 makes those saves the thing this whole
/// layer protects. This is the same argument D-15 makes for note provenance:
/// the cheap moment to model something is before there is player data in it.
///
/// What they are for, from `docs/TECH_STACK.md` §2a — recorded here because the
/// sync change is far enough away that the columns will not explain themselves:
///
/// - **`updatedAt`** — sync is last-write-wins on a small document. Without a
///   per-row stamp there is nothing to compare, and the merge degenerates into
///   "whichever device synced most recently wins", which loses work silently.
///
/// - **`pendingUpload`** — local state is never deleted until the upload is
///   confirmed. The flag is what makes "confirmed" a thing the client can know;
///   without it, a failed upload is indistinguishable from a successful one.
///
/// - **`deviceOrigin`** on a save — when a signing-in player already has state
///   in the account, §2a requires showing **both saves** and letting them pick,
///   never merging automatically. A choice between two saves has to be able to
///   name them, and "the one from your other phone" is the only label a player
///   can act on.
///
/// The rule those three exist to serve, stated plainly so it survives:
/// **never merge automatically, and never delete local state until the upload
/// is confirmed.** Merged streaks and duplicated trophies are worse than either
/// save alone.
library;

/// The tables whose rows sync. Named so the guarantee can be asserted rather
/// than assumed — a new syncable table that forgets the columns is a migration
/// nobody planned.
const List<String> syncableTables = <String>[
  'notes',
  'puzzle_saves',
  'solved_puzzles',
  'lifetime_stats',
  'technique_stats',
  'settings',
  // Permanent progression, like the counters beside it: a **lesson** seen on
  // one device should not be taught again on another (D-17). Cheap to sync —
  // a row is an id and nothing else.
  'seen_lessons',
];
