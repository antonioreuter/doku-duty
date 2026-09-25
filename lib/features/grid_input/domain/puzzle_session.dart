import '../../persistence/domain/note_enums.dart';
import '../../mistake_model/domain/attempt.dart';
import '../../puzzle_engine/domain/grid.dart';
import '../../puzzle_engine/domain/grid_geometry.dart';
import '../../puzzle_engine/domain/placement.dart';
import 'board.dart';
import 'board_history.dart';

/// How a digit reaches a cell.
enum InputMode {
  /// Select a cell, then choose a digit. The default: it needs no explaining.
  cellFirst,

  /// Choose a digit, then tap cells. For a player filling many of one digit
  /// (`docs/SPEC.md` §3.4).
  digitFirst,
}

/// What a digit press writes.
enum EntryKind {
  /// A committed answer.
  value,

  /// A **settled note** — a candidate, the player's working out (D-11).
  note,
}

/// What the player is doing with one puzzle: the board, the selection, and the
/// digit they are holding.
///
/// Pure, immutable, and free of Flutter, so both input modes are one set of
/// rules tested without a widget. Two code paths through a widget is where the
/// modes drift apart.
final class PuzzleSession {
  PuzzleSession._({
    required this.history,
    required this.solution,
    required this.attempt,
    required this.isStrict,
    required this.hasEnded,
    required this.mode,
    required this.entryKind,
    required this.noteInk,
    this.selectedCell,
    this.lockedDigit,
    this.lastEdit,
  });

  /// A puzzle always opens in value mode, whatever mode the last one ended in.
  /// The mode belongs to the session, and each puzzle starts a new one.
  factory PuzzleSession.start({
    required Board board,
    required Grid solution,
    InputMode mode = InputMode.cellFirst,
    EntryKind entryKind = EntryKind.value,
    bool isStrict = false,
    Attempt attempt = Attempt.fresh,
  }) => PuzzleSession._(
    history: BoardHistory.start(board),
    solution: solution,
    attempt: attempt,
    isStrict: isStrict,
    // An attempt resumed on or past the limit is already over: a kill is not a
    // way back into one (D-95).
    hasEnded: isStrict && attempt.hasReachedStrictLimit,
    mode: mode,
    entryKind: entryKind,
    // A puzzle opens in the settled ink whatever ink the last one ended in.
    // The provisional ink belongs to a line of reasoning, and that reasoning
    // does not survive the puzzle it was about.
    noteInk: NoteKind.settled,
  );

  final BoardHistory history;

  /// What the puzzle's answer is.
  ///
  /// Required rather than optional: every real puzzle has one (the pack carries
  /// it, D-32), and a session that could be built without it would be a session
  /// that silently stops counting **mistake**s.
  ///
  /// Only ever compared against a *placement*. Nothing here consults it to
  /// decide what to draw, what a note means, or whether a digit may be entered
  /// — a wrong digit looks exactly like a right one unless **strict mode** is
  /// on (D-04).
  final Grid solution;

  /// What has happened to the player in this run (D-96).
  final Attempt attempt;

  /// Whether this **attempt** has already ended at the limit.
  ///
  /// Latched rather than derived, and that is the whole point. Deriving it from
  /// `isStrict && attempt.hasReachedStrictLimit` made turning **strict mode**
  /// off a way to carry on playing the board that had just ended — which is
  /// precisely the "continue without stakes" option D-95 refused. The switch
  /// governs what happens *next*; it does not reach back into a run that is
  /// over.
  final bool hasEnded;

  /// Whether the player has opted into stakes (D-04, D-94).
  ///
  /// Carried on the session rather than read where it is needed, so that
  /// turning it off mid-puzzle lifts the flagging and the cap in the same
  /// instant, from one place.
  final bool isStrict;

  final InputMode mode;

  /// Whether a digit press writes a value or a **settled note**.
  ///
  /// A mode, not a modifier held per entry: players work in note-heavy bursts
  /// (`docs/SPEC.md` §3.4).
  final EntryKind entryKind;

  /// Which ink a note entry is written in (D-11, D-89).
  ///
  /// A second axis rather than a third [EntryKind]. The two are independent —
  /// changing one never changes the other — which is what keeps
  /// [tapDigitLongPress] meaning exactly one thing: the opposite *mode*, in
  /// whichever ink is in force. Folded into the mode there would be no single
  /// opposite to go to.
  final NoteKind noteInk;

  /// The cell the player last touched, or null.
  final int? selectedCell;

  /// The digit held in [InputMode.digitFirst], or null when nothing is held.
  ///
  /// [Board.empty] means the eraser is held — the same value the board uses for
  /// "no digit", so holding an eraser and holding a digit are one rule.
  final int? lockedDigit;

  Board get board => history.board;

  /// The digit **candidate highlighting** is lighting cells for, or null.
  ///
  /// The digit held in [InputMode.digitFirst] if there is one; otherwise the
  /// digit in the selected cell. Derived rather than stored (D-88): a third,
  /// sticky source would need its own rules for when it clears, and every one
  /// of those is a way to leave the wrong digit lit. Both sources already clear
  /// themselves — a held digit is put down, a selection moves.
  ///
  /// D-13 reads "tapping a digit on the pad", which is literally the
  /// digit-first case. Cell-first reaches the same behaviour through the
  /// selection it already has: tap a digit into a cell and that cell is
  /// selected holding it.
  ///
  /// A held eraser lights nothing — [Board.empty] is not a digit. Neither does
  /// a cell holding only candidates: five candidates are not one digit.
  int? get highlightedDigit {
    final held = lockedDigit;
    if (held != null) return held == Board.empty ? null : held;
    final cell = selectedCell;
    if (cell == null) return null;
    final digit = board.digitAt(cell);
    return digit == Board.empty ? null : digit;
  }

  bool get canUndo => history.canUndo;

  /// The last thing that happened, so a caller can fire a haptic on a placement
  /// and stay silent on a refusal. Null when the last action changed nothing.
  final BoardEdit? lastEdit;

  PuzzleSession _with({
    BoardHistory? history,
    Attempt? attempt,
    bool? isStrict,
    bool? hasEnded,
    InputMode? mode,
    EntryKind? entryKind,
    NoteKind? noteInk,
    int? selectedCell,
    bool clearSelection = false,
    int? lockedDigit,
    bool clearLock = false,
    BoardEdit? edit,
  }) {
    return PuzzleSession._(
      history: history ?? this.history,
      solution: solution,
      attempt: attempt ?? this.attempt,
      isStrict: isStrict ?? this.isStrict,
      // Only ever latches on. Nothing but starting again clears it.
      hasEnded: hasEnded ?? this.hasEnded,
      mode: mode ?? this.mode,
      entryKind: entryKind ?? this.entryKind,
      noteInk: noteInk ?? this.noteInk,
      selectedCell: clearSelection ? null : (selectedCell ?? this.selectedCell),
      lockedDigit: clearLock ? null : (lockedDigit ?? this.lockedDigit),
      lastEdit: edit,
    );
  }

  /// The player touched a cell.
  ///
  /// In [InputMode.digitFirst] with something held, this places it; otherwise it
  /// only moves the selection.
  PuzzleSession tapCell(int cell) {
    if (isOver) return this;
    final held = lockedDigit;
    if (mode == InputMode.digitFirst && held != null) {
      final step = switch ((held, entryKind)) {
        (Board.empty, _) => history.erase(cell),
        // Sweeping a digit across cells in notes mode toggles it in each, so
        // one sweep both marks and unmarks.
        (_, EntryKind.note) => history.toggleNote(cell, held, ink: noteInk),
        (_, EntryKind.value) => null,
      };
      if (step == null) {
        final placed = _placing(cell, held);
        return _with(
          history: placed.step.history,
          attempt: placed.attempt,
          hasEnded: _endsOn(placed.attempt),
          selectedCell: cell,
          edit: placed.step.edit,
        );
      }
      return _with(history: step.history, selectedCell: cell, edit: step.edit);
    }
    return _with(selectedCell: cell);
  }

  /// The player pressed a digit.
  PuzzleSession tapDigit(int digit) => _digit(digit, entryKind);

  /// The player long-pressed a digit: one entry in the other mode.
  ///
  /// The mode in force is untouched, so a single note during a run of values —
  /// or a single value during a run of notes — costs no trip to the toggle
  /// (`docs/SPEC.md` §3.4).
  PuzzleSession tapDigitLongPress(int digit) => _digit(digit, _opposite);

  EntryKind get _opposite =>
      entryKind == EntryKind.value ? EntryKind.note : EntryKind.value;

  /// One rule for both kinds and both input modes.
  ///
  /// A second path through the widget for notes is exactly where the two would
  /// drift apart, and the drift would show up as a mode that behaves subtly
  /// differently depending on how it was reached.
  PuzzleSession _digit(int digit, EntryKind kind) {
    if (isOver) return this;
    if (mode == InputMode.digitFirst) {
      // A held digit is a brush, and a brush is swept many times — so there is
      // no "one entry in the other mode" to make. A long-press holds the digit
      // like any press, and the notes toggle, one tap away, is how the kind
      // changes. The alternative is a held brush whose kind differs from the
      // mode the pad is showing.
      return lockedDigit == digit
          ? _with(clearLock: true)
          : _with(lockedDigit: digit);
    }
    final cell = selectedCell;
    if (cell == null) return _with();
    if (kind == EntryKind.note) {
      final step = history.toggleNote(cell, digit, ink: noteInk);
      return _with(history: step.history, edit: step.edit);
    }
    final placed = _placing(cell, digit);
    return _with(
      history: placed.step.history,
      attempt: placed.attempt,
      hasEnded: _endsOn(placed.attempt),
      edit: placed.step.edit,
    );
  }

  /// Whether [next] takes this run past the **strict mode** limit.
  ///
  /// Read at the placement rather than asked of the session afterwards, so the
  /// ending is pinned to the moment it happened.
  bool _endsOn(Attempt next) =>
      hasEnded || (isStrict && next.hasReachedStrictLimit);

  /// The one place a value is put on the board, for both input modes.
  ///
  /// Counting lives here rather than at the two call sites because a second
  /// path is exactly where the two would drift apart — and a placement that
  /// counted in one mode and not the other would be invisible until a player
  /// compared their statistics with how they play.
  ///
  /// The report is taken against the board *before* the placement, which is
  /// what lets `overwritesCorrectValue` see what was there (D-05). A refused
  /// edit changes nothing and counts nothing: a digit that never landed is not
  /// a wrong answer.
  ({HistoryStep step, Attempt attempt}) _placing(int cell, int digit) {
    final before = board;
    final step = history.place(cell, digit);
    if (step.edit is! EditApplied) return (step: step, attempt: attempt);
    return (
      step: step,
      attempt: attempt.recording(
        inspectPlacement(
          grid: before.toGrid(),
          solution: solution,
          cell: cell,
          digit: digit,
          peers: before.peers,
        ),
      ),
    );
  }

  /// The cells whose placed value disagrees with the solution, while stakes
  /// are on. Empty otherwise, and empty of givens always.
  ///
  /// **Flagging states a fact; counting is what D-05 restricts.** A cell the
  /// player reached by overwriting a correct value is flagged like any other —
  /// **strict mode**'s promise is that the board is checked — and it still
  /// costs them nothing. The two questions are answered by different code for
  /// that reason.
  ///
  /// Derived rather than stored, the way **candidate highlighting** is (D-88):
  /// a flag has no lifecycle of its own, so there is no state to leave stale.
  /// Correcting the cell clears it, erasing clears it, and turning the mode off
  /// clears all of them in the same instant.
  ///
  /// A note is never here. This reads placed values only, so D-14 holds by
  /// construction rather than by care.
  Set<int> get flaggedCells {
    if (!isStrict) return const <int>{};
    final board = this.board;
    return <int>{
      for (var cell = 0; cell < GridGeometry.cellCount; cell++)
        if (!board.isGiven(cell) &&
            board.digitAt(cell) != Board.empty &&
            board.digitAt(cell) != solution.digitAt(cell))
          cell,
    };
  }

  /// Whether this **attempt** has ended at the **strict mode** limit.
  ///
  /// Only ever true with stakes on: outside **strict mode** there is no limit
  /// at all, not a larger one (constraint 1). While it is true the board is
  /// locked but *kept* — the player gets to look at what they did and decide
  /// (D-95).
  bool get isOver => hasEnded || (isStrict && attempt.hasReachedStrictLimit);

  /// How many **mistake**s the player has left, or null when stakes are off.
  ///
  /// Null rather than three, so a screen cannot show a limit to a player who
  /// has no limit (constraint 1).
  int? get mistakesRemaining => isStrict ? attempt.remainingInStrictMode : null;

  /// The puzzle as it was first opened, with the tally back to zero.
  ///
  /// The only route back to zero (D-96), and the way out of an ended
  /// **attempt** that keeps the player's own choice of mode: they opted into
  /// stakes, and failing is not a reason to decide otherwise for them.
  ///
  /// The history goes with it. A restarted puzzle has nothing to undo, because
  /// there is nothing before it any more.
  PuzzleSession restarted() => PuzzleSession.start(
    board: board.asFirstOpened(),
    solution: solution,
    mode: mode,
    isStrict: isStrict,
  );

  /// The player turned stakes on or off.
  ///
  /// Takes effect immediately in both directions. Leaving a mode the player
  /// chose must be as available as entering it, so turning it off lifts the
  /// flagging and the cap at once — it does not wait for the next puzzle.
  ///
  /// The tally is untouched either way. What the player did does not change
  /// because they changed their mind about being told about it.
  PuzzleSession withStrictMode(bool strict) =>
      strict == isStrict ? this : _with(isStrict: strict);

  /// The player changed what a digit press writes.
  ///
  /// Anything held is put down, for the reason [withMode] puts it down: a digit
  /// held as a note brush means something else as a value brush, and carrying
  /// it across would write the wrong thing on the player's next tap.
  PuzzleSession withEntryKind(EntryKind kind) =>
      kind == entryKind ? this : _with(entryKind: kind, clearLock: true);

  /// The player changed which ink a note entry writes.
  ///
  /// Anything held is put down, for the reason [withEntryKind] puts it down: a
  /// digit held as a settled brush means something else as a provisional one,
  /// and carrying it across would write the wrong ink on the next tap.
  ///
  /// The mode is untouched. Changing ink is not a way into or out of notes
  /// mode (D-89).
  PuzzleSession withNoteInk(NoteKind ink) =>
      ink == noteInk ? this : _with(noteInk: ink, clearLock: true);

  /// The player pressed erase.
  PuzzleSession tapErase() {
    if (isOver) return this;
    if (mode == InputMode.digitFirst) {
      return lockedDigit == Board.empty
          ? _with(clearLock: true)
          : _with(lockedDigit: Board.empty);
    }
    final cell = selectedCell;
    if (cell == null) return _with();
    final step = history.erase(cell);
    return _with(history: step.history, edit: step.edit);
  }

  /// The player ran **auto-notes**.
  ///
  /// Aimed at the board rather than a cell, so it needs neither a selection nor
  /// a held digit and leaves both exactly as they were.
  PuzzleSession fillNotes() {
    if (isOver) return this;
    final step = history.fillNotes();
    return _with(history: step.history, edit: step.edit);
  }

  /// The player abandoned the line of reasoning (D-11).
  ///
  /// Aimed at the board, so it needs neither a selection nor a held digit — and
  /// it disturbs neither, nor the mode, nor the ink. Clearing a hypothesis is
  /// not a reason to put the brush down.
  PuzzleSession clearProvisional() {
    if (isOver) return this;
    final step = history.clearProvisional();
    return _with(history: step.history, edit: step.edit);
  }

  /// The player kept the line of reasoning (D-91, **promote**).
  PuzzleSession promoteProvisional() {
    if (isOver) return this;
    final step = history.promoteProvisional();
    return _with(history: step.history, edit: step.edit);
  }

  /// The player pressed undo. Nothing to undo is a no-op, never an error — and
  /// an ended **attempt** is not something undo reaches back into (D-95).
  PuzzleSession tapUndo() => isOver ? this : _with(history: history.undo());

  /// The player changed the input mode.
  ///
  /// Anything held is put down: a locked digit means nothing in a mode that has
  /// no idea what it is, and carrying it across would place digits the player
  /// did not ask for on their next tap.
  PuzzleSession withMode(InputMode next) =>
      next == mode ? this : _with(mode: next, clearLock: true);
}
