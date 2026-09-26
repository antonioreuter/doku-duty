import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../daily_challenge/application/daily_providers.dart';
import '../../persistence/application/database_provider.dart';
import '../../persistence/data/pack_repository.dart';
import '../../persistence/data/note_repository.dart';
import '../../persistence/data/puzzle_save_repository.dart';
import '../../persistence/domain/note_enums.dart';
import '../../persistence/data/settings_repository.dart';
import '../../persistence/domain/app_setting.dart';
import '../../puzzle_engine/application/pack_providers.dart';
import '../../mistake_model/domain/attempt.dart';
import '../../puzzle_engine/domain/cage.dart';
import '../../puzzle_engine/domain/grader.dart';
import '../../puzzle_engine/domain/grid.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../../puzzle_engine/domain/technique.dart';
import '../../rank_progression/data/progression_repository.dart';
import '../../season_map/application/season_providers.dart';
import '../../trophy_cabinet/application/cabinet_providers.dart';
import '../application/puzzle_controller.dart';
import 'puzzle_origin.dart';
import '../../stamps/application/stamp_providers.dart';
import '../../stamps/domain/earning.dart';
import '../domain/board.dart';
import '../domain/note_set.dart';
import '../domain/puzzle_session.dart';

final puzzleSaveRepositoryProvider = Provider<PuzzleSaveRepository>(
  (ref) => PuzzleSaveRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// How input works, read from the stored setting.
///
/// Cell-first until the player says otherwise, and the read falls back to the
/// same default, so a fresh install and an unreadable database agree.
final inputModeProvider = FutureProvider<InputMode>((ref) async {
  final numberFirst = await ref
      .watch(settingsRepositoryProvider)
      .read(AppSetting.numberFirstInput);
  return numberFirst ? InputMode.digitFirst : InputMode.cellFirst;
});

/// The next unsolved puzzle at each **rank**, or null where there is none.
///
/// Null is an ordinary answer. Running out at a **rank** is not a wall
/// (constraint 1), and the picker shows it as nothing left rather than as a
/// lock.
final nextPuzzleByRankProvider = FutureProvider<Map<Rank, StoredPuzzle?>>((
  ref,
) async {
  // Before the first query, not after: the install and this read both start
  // after the first frame, and a rank queried mid-install comes back empty.
  await ref.watch(packInstallationProvider.future);

  final packs = ref.watch(packRepositoryProvider);
  final byRank = <Rank, StoredPuzzle?>{};
  for (final rank in Rank.values) {
    final row = await packs.nextUnsolved(rank);
    byRank[rank] = row == null
        ? null
        : StoredPuzzle(
            id: row.id,
            clues: row.clues,
            solution: row.solution,
            rank: row.rank,
            seed: row.seed,
          );
  }
  return byRank;
});

/// Everything one puzzle needs to open: the row, its save, and the input mode.
final puzzleOpeningProvider = FutureProvider.family<PuzzleOpening?, String>((
  ref,
  puzzleId,
) async {
  // A deep link into a puzzle on a fresh install would otherwise find no row.
  await ref.watch(packInstallationProvider.future);

  final row = await ref.watch(packRepositoryProvider).puzzleById(puzzleId);
  if (row == null) return null;

  final saves = ref.watch(puzzleSaveRepositoryProvider);
  final resumable = await saves.all();
  final save = resumable.where((s) => s.puzzleId == puzzleId).firstOrNull;

  final stored = await ref.watch(noteRepositoryProvider).notesFor(puzzleId);
  final notes = <int, NoteSet>{};
  for (final note in stored) {
    final set = notes[note.cell] ?? NoteSet.none;
    // Both facts come back off the row. Rebuilding every candidate as manual
    // would quietly make the fill's work the player's, and rebuilding every
    // one as settled would throw away the hypothesis the player left on the
    // board — each distinction would survive exactly one app kill (D-15, D-11).
    final marked = note.origin == NoteOrigin.generated
        ? set.withGenerated(note.digit)
        : set.with_(note.digit);
    notes[note.cell] = note.kind == NoteKind.provisional
        ? marked.reInked(note.digit, NoteKind.provisional)
        : marked;
  }

  return PuzzleOpening(
    techniquesRequired: _techniquesFor(row.clues, row.cages),
    puzzle: StoredPuzzle(
      id: row.id,
      clues: row.clues,
      solution: row.solution,
      rank: row.rank,
      seed: row.seed,
      cages: row.cages,
    ),
    placedValues: save == null ? null : _encode(save.placedValues),
    // A resumed puzzle carries its tally, so a player two into a **strict
    // mode** **attempt** is still two into it (D-96).
    mistakes: save?.mistakes ?? 0,
    notes: notes,
    mode: await ref.watch(inputModeProvider.future),
  );
});

/// What the grader says this puzzle requires.
///
/// Taken once, here, on the path that opens a puzzle — never on the path of a
/// tap, where a solver run has no room inside constraint 2's budget.
///
/// The **rank** the player is *told* stays the one stored with the puzzle: the
/// **pack** carries the grade that was checked when it was built, and this
/// device working out its own answer would be a second one (D-32). What is
/// re-derived is only the technique *set*, which the **pack** does not carry
/// and which the **solve record** needs — a **rank** says what a puzzle may
/// require, not what it did.
///
/// An ungradable puzzle yields the empty set rather than an error. Nothing
/// about the player's game should stop because a statistic cannot be computed,
/// and constraint 1 has no room for a puzzle that refuses to open.
///
/// A **killer** puzzle is graded with its **cage**s (D-128). Without them the
/// classic ladder cannot finish one, and the empty set that came back would
/// skip every counter, every **technique unlock** and every **lesson** without
/// a sign that anything had been missed.
Set<Technique> _techniquesFor(String clues, String? storedCages) {
  final parsed = Grid.parse(clues);
  if (parsed is! ValidGrid) return const <Technique>{};
  final cages = switch (CageSet.fromStoredText(storedCages)) {
    ValidCageSet(:final cages) => cages,
    _ => null,
  };
  final result = grade(parsed.grid, cages: cages);
  return switch (result) {
    Graded(:final techniquesUsed) => techniquesUsed,
    Ungradable() => const <Technique>{},
  };
}

String _encode(Map<int, int> placed) {
  final buffer = StringBuffer();
  for (var cell = 0; cell < 81; cell++) {
    final digit = placed[cell];
    buffer.write(digit == null ? '.' : '$digit');
  }
  return buffer.toString();
}

/// A puzzle, ready to play.
final class PuzzleOpening {
  const PuzzleOpening({
    required this.puzzle,
    required this.placedValues,
    required this.mode,
    this.notes = const <int, NoteSet>{},
    this.mistakes = 0,
    this.techniquesRequired = const <Technique>{},
  });

  final StoredPuzzle puzzle;
  final String? placedValues;

  /// The candidates the player left, by cell.
  final Map<int, NoteSet> notes;

  /// **Mistake**s already recorded against this **attempt**.
  final int mistakes;

  final InputMode mode;

  /// What the grader says the puzzle requires, carried from the open so the
  /// **solve record** has it without grading on the frame that completes the
  /// board.
  final Set<Technique> techniquesRequired;
}

/// Writes the board through the persistence layer.
final class RepositoryBoardSink implements BoardSink {
  const RepositoryBoardSink(
    this._saves,
    this._notes,
    this._progression, {
    this._onSolveRecorded,
    this._originCompletion,
    this._afterSolveRecorded,
  });

  final PuzzleSaveRepository _saves;
  final NoteRepository _notes;
  final ProgressionRepository _progression;

  /// What else to write inside the **solve record**'s transaction, if anything,
  /// decided by where the board was opened from.
  ///
  /// Returns null in **free play**, where a solved board belongs to no **node**
  /// and no day (D-111). On the **trail** it returns the write that completes
  /// the **node**; for the **daily challenge**, the write that marks its day.
  /// Inside the transaction either way, so a failure leaves neither and
  /// nothing reads as done that was not. Returns the **earning**s it wrote.
  final Future<List<Earning>> Function()? Function()? _originCompletion;

  /// What to write once the **solve record** is in, inside its transaction,
  /// returning the **earning**s it wrote.
  ///
  /// Wherever the board came from — the **rank** a solve raises and the
  /// perfect solve are facts about the solve, not its origin, so every board
  /// runs it. Told whether this completion wrote the record, because only
  /// that one can pay the perfect solve (D-133).
  final Future<List<Earning>> Function({
    required String puzzleId,
    required bool isFirstSolve,
    required bool isPerfect,
  })?
  _afterSolveRecorded;

  /// Called once a **solve record** has been written.
  ///
  /// Exists because writing the record is not enough on its own: what the
  /// picker shows is a cached read, and a player who solves a puzzle and walks
  /// back would be handed it again — the same break as the missing write, one
  /// layer up. Optional, because a test driving the sink directly has no
  /// cache to tell about.
  final void Function()? _onSolveRecorded;

  @override
  Future<void> write(
    String puzzleId,
    Board board, {
    required int mistakes,
  }) => _saves.save(
    puzzleId: puzzleId,
    placedValues: <int, int>{
      for (var cell = 0; cell < 81; cell++)
        if (!board.isGiven(cell) && board.digitAt(cell) != Board.empty)
          cell: board.digitAt(cell),
    },
    mistakes: mistakes,
    // The timer is display-only and nothing in this change advances it (D-06),
    // so zero is the truth today.
    //
    // **It will not be the truth the moment a timer exists.** `save` writes the
    // whole row, so this line would reset `elapsedMs` on every placement —
    // silently, with no symptom until a player noticed their time never grew.
    // Whoever adds the timer must thread the elapsed value through here rather
    // than leaving this constant in place.
    elapsed: Duration.zero,
  );

  /// Writes the cell's candidates as they now stand.
  ///
  /// A note is addressed by (puzzle, cell, digit), so a candidate that is gone
  /// is a deleted row and the other eight are untouched — constraint 3 made
  /// structural rather than careful.
  ///
  /// Ink and origin are both written from the set rather than assumed, and
  /// they are independent: **auto-notes** marks candidates the player did not,
  /// taking one over by hand moves the row back to manual (D-15), and either
  /// origin can be carried into a hypothesis without that changing which of
  /// the two first marked it (D-90).
  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) {
    return _notes.putCells(
      puzzleId: puzzleId,
      cells: <int, Map<int, NoteMark>>{
        for (final entry in byCell.entries)
          entry.key: <int, NoteMark>{
            for (var digit = 1; digit <= 9; digit++)
              if (entry.value.contains(digit))
                digit: (
                  kind: entry.value.isProvisional(digit)
                      ? NoteKind.provisional
                      : NoteKind.settled,
                  origin: entry.value.isGenerated(digit)
                      ? NoteOrigin.generated
                      : NoteOrigin.manual,
                ),
          },
      },
    );
  }

  /// The puzzle is finished: close the save, then write the **solve record**.
  ///
  /// Both, and in this order. Closing the save is what takes the board out of
  /// the resumable list; the **solve record** is what the player's **rank**,
  /// their **technique unlock**s, and the next puzzle at this **rank** are all
  /// read from. Until this change nothing wrote the second, so finishing a
  /// puzzle left no trace outside its own save row and the picker handed the
  /// same puzzle back forever.
  ///
  /// The record is idempotent, so a duplicate completion — a write already in
  /// flight when another lands — costs a query and changes nothing.
  @override
  Future<int> complete(
    String puzzleId, {
    required Set<Technique> techniquesRequired,
    required Attempt attempt,
  }) async {
    // Two transactions, deliberately: the save row and the **solve record** are
    // different facts, and only the record's own parts must be atomic. The
    // window is real but small — if the record throws, the save reads complete
    // with no record behind it, and the puzzle is offered again. That is
    // recoverable by solving it again, and `_persist` routes the error to
    // `onError` rather than the player (D-03). Worth closing if these ever
    // share a transaction; not worth threading a database handle through the
    // sink to close it today.
    await _saves.complete(puzzleId);
    // Gathered from both hooks as they run, and only read once `record` has
    // returned — so a transaction that rolled back reports nothing, because
    // it throws before this method gets that far.
    final earned = <Earning>[];
    final origin = _originCompletion?.call();
    final after = _afterSolveRecorded;
    await _progression.record(
      puzzleId: puzzleId,
      techniquesRequired: techniquesRequired,
      attempt: attempt,
      alsoInTransaction: origin == null
          ? null
          : () async => earned.addAll(await origin()),
      afterInTransaction: after == null
          ? null
          : ({required bool isFirstSolve}) async => earned.addAll(
              await after(
                puzzleId: puzzleId,
                isFirstSolve: isFirstSolve,
                isPerfect: attempt.isPerfect,
              ),
            ),
      // Display-only and never advanced (D-06), exactly as `elapsed` above.
      // **Whoever adds the timer must thread it through here too**, or the
      // lifetime play total stays at zero with no symptom until someone reads
      // the cabinet and finds every puzzle took no time at all.
      timeTaken: Duration.zero,
    );
    _onSolveRecorded?.call();
    return earned.fold<int>(0, (total, e) => total + e.amount);
  }
}

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(ref.watch(appDatabaseProvider)),
);

final progressionRepositoryProvider = Provider<ProgressionRepository>(
  (ref) => ProgressionRepository(ref.watch(appDatabaseProvider)),
);

/// The player's **rank**: the hardest **rank** they have solved (D-102).
///
/// Derived from the **solve record**s on every read, so it cannot fall out of
/// step with them. Greenhorn is the answer for a player who has solved nothing
/// — a starting position, not an absence.
final playerRankProvider = FutureProvider<Rank>(
  (ref) => ref.watch(progressionRepositoryProvider).playerRank(),
);

final boardSinkProvider = Provider<BoardSink>(
  (ref) => RepositoryBoardSink(
    ref.watch(puzzleSaveRepositoryProvider),
    ref.watch(noteRepositoryProvider),
    ref.watch(progressionRepositoryProvider),
    // Where the board was opened from, read at the moment of completion rather
    // than captured when the sink was built, so a player who leaves a **node**,
    // plays elsewhere, and comes back completes what they are actually on.
    //
    // Both writes are routed through the **cabinet**'s minting service rather
    // than their own repositories, so the completion and any **trophy** it
    // earns commit in one transaction (D-124). `season-map` and
    // `daily-challenge` stay unaware of the **cabinet**; the dependency points
    // one way.
    originCompletion: () {
      final minting = ref.read(mintingServiceProvider);
      switch (ref.read(puzzleOriginProvider)) {
        case FreePlayOrigin():
          return null;
        case DailyOrigin(:final day):
          return () => minting.completeDay(day);
        case TrailOrigin(:final position):
          final season = ref.read(currentSeasonProvider);
          final catalogue = ref.read(awardCatalogueProvider);
          final type = season.nodes
              .firstWhere((node) => node.position == position)
              .type;
          return () => minting.completeNode(
            seasonId: season.id,
            seasonName: season.name,
            position: position,
            type: type,
            nodeCount: season.nodes.length,
            catalogue: catalogue,
          );
      }
    },
    // Every **rank** **award** at or below the player's **rank**, read inside
    // the transaction so it sees the record this solve just wrote (D-102),
    // and the perfect solve's **stamp**s. Minting is idempotent, so a solve
    // that raises nothing costs a few no-op inserts and mints nothing.
    afterSolveRecorded:
        ({
          required String puzzleId,
          required bool isFirstSolve,
          required bool isPerfect,
        }) async {
          final progression = ref.read(progressionRepositoryProvider);
          return ref
              .read(mintingServiceProvider)
              .afterSolve(
                puzzleId: puzzleId,
                isFirstSolve: isFirstSolve,
                isPerfect: isPerfect,
                rank: await progression.playerRank(),
              );
        },
    // Every read derived from the **solve record** is now stale: which puzzle
    // is next at each **rank**, the player's **rank**, where they stand on the
    // **trail**, the day on the **calendar**, and the **cabinet**'s
    // **trophy**s and statistics. D-105 was found by a test and not by reasoning — both the
    // **trail** and **free play** sit under the puzzle in the navigation stack
    // and stay mounted, so each keeps its listener and nothing would re-read on
    // its own.
    onSolveRecorded: () {
      ref.invalidate(nextPuzzleByRankProvider);
      ref.invalidate(playerRankProvider);
      ref.invalidate(trailProgressProvider);
      ref.invalidate(nodePuzzleProvider);
      ref.invalidate(dailyStatusProvider);
      ref.invalidate(earnedTrophiesProvider);
      ref.invalidate(earnedIdsProvider);
      ref.invalidate(cabinetStatisticsProvider);
      ref.invalidate(stampBalanceProvider);
    },
  ),
);
