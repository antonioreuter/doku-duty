import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/application/database_provider.dart';
import '../../persistence/data/pack_repository.dart';
import '../../persistence/data/note_repository.dart';
import '../../persistence/data/puzzle_save_repository.dart';
import '../../persistence/domain/note_enums.dart';
import '../../persistence/data/settings_repository.dart';
import '../../persistence/domain/app_setting.dart';
import '../../puzzle_engine/application/pack_providers.dart';
import '../../puzzle_engine/domain/rank.dart';
import '../application/puzzle_controller.dart';
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
    // Origin comes back off the row. Rebuilding every candidate as manual
    // would quietly make the fill's work the player's, and the distinction
    // D-15 keeps would survive exactly one app kill.
    notes[note.cell] = note.origin == NoteOrigin.generated
        ? set.withGenerated(note.digit)
        : set.with_(note.digit);
  }

  return PuzzleOpening(
    puzzle: StoredPuzzle(
      id: row.id,
      clues: row.clues,
      solution: row.solution,
      rank: row.rank,
      seed: row.seed,
    ),
    placedValues: save == null ? null : _encode(save.placedValues),
    notes: notes,
    mode: await ref.watch(inputModeProvider.future),
  );
});

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
  });

  final StoredPuzzle puzzle;
  final String? placedValues;

  /// The candidates the player left, by cell.
  final Map<int, NoteSet> notes;

  final InputMode mode;
}

/// Writes the board through the persistence layer.
final class RepositoryBoardSink implements BoardSink {
  const RepositoryBoardSink(this._saves, this._notes);

  final PuzzleSaveRepository _saves;
  final NoteRepository _notes;

  @override
  Future<void> write(String puzzleId, Board board) => _saves.save(
    puzzleId: puzzleId,
    placedValues: <int, int>{
      for (var cell = 0; cell < 81; cell++)
        if (!board.isGiven(cell) && board.digitAt(cell) != Board.empty)
          cell: board.digitAt(cell),
    },
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
  /// Origin is written from the set rather than assumed: **auto-notes** marks
  /// candidates the player did not, and taking one over by hand has to move
  /// the row back to manual (D-15). The ink is always **settled** — the
  /// turquoise is `add-provisional-notes`.
  @override
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell) {
    return _notes.putCells(
      puzzleId: puzzleId,
      cells: <int, Map<int, NoteOrigin>>{
        for (final entry in byCell.entries)
          entry.key: <int, NoteOrigin>{
            for (var digit = 1; digit <= 9; digit++)
              if (entry.value.contains(digit))
                digit: entry.value.isGenerated(digit)
                    ? NoteOrigin.generated
                    : NoteOrigin.manual,
          },
      },
    );
  }

  @override
  Future<void> complete(String puzzleId) => _saves.complete(puzzleId);
}

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(ref.watch(appDatabaseProvider)),
);

final boardSinkProvider = Provider<BoardSink>(
  (ref) => RepositoryBoardSink(
    ref.watch(puzzleSaveRepositoryProvider),
    ref.watch(noteRepositoryProvider),
  ),
);
