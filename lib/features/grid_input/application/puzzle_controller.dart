import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../design_system/domain/haptics.dart';
import '../../persistence/data/pack_repository.dart' show StoredPuzzle;
import '../../puzzle_engine/domain/grid.dart';
import '../domain/board.dart';
import '../domain/note_set.dart';
import '../domain/puzzle_session.dart';
import '../presentation/number_pad.dart';

/// Writes the board out.
///
/// An interface so the controller's rules can be exercised without a database,
/// and so the save path is one named thing rather than a repository call
/// scattered through a widget.
abstract interface class BoardSink {
  /// Persist the whole board. Called after every change, never on a timer.
  Future<void> write(String puzzleId, Board board);

  /// Persist the candidates of every cell in [byCell], as they now stand.
  ///
  /// Separate from [write] because a note is one row, not a rewrite of the
  /// board: `add-persistence-layer` addresses a candidate by (puzzle, cell,
  /// digit) precisely so marking one costs one statement and disturbs nothing
  /// else (constraint 3, D-33).
  ///
  /// Takes every changed cell at once rather than one at a time because one
  /// player action can reach many: **auto-cleanup** twenty cells and
  /// **auto-notes** eighty-one. One action, one commit — and one code path, so
  /// the single-cell case cannot drift away from the many-cell one.
  Future<void> writeNotes(String puzzleId, Map<int, NoteSet> byCell);

  /// The puzzle is finished.
  Future<void> complete(String puzzleId);
}

/// One puzzle being played.
///
/// [PuzzleSession] holds the rules; this holds the session, saves it, and names
/// the haptic. Every write happens *after* the new state is published, so the
/// frame the player is waiting for never waits on the database (constraint 2).
class PuzzleController extends ChangeNotifier {
  PuzzleController({
    required this.puzzle,
    required this.sink,
    required PuzzleSession initial,
    this.fireHaptic,
    this.onError,
  }) : _state = initial;

  final StoredPuzzle puzzle;
  final BoardSink sink;

  /// Named rather than called on the platform directly, so the vocabulary in
  /// `docs/DESIGN.md` §5 stays the only way a haptic happens.
  final void Function(DokuHaptic haptic)? fireHaptic;

  /// Where a failed write goes. Never to the player: losing a row is a
  /// developer's problem, and this product has no failure states (D-03).
  final void Function(Object error, StackTrace stack)? onError;

  PuzzleSession _state;

  PuzzleSession get state => _state;

  /// Completed *and* right. A full board that disagrees with the solution is
  /// not a solved puzzle, and nothing here tells the player which it is —
  /// that is `add-mistake-model`.
  bool get isSolved => _solves(_state.board);

  void tapCell(int cell) => _apply(_state.tapCell(cell));

  void tapKey(PadKey key) => _apply(switch (key) {
    DigitKey(:final digit) => _state.tapDigit(digit),
    DigitLongPressKey(:final digit) => _state.tapDigitLongPress(digit),
    EraseKey() => _state.tapErase(),
    UndoKey() => _state.tapUndo(),
    // The toggle changes what the next digit writes; it touches no cell, so it
    // is not an edit and nothing is saved or undone for it.
    // Aimed at the board, so it needs neither a selection nor a held digit.
    AutoNotesKey() => _state.fillNotes(),
    NotesToggleKey() => _state.withEntryKind(
      _state.entryKind == EntryKind.value ? EntryKind.note : EntryKind.value,
    ),
  });

  /// Change what a digit press writes.
  void setEntryKind(EntryKind kind) {
    final next = _state.withEntryKind(kind);
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  /// **Auto-notes**: mark every empty cell with its legal candidates.
  void fillNotes() => _apply(_state.fillNotes());

  void setMode(InputMode mode) {
    final next = _state.withMode(mode);
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  void _apply(PuzzleSession next) {
    final previous = _state;
    final changed = next.board != previous.board;
    _state = next;
    // Published first: everything below this line happens with the new board
    // already on its way to the screen.
    notifyListeners();

    final edit = next.lastEdit;
    if (edit is EditApplied) {
      fireHaptic?.call(DokuHaptic.selectionTick);
    }
    if (!changed) return;
    unawaited(_persist(previous.board, next.board));
  }

  /// Every cell whose candidates differ between two boards, with what they
  /// now hold.
  ///
  /// Undo can restore a cell's candidates without an edit describing it, so the
  /// write is derived from the boards rather than from the action. A note that
  /// came back on screen and not in the database is exactly the silent loss
  /// constraint 9 exists to prevent.
  Map<int, NoteSet> _notesChangedBetween(Board before, Board after) {
    final changed = <int, NoteSet>{};
    for (var cell = 0; cell < 81; cell++) {
      final now = after.notesAt(cell);
      if (before.notesAt(cell) != now) changed[cell] = now;
    }
    return changed;
  }

  /// Written on every change, never on a timer — the discipline D-33 sets for
  /// notes, applied to values for the same reason: nobody gets a warning before
  /// the OS reclaims the process.
  Future<void> _persist(Board before, Board board) async {
    try {
      final changed = _notesChangedBetween(before, board);
      if (changed.isNotEmpty) await sink.writeNotes(puzzle.id, changed);
      await sink.write(puzzle.id, board);
      // Asked of the board that was written, not of the current state: writes
      // are in flight concurrently, and an earlier one resuming after the
      // puzzle was finished would report it finished a second time.
      if (_solves(board)) await sink.complete(puzzle.id);
    } on Object catch (error, stack) {
      onError?.call(error, stack);
    }
  }

  bool _solves(Board board) =>
      board.isComplete && board.toGrid().toStorageString() == puzzle.solution;
}

/// The session a puzzle opens into, resumed from [placedValues] when there is a
/// save to resume.
///
/// The history starts empty either way: the board survives an app kill, the
/// moves that made it do not.
PuzzleSession sessionFor({
  required StoredPuzzle puzzle,
  required String? placedValues,
  required InputMode mode,
  Map<int, NoteSet> notes = const <int, NoteSet>{},
}) {
  final givens = (Grid.parse(puzzle.clues) as ValidGrid).grid;
  return PuzzleSession.start(
    board: placedValues == null && notes.isEmpty
        ? Board.forPuzzle(givens: givens)
        : Board.restore(
            givens: givens,
            placedValues: placedValues ?? '.' * 81,
            notes: notes,
          ),
    mode: mode,
  );
}
