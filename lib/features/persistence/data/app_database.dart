import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app_database.steps.dart';

import '../domain/note_enums.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../../puzzle_engine/domain/technique.dart';

export '../domain/note_enums.dart';
export '../../puzzle_engine/domain/rank.dart';
export '../../puzzle_engine/domain/technique.dart';

part 'app_database.g.dart';

/// The last usable remote config, kept so a player who was online once stays
/// configured offline afterwards.
///
/// **Not player state.** Losing it is harmless — the compiled-in fallback
/// answers every value — so it inherits none of the write-on-every-change
/// discipline that protects notes (D-33). It lives here rather than in a file
/// only because there is already one durable store, and a second place data
/// lives is a cost of its own.
class ConfigCache extends Table {
  /// Always [singletonId]. One config, one row.
  IntColumn get id => integer()();

  /// The document exactly as fetched, re-parsed on read rather than stored
  /// pre-parsed: the parser is where per-key fallback and clamping happen, and
  /// a cached config must go through both again after an app upgrade that
  /// changed either.
  TextColumn get document => text()();

  /// The server's entity tag, sent on the next fetch so an unchanged document
  /// costs a round trip and no payload.
  TextColumn get validator => text().nullable()();

  DateTimeColumn get fetchedAt => dateTime().clientDefault(DateTime.now)();

  static const int singletonId = 0;

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Player settings, one row per setting the player has actually chosen.
///
/// A missing row is not missing data — it means "never chosen", and the answer
/// is the documented default. That distinction matters: it is what lets a new
/// default reach players who never opened the settings screen.
class Settings extends Table {
  TextColumn get key => text()();

  BoolColumn get boolValue => boolean()();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

/// Counters that outlive any puzzle, **season**, or pack.
///
/// The permanent layer of D-17's three. Seasons rotate every six weeks and take
/// their maps with them; this is what stops that rotation feeling like loss, so
/// nothing here may be scoped to a season.
class LifetimeStats extends Table {
  /// Always [singletonId]. The column exists only to give the single row a
  /// stable upsert target — leaving it to a default makes the conflict clause
  /// ambiguous, and the symptom is a second row rather than an error.
  IntColumn get id => integer()();

  static const int singletonId = 0;

  IntColumn get puzzlesSolved => integer().withDefault(const Constant(0))();

  IntColumn get perfectSolves => integer().withDefault(const Constant(0))();

  IntColumn get totalPlayMs => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// How often each technique has been required of the player.
///
/// `add-rank-progression` reads these to decide when a technique is understood,
/// and `add-trophy-cabinet` shows them. Kept per technique rather than per rank
/// because the rank is only ever the hardest of them (D-07).
class TechniqueStats extends Table {
  TextColumn get technique => textEnum<Technique>()();

  IntColumn get puzzlesRequiring => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{technique};
}

/// A shipped or downloaded set of puzzles.
///
/// Versioned so a refreshed pack can replace its contents without disturbing
/// what the player has already solved — the two are separate tables for exactly
/// that reason.
class Packs extends Table {
  TextColumn get packId => text()();

  IntColumn get version => integer()();

  DateTimeColumn get installedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{packId};
}

/// One puzzle, exactly as D-32 describes it.
///
/// The solution, the grade, and the seed are all carried rather than derived.
/// Generation and grading happen offline (`docs/TECH_STACK.md` §4) because
/// grading requires running a full solver, and doing that on the device is slow
/// enough to be felt. This table is the result of that work, not a place where
/// any of it is redone.
class Puzzles extends Table {
  TextColumn get id => text()();

  /// The **pack** this puzzle came from.
  ///
  /// Spelled as a custom constraint rather than `.references(Packs, #packId)`,
  /// and not by preference. `.references()` stopped emitting the SQL-level
  /// foreign key at some drift upgrade, so the app quietly began creating this
  /// column as a bare `TEXT NOT NULL` while every schema snapshot from v1 on
  /// still recorded `REFERENCES packs (pack_id)`. Nothing caught it because the
  /// migration tests compare snapshots with each other, and no schema change
  /// was made between the upgrade and `add-technique-tutorials` — whose bump to
  /// version 4 was the first comparison against what the app actually builds.
  ///
  /// Installs from before that upgrade have the key; installs made in between
  /// do not. Neither enforces it — there is no `foreign_keys` pragma — so the
  /// divergence costs nothing at runtime, and stating the constraint here is
  /// what makes new databases agree with the old ones and with the snapshots
  /// again.
  ///
  /// **Do not swap this back to `.references()` without dumping
  /// `sqlite_master` and reading the emitted SQL.** The declaration looks
  /// correct either way; only the SQL says which one it is.
  TextColumn get packId =>
      text().customConstraint('NOT NULL REFERENCES packs (pack_id)')();

  /// The givens, 81 characters, `.` for empty.
  TextColumn get clues => text().withLength(min: 81, max: 81)();

  /// The full solution. Every puzzle has exactly one (D-08).
  TextColumn get solution => text().withLength(min: 81, max: 81)();

  /// The hardest technique the puzzle requires, never its clue count (D-07).
  TextColumn get rank => textEnum<Rank>()();

  IntColumn get seed => integer()();

  /// A **killer** puzzle's **cage**s and **cage sum**s, in the JSON form the
  /// **pack** carries them in, or null for a classic puzzle (D-127).
  ///
  /// Null *is* classic: there is no separate kind column, so a row cannot say
  /// it is **killer** and carry no **cage**s, or the other way round.
  TextColumn get cages => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Which puzzles the player has finished.
///
/// Deliberately not a column on [Puzzles]: a pack refresh replaces puzzle rows,
/// and progress that lived on those rows would be replaced with them. Losing a
/// season's solved history to a content update is the kind of silent failure
/// D-33 exists to prevent.
/// Which **lesson**s the player has been shown.
///
/// Seen is a fact, not a count: a **lesson** completed, skipped, or replayed
/// four times is one row either way. That is why there is no counter column —
/// the only question anything asks of this table is whether the row exists, and
/// a count would be a second answer nobody needs.
///
/// Keyed by the **lesson**'s own id rather than by a `Technique`, because the
/// **notes lesson** teaches no technique and still has to live here.
class SeenLessons extends Table {
  TextColumn get lessonId => text()();

  DateTimeColumn get seenAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{lessonId};
}

/// Which **season** is in force.
///
/// One row. The **season** itself is not stored — it is read from the remote
/// configuration document with a compiled-in fallback (D-109's rotation is a
/// publish, not a release), so all this table records is *which* one the player
/// is walking. That is enough: completions are keyed by the same id, so a
/// **season** and its progress find each other by name.
class SeasonStates extends Table {
  /// Always [singletonId]. One **season** in force, one row.
  IntColumn get id => integer()();

  /// The **season**'s id, matching the definition's own.
  TextColumn get seasonId => text()();

  /// When this **season** became the one in force. Not the **season**'s start
  /// date, which the definition carries — this is when *this player* began it.
  DateTimeColumn get startedAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  static const int singletonId = 0;

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Every **trophy** the player has earned.
///
/// **Minted, not derived** (D-124), and that is a deliberate departure from the
/// rule that governs the **streak** and a **technique unlock**. A **trophy** is
/// a record of an *event* — earned on a date, in a territory, never true
/// differently afterwards — where those two are states that change while the
/// player does nothing. The codebase already treats events this way, which is
/// why `solved_puzzles` holds a row per puzzle.
///
/// **The season's name is copied in here on purpose.** It is the one field that
/// looks redundant and is not: `completed_nodes` survives rotation, but the
/// **season** *document* carrying the name is replaced, so a derived **trophy**
/// from a past territory could only ever be "position 22 of frontier-1".
///
/// As with **completed node**s and **completed day**s there is no way to unset
/// a row: constraint 1 is enforced by the schema having no representation for
/// taking a **trophy** back.
class Trophies extends Table {
  /// The **award** id this was minted from. Stable across publishes —
  /// **progress is keyed to it**, so a republish that changes an id orphans the
  /// **trophy** rather than renaming it.
  TextColumn get awardId => text()();

  /// What it was called when it was earned. A later publish may rename the
  /// **award**; what the player earned does not change.
  TextColumn get name => text()();

  /// Null for a permanent **award**, which belongs to no **season**.
  TextColumn get seasonId => text().nullable()();

  /// The territory's name, captured at mint time. See the note above.
  TextColumn get seasonName => text().nullable()();

  /// When it was first earned. Never moved by a second minting.
  DateTimeColumn get earnedAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{awardId};
}

/// Which days the **daily challenge** was completed.
///
/// **A set of dates, never a count.** The **streak** is recomputed from these
/// rows on demand (`docs/TECH_STACK.md` §3b), because two devices holding two
/// numbers cannot be reconciled while two sets of days union cleanly. Storing
/// the number as well would create a second source of truth that can drift from
/// the days it claims to describe, with nothing able to detect it.
///
/// As with **completed node**s there is no `completed` boolean and no way to
/// unset a row: a day is completed by its row existing, so the schema has no
/// representation for taking one back (constraint 1).
class CompletedDays extends Table {
  /// `YYYY-MM-DD`, local to the player. Zero-padded, so the stored form sorts
  /// in date order and a month can be read as a range.
  TextColumn get day => text().withLength(min: 10, max: 10)();

  /// False where the day was recorded with no known server-time offset — the
  /// ordinary offline case, not a suspicion. Reconciliation may discard an
  /// unverified day dated ahead of the server's own; it may never touch
  /// anything else (`docs/TECH_STACK.md` §3b).
  BoolColumn get isVerified => boolean().withDefault(const Constant(false))();

  /// Whether a **streak freeze** bridged this day rather than the player
  /// playing it. Both kinds count toward the **streak**; only one of them is a
  /// day they turned up for, and the **calendar** draws them differently.
  BoolColumn get wasFrozen => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{day};
}

/// When a **streak freeze** was last spent.
///
/// One row, and a date rather than a count. How many are held is derived from
/// this (D-117: one at a time, regenerating every 7 days, never banked), for
/// the same reason the **streak** is derived from the **calendar** — a stored
/// count can drift out of step with the events that produced it, and a date
/// cannot. It also means there is no number in the schema for a bug to
/// increment twice.
/// Named for the generated row class, not for elegance: a table `FreezeLedgers`
/// would generate a `FreezeLedger` data class that collides with the domain
/// type of the same name, and the two would go on colliding in every file that
/// needed both.
class StreakFreezeLedgers extends Table {
  /// Always [singletonId]. One player, one ledger.
  IntColumn get id => integer()();

  /// `YYYY-MM-DD` of the last spend, or null if one has never been spent — in
  /// which case the player holds one, immediately (D-117).
  TextColumn get lastSpentDay =>
      text().withLength(min: 10, max: 10).nullable()();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  static const int singletonId = 0;

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Which **node**s the player has completed, in which **season**.
///
/// Keyed by **season** id as well as position, and that is what makes rotation
/// safe: a successor **season** has a different id, so it starts with no rows
/// and carries none of its predecessor's progress (D-17). Nothing has to be
/// deleted at rotation, which means nothing can be deleted by mistake — the old
/// **season**'s rows simply stop being asked about.
///
/// There is no `completed` boolean and no way to unset a row. A **node** is
/// completed by a row existing, and constraint 1 is enforced by the schema
/// having no representation for taking one back.
class CompletedNodes extends Table {
  TextColumn get seasonId => text()();

  /// 1-based, matching what the player is shown ("Node 14").
  // Drift's documented idiom for a CHECK constraint refers to the column inside
  // its own getter, exactly as `Notes.cell` does.
  // ignore: recursive_getters
  IntColumn get position => integer().check(position.isBetweenValues(1, 42))();

  DateTimeColumn get completedAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{seasonId, position};
}

/// How many times each **boss node** has been attempted.
///
/// **Counted, never enforced.** D-22 gives a **boss node** unlimited free
/// retries, so nothing reads this to decide whether an attempt may happen — it
/// exists for `add-trophy-cabinet`'s statistics and for the player's own
/// interest. A test asserts the count never restricts access, because a counter
/// sitting next to a gate is one line away from becoming one.
class BossAttempts extends Table {
  TextColumn get seasonId => text()();

  // ignore: recursive_getters
  IntColumn get position => integer().check(position.isBetweenValues(1, 42))();

  IntColumn get attempts => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{seasonId, position};
}

class SolvedPuzzles extends Table {
  TextColumn get puzzleId => text()();

  DateTimeColumn get solvedAt => dateTime().clientDefault(DateTime.now)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{puzzleId};
}

/// An empty 81-cell grid, `.` for every cell.
///
/// Public and library-level for two reasons: drift's generated table code
/// refers to it unqualified, and the generated *steps* file is a separate
/// library, so a private constant used as a column default breaks migration
/// generation. `add-grid-and-input` needs the same convention anyway.
const String emptyGrid =
    '.................................................................'
    '................';

/// A puzzle the player has started and not finished.
///
/// One row per puzzle. Placed values are stored as a compact string rather than
/// 81 rows: unlike notes, a value's position *is* its identity and nothing is
/// ever removed from the middle of the grid, so there is no reflow risk here
/// and a single row keeps the save atomic.
class PuzzleSaves extends Table {
  TextColumn get puzzleId => text()();

  /// 81 characters, one per cell, `.` for empty. Fixed width, so a cell's
  /// index is its offset and the string can never shift.
  ///
  /// Required rather than defaulted. A save without a grid is not a state the
  /// game has, and a Dart constant used as a column default does not survive
  /// into the generated migration steps, which are a separate library.
  TextColumn get placedValues => text().withLength(min: 81, max: 81)();

  /// Milliseconds of play. Stored rather than derived: wall-clock difference
  /// would count the hours the app was closed, and D-06 leaves the timer
  /// display-only precisely so it can be honest.
  IntColumn get elapsedMs => integer().withDefault(const Constant(0))();

  BoolColumn get isComplete => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  /// Which device this save came from. Unused until `add-cloud-sync`, where
  /// §2a's "show both saves and let the player pick" needs to name them.
  TextColumn get deviceOrigin => text().withDefault(const Constant(''))();

  /// **Mistake**s recorded against this **attempt** (D-96).
  ///
  /// Defaults to zero, which is also what a save written before
  /// `add-mistake-model` reads as — the only honest answer, since the
  /// placements that made it were never inspected.
  ///
  /// On the save row rather than a table of its own: it is one number per
  /// puzzle in progress, it is written by the same action that writes the
  /// board, and a second table would be a second thing to keep in step with
  /// the first (constraint 9).
  IntColumn get mistakes => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{puzzleId};
}

/// One candidate in one cell of one puzzle.
///
/// A note is addressed by (puzzle, cell, digit) rather than stored as a list.
/// That is constraint 3 made structural: a list would need compacting when a
/// candidate is removed, and a compacted list reflows the board on reload. Here
/// removing a candidate is deleting one row, and the other eight are untouched
/// because nothing about them referred to it.
class Notes extends Table {
  TextColumn get puzzleId => text()();

  /// 0-80, reading the grid left to right and top to bottom.
  ///
  // Drift's documented idiom for a CHECK constraint refers to the column inside
  // its own getter. The analyzer reads that as recursion; sqlite receives
  // `CHECK("cell" BETWEEN 0 AND 80)` and enforces it, which a test asserts.
  // ignore: recursive_getters
  IntColumn get cell => integer().check(cell.isBetweenValues(0, 80))();

  /// The candidate itself, 1-9. This *is* the note's identity, not its
  /// position — the fixed 3x3 slot it occupies is derived from it (D-10).
  // ignore: recursive_getters
  IntColumn get digit => integer().check(digit.isBetweenValues(1, 9))();

  TextColumn get kind => textEnum<NoteKind>()();

  TextColumn get origin => textEnum<NoteOrigin>()();

  /// Sync metadata. Nothing reads these until `add-cloud-sync`; they exist so
  /// that change is not a migration of live saves.
  ///
  /// Defaulted rather than required so that no caller can insert a row without
  /// a stamp. Updates set it explicitly — see the note repository, where the
  /// stamp and the write are the same statement.
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  BoolColumn get pendingUpload => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{puzzleId, cell, digit};
}

/// The local database.
///
/// Everything a player would be upset to lose lives here: the puzzle they are
/// part-way through, both kinds of note on it, their statistics, and their
/// settings. Guests and signed-in players use it identically — an account buys
/// sync, never storage (`docs/TECH_STACK.md` §2a).
///
/// Opened lazily. Nothing here may sit on the path to the first frame.
@DriftDatabase(
  tables: <Type>[
    Notes,
    PuzzleSaves,
    Packs,
    Puzzles,
    SolvedPuzzles,
    LifetimeStats,
    TechniqueStats,
    Settings,
    ConfigCache,
    SeenLessons,
    SeasonStates,
    CompletedNodes,
    BossAttempts,
    CompletedDays,
    StreakFreezeLedgers,
    Trophies,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Takes its executor, so tests and drift's generated migration tests can
  /// supply one. Unnamed on purpose: `drift_dev make-migrations` generates a
  /// test that calls `AppDatabase.new` with an executor, and a database whose
  /// primary constructor does not accept one cannot use that tooling.
  AppDatabase(super.executor);

  /// The real database, in the platform's application-support directory.
  ///
  /// The directory is set explicitly. `drift_flutter` defaults to the
  /// *documents* directory, which is the wrong home for a database: on iOS that
  /// is user-facing space backed up to iCloud, and Apple's guidance reserves it
  /// for documents the player created. A save file is app data, so it belongs
  /// in Application Support — where the OS also knows not to expose it.
  AppDatabase.open()
    : this(
        driftDatabase(
          name: 'doku_duty',
          native: DriftNativeOptions(
            databaseDirectory: getApplicationSupportDirectory,
          ),
        ),
      );

  /// How the database gets from an older version to this one.
  ///
  /// `stepByStep` walks one version at a time, so a player upgrading from
  /// several releases back takes the same path as several consecutive upgrades
  /// — which is the path that has tests.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      // Version 2 adds the remote-config cache. Nothing existing moves, so
      // every saved game, note, statistic and setting carries over
      // untouched — which task 6.4 asserts rather than assumes.
      from1To2: (m, schema) async {
        await m.createTable(schema.configCache);
      },
      // Version 3 adds the **mistake** tally to a save. One column with a
      // default, so every existing save keeps its board, its notes and its
      // elapsed time and simply reads as zero — which task 6.3 asserts rather
      // than assumes.
      from2To3: (m, schema) async {
        await m.addColumn(schema.puzzleSaves, schema.puzzleSaves.mistakes);
      },
      // Version 4 adds the seen **lesson**s. A new table and nothing else, so
      // every existing save, note, statistic, setting and **solve record**
      // carries over untouched — and, importantly, the table arrives *empty*.
      // A player upgrading has seen no **lesson**, which is the direction that
      // makes them all still due; arriving full would silently suppress the
      // whole feature for every existing install (task 2.4).
      from3To4: (m, schema) async {
        await m.createTable(schema.seenLessons);
      },
      // Version 5 adds the **season** the player is walking and what they have
      // completed on it. Three new tables and nothing else moves, so every
      // saved game, note, statistic, setting, **solve record** and seen
      // **lesson** carries over untouched — which task 4.2 asserts rather than
      // assumes.
      //
      // They arrive *empty*, and that is the direction that is safe: a player
      // upgrading has completed no **node**, so they start at **node** 1 of
      // season one with their permanent progress intact (D-17). Arriving
      // pre-filled would hand them a **season** they never played.
      from4To5: (m, schema) async {
        await m.createTable(schema.seasonStates);
        await m.createTable(schema.completedNodes);
        await m.createTable(schema.bossAttempts);
      },
      // Version 6 adds the **daily challenge**'s **calendar** and the **streak
      // freeze** ledger. Two new tables and nothing else moves, so every saved
      // game, note, statistic, setting, **solve record**, seen **lesson** and
      // **season** completion carries over untouched — which task 4.2 asserts
      // rather than assumes.
      //
      // They arrive *empty*, and here that direction is not merely safe but
      // required. An empty **calendar** means a player upgrading has a
      // **streak** of zero and has completed no day, which is true: there was
      // no **daily challenge** before this version for them to have played.
      // Arriving pre-filled would credit days that never happened and put a
      // number on screen the player could not account for.
      //
      // The ledger arrives empty too, which by D-117 means `lastSpentDay` is
      // null and every upgrading player holds one **streak freeze** from the
      // moment they open the app. That is the intended reading, not an
      // accident of the default: the safety net exists for the player whose
      // second day goes wrong, and an upgrade is somebody's first day.
      from5To6: (m, schema) async {
        await m.createTable(schema.completedDays);
        await m.createTable(schema.streakFreezeLedgers);
      },
      // Version 7 adds the **cabinet**'s **trophy**s. One new table and nothing
      // else moves, so every saved game, note, statistic, setting, **solve
      // record**, seen **lesson**, **season** completion and **calendar** day
      // carries over untouched — which the migration test asserts rather than
      // assumes.
      //
      // It arrives *empty*, and **there is no retroactive minting**. A player
      // upgrading has earned no **trophy** yet and starts earning from here.
      // Back-filling would mean inventing dates for events the database never
      // recorded — a **boss node** completed under version 5 has a completion
      // row but no moment attached to it — and a **cabinet** that quietly
      // invents its own history is worth less than an honest empty one.
      from6To7: (m, schema) async {
        await m.createTable(schema.trophies);
      },
      // Version 8 gives a puzzle its **cage**s. One nullable column, so every
      // puzzle already installed reads as null — classic, which is what it is —
      // and nothing a player has done moves: saves key by puzzle id, and the
      // id does not change. The **killer** puzzles themselves arrive with
      // **pack** version 2, which the existing version check installs on the
      // next launch.
      from7To8: (m, schema) async {
        await m.addColumn(schema.puzzles, schema.puzzles.cages);
      },
    ),
  );

  /// Bump this for any schema change — and in the same commit:
  ///
  /// 1. `flutter pub run drift_dev make-migrations`, which writes the new
  ///    snapshot under `drift_schemas/`, a steps file next to this one, and a
  ///    migration test under `test/drift/`.
  /// 2. Import the steps file and add a `MigrationStrategy` with
  ///    `onUpgrade: stepByStep(from1To2: ...)` describing the change.
  /// 3. Run the generated test. It checks both that the schema arrives at the
  ///    right shape and that data already in it survives.
  ///
  /// Commit the snapshot. It is the baseline every later migration compares
  /// against and it cannot be reconstructed once the schema has moved.
  ///
  /// Two things this schema learned the hard way, so the next person does not:
  ///
  /// - **A column default cannot be a private constant.** The generated steps
  ///   file is a separate library and cannot see it. Either make the constant
  ///   public or leave the column required.
  /// - **The unnamed constructor must take a `QueryExecutor`.** The generated
  ///   migration test calls `AppDatabase.new` with one; the app's own opener is
  ///   [AppDatabase.open].
  ///
  /// Shipping a schema change without a tested migration risks exactly the
  /// saved games D-33 exists to protect. The mechanism was exercised once at
  /// version 1, against a throwaway version 2, so that the first real migration
  /// is not also the first attempt.
  @override
  int get schemaVersion => 8;
}
