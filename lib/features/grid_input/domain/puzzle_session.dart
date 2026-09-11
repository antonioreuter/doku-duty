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
    required this.mode,
    required this.entryKind,
    this.selectedCell,
    this.lockedDigit,
    this.lastEdit,
  });

  /// A puzzle always opens in value mode, whatever mode the last one ended in.
  /// The mode belongs to the session, and each puzzle starts a new one.
  factory PuzzleSession.start({
    required Board board,
    InputMode mode = InputMode.cellFirst,
    EntryKind entryKind = EntryKind.value,
  }) => PuzzleSession._(
    history: BoardHistory.start(board),
    mode: mode,
    entryKind: entryKind,
  );

  final BoardHistory history;
  final InputMode mode;

  /// Whether a digit press writes a value or a **settled note**.
  ///
  /// A mode, not a modifier held per entry: players work in note-heavy bursts
  /// (`docs/SPEC.md` §3.4).
  final EntryKind entryKind;

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
    InputMode? mode,
    EntryKind? entryKind,
    int? selectedCell,
    bool clearSelection = false,
    int? lockedDigit,
    bool clearLock = false,
    BoardEdit? edit,
  }) {
    return PuzzleSession._(
      history: history ?? this.history,
      mode: mode ?? this.mode,
      entryKind: entryKind ?? this.entryKind,
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
    final held = lockedDigit;
    if (mode == InputMode.digitFirst && held != null) {
      final step = switch ((held, entryKind)) {
        (Board.empty, _) => history.erase(cell),
        // Sweeping a digit across cells in notes mode toggles it in each, so
        // one sweep both marks and unmarks.
        (_, EntryKind.note) => history.toggleNote(cell, held),
        (_, EntryKind.value) => history.place(cell, held),
      };
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
    final step = kind == EntryKind.note
        ? history.toggleNote(cell, digit)
        : history.place(cell, digit);
    return _with(history: step.history, edit: step.edit);
  }

  /// The player changed what a digit press writes.
  ///
  /// Anything held is put down, for the reason [withMode] puts it down: a digit
  /// held as a note brush means something else as a value brush, and carrying
  /// it across would write the wrong thing on the player's next tap.
  PuzzleSession withEntryKind(EntryKind kind) =>
      kind == entryKind ? this : _with(entryKind: kind, clearLock: true);

  /// The player pressed erase.
  PuzzleSession tapErase() {
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
    final step = history.fillNotes();
    return _with(history: step.history, edit: step.edit);
  }

  /// The player pressed undo. Nothing to undo is a no-op, never an error.
  PuzzleSession tapUndo() => _with(history: history.undo());

  /// The player changed the input mode.
  ///
  /// Anything held is put down: a locked digit means nothing in a mode that has
  /// no idea what it is, and carrying it across would place digits the player
  /// did not ask for on their next tap.
  PuzzleSession withMode(InputMode next) =>
      next == mode ? this : _with(mode: next, clearLock: true);
}
