import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../completion_effects/domain/completion_schedule.dart';
import '../../completion_effects/domain/effect_event.dart';
import '../../completion_effects/domain/unit_completion.dart';
import '../../design_system/domain/haptics.dart';
import '../../persistence/data/pack_repository.dart' show StoredPuzzle;
import '../../mistake_model/domain/attempt.dart';
import '../../persistence/domain/note_enums.dart';
import '../../puzzle_engine/domain/grid.dart';
import '../../puzzle_engine/domain/technique.dart';
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
  /// Persist the whole board and the **attempt**'s tally. Called after every
  /// change, never on a timer.
  ///
  /// The count travels with the board rather than separately: they change in
  /// the same action, and two writes could leave a player's board and their
  /// tally disagreeing after a kill between them (constraint 9).
  Future<void> write(String puzzleId, Board board, {required int mistakes});

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

  /// The puzzle is finished, and this is the **solve record**.
  ///
  /// Carries what the record needs and nothing the caller could get wrong:
  /// the [Attempt] rather than a "was it perfect" flag, because perfection is a
  /// fact about the run and [Attempt] is the one place that decides it; and the
  /// techniques the puzzle actually required rather than its **rank**, because
  /// a **rank** says only what a puzzle *may* need (D-07).
  Future<void> complete(
    String puzzleId, {
    required Set<Technique> techniquesRequired,
    required Attempt attempt,
  });
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
    this.techniquesRequired = const <Technique>{},
    this.fireHaptic,
    this.onError,
  }) : _state = initial;

  final StoredPuzzle puzzle;
  final BoardSink sink;

  /// What the grader says this puzzle requires, taken once when it was opened.
  ///
  /// Held rather than computed because grading is a solver run, and constraint
  /// 2 has no room for one on the path of a tap. Empty is a legitimate value —
  /// a caller that has not graded records a solve with no techniques against
  /// it rather than guessing a set from the **rank**.
  final Set<Technique> techniquesRequired;

  /// Named rather than called on the platform directly, so the vocabulary in
  /// `docs/DESIGN.md` §5 stays the only way a haptic happens.
  final void Function(DokuHaptic haptic)? fireHaptic;

  /// Where a failed write goes. Never to the player: losing a row is a
  /// developer's problem, and this product has no failure states (D-03).
  final void Function(Object error, StackTrace stack)? onError;

  PuzzleSession _state;

  PuzzleSession get state => _state;

  final StreamController<EffectEvent> _effects =
      StreamController<EffectEvent>.broadcast();

  /// What completed, where, and when.
  ///
  /// A broadcast stream because more than one thing listens: the effect layer
  /// today, the characters and a sound layer later. Broadcast also means an
  /// event with nobody listening is dropped rather than buffered — which is the
  /// behaviour a celebration wants. A player who backgrounded the app mid-solve
  /// should not be met by four queued cascades on their return.
  ///
  /// **Nothing waits on a listener.** The events are published after the new
  /// state is, and no subscriber can delay the board reaching the screen
  /// (constraint 2).
  Stream<EffectEvent> get effects => _effects.stream;

  @override
  void dispose() {
    unawaited(_effects.close());
    super.dispose();
  }

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
    // The other axis, and the same shape: it changes what the next digit
    // writes, touches no cell, and so is neither saved nor undone (D-89).
    InkToggleKey() => _state.withNoteInk(
      _state.noteInk == NoteKind.settled
          ? NoteKind.provisional
          : NoteKind.settled,
    ),
    // Aimed at the board like the fill, so neither needs a selection nor a
    // held digit.
    ClearProvisionalKey() => _state.clearProvisional(),
    PromoteProvisionalKey() => _state.promoteProvisional(),
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

  /// Remove every **provisional note** on the board (D-11).
  ///
  /// Board-wide like [fillNotes], and written the same way: one edit, so one
  /// commit and one undo step.
  void clearProvisional() => _apply(_state.clearProvisional());

  /// Turn every **provisional note** settled (D-91, **promote**).
  void promoteProvisional() => _apply(_state.promoteProvisional());

  /// The player turned stakes on or off, or their stored choice arrived.
  ///
  /// Not an edit: it changes no cell, so nothing is saved and nothing is
  /// undone for it. It takes effect at once in both directions — the flagging
  /// appears or goes, and the cap applies or lifts (D-94).
  void setStrictMode(bool strict) {
    final next = _state.withStrictMode(strict);
    if (identical(next, _state)) return;
    _state = next;
    notifyListeners();
  }

  /// The player chose to start the puzzle again.
  ///
  /// The only route back to a zero tally (D-96). The cleared board is written
  /// like any other change — a restart the store did not hear about would
  /// hand the player their failed **attempt** back on the next launch.
  void restart() {
    final previous = _state;
    _state = _state.restarted();
    notifyListeners();
    unawaited(_persist(previous.board, _state.board, _state.attempt));
  }

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
    // The write is started before anything is announced, and the order is not
    // cosmetic. `_persist` runs synchronously up to its first await, so putting
    // it first means nothing between the board changing and the write being in
    // flight can prevent it — constraint 9, which has no visible symptom when
    // it breaks. Announcing first would put a second code path in that gap for
    // no benefit: the event reaches its listeners on a microtask either way.
    unawaited(_persist(previous.board, next.board, next.attempt));
    _announce(previous.board, next.board, edit);
  }

  /// Say what this change completed, if anything.
  ///
  /// Published after [notifyListeners], so the board is already on its way to
  /// the screen before any effect is scheduled. A celebration that ran before
  /// the digit it is celebrating would be the wrong way round, and one that
  /// delayed it would cost the budget in constraint 2.
  ///
  /// **A note completes nothing** (D-52). Candidates are thinking, and the
  /// guard is structural rather than a check: a note edit moves no value, so
  /// [UnitCompletion.forChange] finds nothing changed and there is no event to
  /// suppress.
  void _announce(Board before, Board after, BoardEdit? edit) {
    if (edit is! EditApplied) return;
    final origin = edit.cell;

    final change = UnitCompletion.forChange(
      before: before,
      after: after,
      cell: origin,
    );
    if (change.completed.isNotEmpty) {
      _emit(
        UnitsCompleted(
          origin: origin,
          steps: CompletionSchedule.forChange(change, origin: origin),
        ),
      );
    }

    // Asked of both boards, so finishing the board announces once — an edit
    // that leaves an already-finished board finished says nothing.
    if (UnitCompletion.isBoardComplete(after) &&
        !UnitCompletion.isBoardComplete(before)) {
      _emit(BoardCompleted(origin: origin));
    }
  }

  void _emit(EffectEvent event) {
    if (_effects.isClosed) return;
    _effects.add(event);
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
  Future<void> _persist(Board before, Board board, Attempt attempt) async {
    try {
      final changed = _notesChangedBetween(before, board);
      if (changed.isNotEmpty) await sink.writeNotes(puzzle.id, changed);
      await sink.write(puzzle.id, board, mistakes: attempt.mistakes);
      // Asked of the board that was written, not of the current state: writes
      // are in flight concurrently, and an earlier one resuming after the
      // puzzle was finished would report it finished a second time.
      if (_solves(board)) {
        await sink.complete(
          puzzle.id,
          techniquesRequired: techniquesRequired,
          attempt: attempt,
        );
      }
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
  bool isStrict = false,
  int mistakes = 0,
}) {
  final givens = (Grid.parse(puzzle.clues) as ValidGrid).grid;
  return PuzzleSession.start(
    // The pack carries the solution beside the clues (D-32), so the session
    // that counts **mistake**s never has to ask the network for the answer.
    solution: (Grid.parse(puzzle.solution) as ValidGrid).grid,
    isStrict: isStrict,
    attempt: Attempt(mistakes: mistakes),
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
