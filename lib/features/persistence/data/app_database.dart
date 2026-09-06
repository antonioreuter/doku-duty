import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/note_enums.dart';
import '../domain/rank.dart';
import '../domain/technique.dart';

export '../domain/note_enums.dart';
export '../domain/rank.dart';
export '../domain/technique.dart';

part 'app_database.g.dart';

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

  TextColumn get packId => text().references(Packs, #packId)();

  /// The givens, 81 characters, `.` for empty.
  TextColumn get clues => text().withLength(min: 81, max: 81)();

  /// The full solution. Every puzzle has exactly one (D-08).
  TextColumn get solution => text().withLength(min: 81, max: 81)();

  /// The hardest technique the puzzle requires, never its clue count (D-07).
  TextColumn get rank => textEnum<Rank>()();

  IntColumn get seed => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Which puzzles the player has finished.
///
/// Deliberately not a column on [Puzzles]: a pack refresh replaces puzzle rows,
/// and progress that lived on those rows would be replaced with them. Losing a
/// season's solved history to a content update is the kind of silent failure
/// D-33 exists to prevent.
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
  int get schemaVersion => 1;
}
