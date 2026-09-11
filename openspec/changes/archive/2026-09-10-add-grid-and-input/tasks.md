# Tasks — add-grid-and-input

The board model and the undo stack are pure logic and go on the test-first list
in `openspec/config.yaml` by the same argument the engine does: they carry no
Flutter import, and a bug in either corrupts a save. Everything above them is a
widget, tested as one.

Constraint 2 is the acceptance criterion for this whole change, and it is a
product requirement rather than an aspiration. The simulator lies about frame
timing, so the number that counts is measured on a mid-tier Android device.

## 1. The board

- [x] 1.1 Write the failing test: a board is built from a puzzle's givens and its
      placed values, and knows which cells are givens.
- [x] 1.2 Write the failing test: placing a digit into an empty cell changes that
      cell and nothing else; the board before is unchanged (immutable value).
- [x] 1.3 Write the failing test: a given refuses a placement and an erase, and
      says so as a value rather than by throwing.
- [x] 1.4 Write the failing test: erasing clears a placed value and leaves a
      given alone.
- [x] 1.5 Implement the board. Pure Dart under `domain/`, no Flutter import — the
      rule D-83 scopes to that directory.
- [x] 1.6 Test the board round-trips the 81-character form `PuzzleSaves` stores,
      so a save is the board and not a second encoding of it.
- [x] 1.7 Test completion: a board is finished when every cell holds a digit and
      no **unit** repeats one. Reuse the engine's check rather than writing a
      second one.

## 2. Undo

- [x] 2.1 Write the failing test: undo after a placement restores what the cell
      held before, including when that was another placed value.
- [x] 2.2 Write the failing test: undo after an erase restores the erased value.
- [x] 2.3 Write the failing test: undo repeated to the start returns the board the
      puzzle was opened with, and then does nothing.
- [x] 2.4 Write the failing test: undo with nothing to reverse is a no-op, not an
      error — constraint 1 applies to controls as well as to play.
- [x] 2.5 Implement the undo stack. Full depth within the session; it is not
      persisted, and a test asserts a reopened puzzle has an empty stack rather
      than a stale one.
- [x] 2.6 Test that an action refused by the board — a placement onto a given —
      pushes nothing, so undo never reverses a move that never happened.

## 3. Drawing the grid

- [x] 3.1 Implement the grid painter on a custom canvas (D-31): cell lines,
      heavier **unit** boundaries, givens and placed values in different weights.
- [x] 3.2 Golden test: an empty grid, a part-filled grid, and a solved grid. In
      the default season and one repainted season — there is no dark theme
      (`DokuTheme` is `Brightness.light` only), and seasons repainting surfaces
      is the variation axis this app actually has.
- [x] 3.3 Test that a given and a placed value differ by weight, not only by
      colour — constraint 5, and the golden is what pins it.
- [x] 3.4 Test the painter repaints only when the board, the selection, or the
      theme changed. `shouldRepaint` returning true unconditionally is how the
      latency budget is lost without anything looking wrong.
- [x] 3.5 Test the grid stays square and centred at the narrowest and widest
      supported widths, and that it takes the width it is given (D-84). The 44pt
      floor is asserted on the number-pad keys in 5.1, not on cells: nine 44pt
      cells need 396pt of width that most phones do not have.

## 4. Selection and peer highlighting

- [x] 4.1 Test that a tap selects the cell under it, computed from the tap offset
      rather than from 81 hit-test regions.
- [x] 4.2 Test that selecting a cell marks its twenty peers, and that the
      selected cell stays distinguishable from them.
- [x] 4.3 Test that moving the selection unmarks the previous cell's peers.
- [x] 4.4 Test that selection and peer highlight are two depths of the focus
      token, not two hues (D-53, constraint 4), and that the selected cell
      carries a border so colour is never the only signal (constraint 5).
- [x] 4.5 Golden test: a selected cell with its peers marked.

## 5. The number pad

- [x] 5.1 Implement the pad: nine digits and erase, every target at least 44pt.
- [x] 5.2 Test cell-first input: select a cell, tap a digit, the digit lands.
- [x] 5.3 Test erase clears a placed value and does nothing to a given.
- [x] 5.4 Test that a digit already placed nine times is still offered — nothing
      is disabled, because a disabled control is a failure state wearing a
      different hat (constraint 1). If this proves wrong in play it is a decision
      to record, not a default to slip in.
- [x] 5.5 Test undo is reachable from the pad and reverses the last action.
- [x] 5.6 Test the pad fires the placement haptic from the design system's named
      vocabulary rather than a raw platform call.

## 6. Number-first input

- [x] 6.1 Add the setting to `AppSetting`, defaulting off, and test that a player
      who has never touched it gets cell-first.
- [x] 6.2 Write the failing test: with the setting on, choosing a digit and then
      tapping cells places that digit, and the digit stays chosen.
- [x] 6.3 Implement it as one input controller with two modes, not two paths
      through the widget — the second path is where the two modes drift.
- [x] 6.4 Test switching modes mid-puzzle drops any locked digit rather than
      carrying it into a mode that has no idea what it is.
- [x] 6.5 Test the stored choice survives a restart, and that its key is the enum
      name so a rename is a visible break (the rule `AppSetting` already sets).

## 7. Saving as it is played

- [x] 7.1 Test that placing a digit writes the board — every change, never on a
      timer. Same discipline as D-33, applied to values.
- [x] 7.2 Test that the write happens after the digit is on screen, so the frame
      is never waiting on the database.
- [x] 7.3 Test that erase and undo are saved the same way as a placement.
- [x] 7.4 Test that reopening a puzzle restores the board, and that the undo
      stack starts empty.
- [x] 7.5 Test that completing a puzzle records it solved through the existing
      `markSolved`, so it stops being offered.

## 8. Reaching a puzzle

- [x] 8.1 Build the temporary rank picker: six entries, each opening the next
      unsolved puzzle at that **rank**. Mark it in the code as scaffolding
      `add-season-map` deletes.
- [x] 8.2 Test that choosing a **rank** opens a puzzle of that **rank** the player
      has not solved.
- [x] 8.3 Test that a **rank** with nothing left says so and blocks nothing —
      no lock, no error, no failure state (constraint 1).
- [x] 8.4 Test the picker does not hold the first frame: it reads the **pack**
      after the frame and fills in, the same ordering the config refresh uses.
- [x] 8.5 Add the puzzle route and test that it addresses a puzzle by id rather
      than by a bare string, the rule `Routes` already sets.

## 9. The settings screen

- [x] 9.1 Build a plain settings list showing the stored settings, reachable from
      home.
- [x] 9.2 Test that changing a setting persists it and that a restart reads it
      back.
- [x] 9.3 Test the defaults a new player gets: auto-check off, strict mode off
      (D-04, constraint 1). This is the single most consequential default in the
      product and it deserves a test that names it.
- [x] 9.4 Test that nothing on this screen reads a setting no change has
      implemented yet as though it worked — a row that lies is worse than a row
      that is absent.

## 10. Latency

- [x] 10.1 Measure tap-to-repaint for a placement on the host, and record it.
- [ ] 10.2 Measure the same on a mid-tier Android device and an iOS device, and
      record both beside the engine's numbers in `docs/PERFORMANCE.md`.
      **NOT DONE — no physical Android phone was available.** Measured on an
      emulator and a simulator instead and recorded as such; the gap is carried
      on change 6 in `openspec/BACKLOG.md` so it survives this archive. Left
      unticked deliberately: ticking it would report a measurement nobody took.
- [x] 10.3 Test that no animation in this change blocks the next tap: a second
      tap during any transition is accepted (D-46, constraint 2).
- [x] 10.4 Profile a full grid fill — 81 placements in sequence — and confirm no
      frame budget is missed as the board fills.

## 11. Close out

- [x] 11.1 `flutter analyze` clean and `dart format --set-exit-if-changed`
      passing.
- [x] 11.2 Confirm no note logic, error state, timer, or completion effect crept
      in. Each belongs to a later change, and each is easy to add "while we are
      here".
- [x] 11.3 Confirm the eight colour tokens are unchanged and no ninth hue
      appeared (constraint 4).

## Platform checks

- [x] Verified on iOS: input latency and the golden grid on a simulator, plus a
      placement haptic on a real device — the simulator does not have one
- [ ] Verified on Android: **the latency number that counts is measured here, on
      a mid-tier device, not on an emulator.** The backlog names this as the
      thing to watch for this change, and an emulator will happily report a
      budget the phone misses. **NOT DONE** — see 10.2. Everything else on
      Android passed on the emulator: the pack loads, the grid solves, and
      tap-to-repaint medians 397 µs against a 100 ms budget
- [x] Accessibility: the grid at the largest dynamic type without clipping, the
      44pt minimum target on every control, selection identifiable without
      colour, and the whole change usable with reduce-effects on
