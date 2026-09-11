# Tasks — add-notes

All notes logic is on the test-first list in `openspec/config.yaml` under
`rules.tasks` — named there explicitly, alongside the puzzle engine and the
mistake model. The reason is constraint 9: a note write that stops landing has no
visible symptom until a player loses an hour of work, and no amount of careful
reading catches it. The failing test comes first for every one of these.

Positional layout is the other thing to guard. A slot is a function of the digit
and nothing else — not insertion order, not how many candidates the cell holds.

## 1. The note set

- [x] 1.1 Write the failing test: a cell's candidates are a set of digits, and
      marking a digit already present removes it, so one control both marks and
      unmarks.
- [x] 1.2 Write the failing test: removing one candidate leaves the other eight
      untouched and identifiable — the same nine-bit reasoning the engine's
      `Candidates` already uses.
- [x] 1.3 Write the failing test: a slot is derived from the digit alone. Assert
      the same digit lands in the same slot in a cell holding one candidate and a
      cell holding nine.
- [x] 1.4 Implement the note set. Pure Dart under `domain/`, no Flutter import
      (D-83).
- [x] 1.5 Test that a board carries notes per cell and that a cell holding a
      value reports no candidates — the two are exclusive by construction, which
      is what D-16 rests on.

## 2. Notes on the board

- [x] 2.1 Write the failing test: marking a candidate in an empty cell changes
      that cell and nothing else; the board before is unchanged.
- [x] 2.2 Write the failing test: marking a candidate in a cell holding a value
      is refused as a value, and marking one in a given is refused the same way.
- [x] 2.3 Write the failing test: placing a value clears that cell's candidates,
      and the edit records what it cleared.
- [x] 2.4 Implement notes on the board, extending the existing edit result rather
      than adding a parallel one — two shapes of "what changed" is how undo and
      the save get different ideas about the same action.
- [x] 2.5 Test the stored form round-trips notes alongside placed values.

## 3. Undo across both

- [x] 3.1 Write the failing test: undoing a marked candidate removes it and
      leaves the rest of the cell alone.
- [x] 3.2 Write the failing test: undoing a removed candidate puts it back in its
      own slot.
- [x] 3.3 Write the failing test: **undoing a value placement restores every
      candidate it cleared**, in their own slots. This is the one that loses a
      player's working out if it is wrong, and it is silent when it is.
- [x] 3.4 Write the failing test: notes and values share one history and undo
      reverses them in the exact order they were made.
- [x] 3.5 Implement it. One stack, one kind of entry.
- [x] 3.6 Test that a refused note action pushes nothing, so undo never reverses
      a move that never happened.

## 4. Drawing them

- [x] 4.1 Implement note painting: nine slots per cell, derived from the cell rect
      the painter already computes, at the `gridNote` type role.
- [x] 4.2 Golden test: a cell with one candidate, a cell with nine, and a board
      with both notes and values.
- [x] 4.3 **The reflow test.** Golden a cell with all nine candidates, remove
      candidate 5, and golden it again: every remaining glyph must be at the
      pixel it was at before. This is constraint 3, and it is the test the
      backlog says catches the defect that makes an app feel bad.
- [x] 4.4 Test that notes use the settled ink token and nothing else — one hue,
      and position carries identity so colour is never the only signal.
- [x] 4.5 Test `shouldRepaint`: a board whose values changed but whose note sets
      were rebuilt into equal ones must not redraw.
- [x] 4.6 Test notes stay inside their cell at the largest dynamic type, and that
      the board does not grow.

## 5. The mode

- [x] 5.1 Write the failing test: notes mode stays in force across several
      entries, and a puzzle opens in value mode whatever the last one ended in.
- [x] 5.2 Write the failing test: long-pressing a pad digit makes that one entry
      in the opposite mode and leaves the mode in force unchanged.
- [x] 5.3 Implement the toggle and the long-press as one mode rule, not two paths
      — the second path is where the modes drift.
- [x] 5.4 Add the toggle to the pad, at the 44pt minimum, showing which mode is
      in force.
- [x] 5.5 Test the toggle is never disabled and never refuses a press
      (constraint 1).

## 6. Digit-first notes

- [x] 6.1 Write the failing test: holding a digit in notes mode and tapping empty
      cells marks that candidate in each, and the digit stays held.
- [x] 6.2 Write the failing test: tapping a cell that already has the held
      candidate removes it, so one sweep both marks and unmarks.
- [x] 6.3 Implement it inside the existing session rules rather than beside them.
- [x] 6.4 Test switching either mode mid-puzzle drops the held digit, the rule
      `add-grid-and-input` already set.

## 7. Written on every change

- [x] 7.1 Test that marking a candidate writes it — every change, never on a
      timer (D-33, constraint 9).
- [x] 7.2 Test that removing one writes that too, as a delete rather than a
      rewrite of the cell.
- [x] 7.3 Test that a rapid sequence of marks produces one write each, with none
      dropped or coalesced.
- [x] 7.4 Test that the write happens after the candidate is on screen.
- [x] 7.5 Test that clearing a cell's notes for a value placement is written, and
      that undoing it writes them back.
- [x] 7.6 Test that every note is written as a **settled note** and manual in
      origin — this change never writes the other values, and a test says so, so
      changes 8 and 9 inherit a clean slate.

## 8. Never a mistake

- [x] 8.1 Test a candidate that contradicts the solution is drawn like any other
      and recorded nowhere (D-14).
- [x] 8.2 Test a candidate that contradicts a **peer** holding that value is
      still marked.
- [x] 8.3 Test nothing in this change reads auto-check or strict mode — those
      arrive with change 10, and notes are outside them in any case.

## 9. Close out

- [x] 9.1 `flutter analyze` clean and `dart format --set-exit-if-changed`
      passing.
- [x] 9.2 Confirm no auto-cleanup, candidate highlighting, auto-notes, or
      provisional ink crept in. Each is a later change and each is a natural
      thing to add "while we are here".
- [x] 9.3 Measure the cost of a repaint with a board at maximum note density —
      every empty cell holding all nine — and record it beside the existing
      numbers in `docs/PERFORMANCE.md`.

## Platform checks

- [x] Verified on iOS: notes render legibly at 11px on a simulator, and an
      `integration_test` confirms a marked candidate survives a real process
      death — the half of constraint 9 no host test can reach
- [x] Verified on Android: the same process-death test on an emulator, plus the
      repaint cost at maximum note density. **The outstanding mid-tier device
      profile from change 6 applies here too** — this change adds up to 729
      glyphs to a board that had 81, so if a phone becomes available it should be
      measured with a dense board, not an empty one
- [x] Accessibility: notes at the largest dynamic type without leaving the cell,
      the settled ink against the cell surface at the documented contrast, and
      the whole change usable with reduce-effects on
