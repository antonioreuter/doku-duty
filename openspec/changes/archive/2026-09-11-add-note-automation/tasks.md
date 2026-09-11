# Tasks — add-note-automation

## 1. An edit that can change more than one cell

The history entry records one cell's candidates. **Auto-cleanup** changes up to
twenty and **auto-notes** up to eighty-one, so this generalisation comes first —
everything below depends on it, and it is where a silent bug would live.

- [x] 1.1 Establish the regression net: `undo_test.dart`, `undo_notes_test.dart`,
  and `board_notes_test.dart` green before anything moves. Group 1 is a pure
  refactor with no new behaviour, so it gets no red test of its own — the
  multi-cell undo test is 2.3, where **auto-cleanup** first produces one
- [x] 1.2 Generalise `EditApplied` in `lib/features/grid_input/domain/board.dart`
  from `notesBefore`/`notesAfter` to note changes keyed by cell, keeping those
  two as getters so nothing outside `board.dart` changes
- [x] 1.3 Rewrite `BoardHistory.undo` in
  `lib/features/grid_input/domain/board_history.dart` to restore every cell an
  edit recorded, value first and candidates after, and confirm the existing
  `undo_test.dart` and `undo_notes_test.dart` still pass unchanged

## 2. Auto-cleanup (test-first, per the project rules)

- [x] 2.1 Failing test `test/features/grid_input/auto_cleanup_test.dart`:
  placing a value strips that digit from all twenty **peer**s, leaves the same
  digit marked in a non-peer, and moves no other candidate in any touched cell
  (constraint 3)
- [x] 2.2 Implement cleanup inside `Board.place`, recording every stripped
  candidate on the returned `EditApplied`
- [x] 2.3 Failing test: one undo of that placement restores the cell's own
  candidates *and* every **peer**'s stripped candidate; erasing the value
  instead restores nothing
- [x] 2.4 Failing test: cleanup records nothing against the player and flags no
  cell, including when it strips a candidate that was correct (D-14,
  constraint 1)
- [x] 2.5 Confirm no setting, menu entry, or constructor flag can disable it —
  a test that asserts the absence, so a later change cannot add one quietly
  (D-12)

## 3. Origin in the domain model (test-first)

The store has carried `NoteOrigin` since `add-persistence-layer`; nothing has
ever written anything but `manual`. **Auto-notes** is the first writer of the
other value, so origin reaches the domain model before the fill does.

- [x] 3.1 Failing test in `test/features/grid_input/note_set_test.dart`: a note
  set carries manual against generated per digit, `slotOf` is unchanged, and a
  digit toggled by the player is manual whatever it was before
- [x] 3.2 Add the origin mask to `NoteSet` in
  `lib/features/grid_input/domain/note_set.dart`, keeping the existing mask
  operations and their meanings intact
- [x] 3.3 Failing test in `test/features/grid_input/note_storage_test.dart`: the
  sink writes `NoteOrigin.generated` for a generated candidate and `manual` for
  a hand-marked one, in the same cell
- [x] 3.4 Carry origin through `RepositoryBoardSink.writeNotes` and the load path
  in `lib/features/grid_input/application/grid_providers.dart`, which currently
  drops it on both sides
- [x] 3.5 Failing test: a puzzle saved with mixed origins reopens with each
  candidate's origin intact

## 4. Auto-notes fill (test-first)

- [x] 4.1 Failing test `test/features/grid_input/auto_notes_test.dart`: on an
  untouched board every empty cell gains each digit no **peer** holds as a value,
  and no given or filled cell gains anything
- [x] 4.2 Failing test: the fill unions — hand-marked candidates survive and stay
  manual, added ones are generated, and a legal candidate the player had
  eliminated comes back
- [x] 4.3 Implement the fill on `Board`, using the engine's existing candidate
  code rather than a second definition of "legal", and return it as one
  `EditApplied`
- [x] 4.4 Failing test: one undo reverses the whole fill and leaves every
  hand-marked candidate exactly as it was; a second undo reaches the action
  before it
- [x] 4.5 Failing test: the fill is computed from the values on the board as they
  stand, including a value that contradicts the solution, and flags nothing
  (D-14)
- [x] 4.6 Failing test: nothing is charged, metered, or offered — this change
  ships the mechanism, not the perk (change 19)

## 5. Writing it down (constraint 9)

- [x] 5.1 Failing test in `test/features/grid_input/note_saving_test.dart`: the
  fill's candidates are all written with the action, and a fake sink that
  records call order shows one commit rather than a deferred batch
- [x] 5.2 Add a transactional multi-note write to `NoteRepository`, documenting
  why a transaction is not the batching constraint 9 forbids
- [x] 5.3 Failing test: a write that fails part-way leaves the stored board as it
  was rather than part-filled, and reaches `onError` rather than the player
  (D-03)
- [x] 5.4 Integration test in `integration_test/notes_test.dart`: a real database
  reopened after a fill and after a cleanup returns exactly the board that was on
  screen
- [x] 5.5 Confirm the fill's write stays off the frame path — the board is
  published before the write starts, as values and single notes already are

## 6. Candidate highlighting

- [x] 6.1 Failing test in `test/features/grid_input/puzzle_session_test.dart`:
  the highlighted digit is the held digit in digit-first, the selected cell's
  digit in cell-first, and nothing when the selected cell is empty
- [x] 6.2 Expose the highlighted digit on `PuzzleSession` as derived state, with
  no new field to keep in step
- [x] 6.3 Failing test in `test/features/grid_input/grid_painter_test.dart`:
  every cell holding the digit is lit, as a candidate or as a value, and no other
  cell is
- [x] 6.4 Paint the highlight in `grid_painter.dart` using `nightIndigo`'s pale
  derivative — the tint `docs/DESIGN.md` §2 already names — below selection and
  above nothing else yet (D-49)
- [x] 6.5 Failing test: where a lit cell is also the selected cell or one of its
  **peer**s, the focus fill is what shows
- [x] 6.6 Golden test in `test/features/grid_input/note_golden_test.dart` for a
  highlighted board, in the standard palette and under a season that repaints
  both surfaces — the app has one theme plus season repaints, not light and
  dark, and the useful check is that the highlight tint does *not* move with
  the season (D-55, constraint 4)

## 7. The control for the fill

- [x] 7.1 Add an auto-notes key to the pad's `PadKey` set in
  `number_pad.dart`, with a label and semantics matching the existing keys
- [x] 7.2 Failing widget test in `test/features/grid_input/notes_pad_test.dart`:
  pressing it fills the board, pressing undo once takes the whole fill back
- [x] 7.3 Route it through `PuzzleController.tapKey` alongside the other keys,
  firing the same haptic a placement does

## 8. Decisions and documents

- [x] 8.1 Add **D-87** to `docs/DECISIONS.md`: **auto-notes** unions rather than
  replaces — hand-marked candidates survive and legal candidates the player
  eliminated come back, because "every legal candidate" is what the action means
  and one undo makes it free to try
- [x] 8.2 Add **D-88** to `docs/DECISIONS.md`: **candidate highlighting** is
  driven by the held digit or the selected cell's digit, not by a third piece of
  sticky state — D-13's "tapping a digit" reads literally only in digit-first,
  and cell-first reaches the same behaviour through the selection it already has
- [x] 8.3 Confirm the three glossary entries added to `openspec/project.md`
  (**auto-notes**, **candidate highlighting**, **generated note**) still match
  what shipped, and correct them if the implementation moved
- [x] 8.4 `flutter analyze` clean and `dart format` applied

## 9. Pad announcements (follow-up)

Raised by 7.2: the pad's `Semantics` label merged with the glyph drawn on the
key, so a screen reader read "Fill notes ⁙". Every key already had it — this is
`add-grid-and-input`'s defect, surfaced by adding a key to the same pad.

- [x] 9.1 Exclude the glyph, not the button. `excludeSemantics` on the outer
  node would also drop the tap action `Pressable` contributes, leaving a key a
  screen reader can name but not press — so the `Text` is wrapped in
  `ExcludeSemantics` instead
- [x] 9.2 Tighten `notes_pad_test.dart` from `startsWith` to the exact label,
  and assert the tap action survived the exclusion
- [x] 9.3 Regression test over *every* key in `accessibility_test.dart` — digits,
  erase, undo, notes, auto-notes — so the glyph cannot creep back one key at a
  time
- [x] 9.4 Record the rule as a requirement in the `grid-input` delta: a pad key
  announces its name, never its glyph, and stays pressable. A screen-reader user
  can observe this, so it needed a spec and not only a test
- [x] 9.5 Cover the held-key case the new requirement also states: a held digit
  and an active notes mode report as selected (constraint 5)

## Platform checks

- [x] Verified on iOS — `integration_test/notes_test.dart` green on the iOS 26.5
  simulator (iPhone 17), `--flavor dev`: the fill reaches disk whole with its
  origins, the cleanup reaches disk with its placement, and a second test
  process finds the fill still there
- [x] Verified on Android — the same file green on the API 37 emulator
  (`emulator-5554`), `--flavor dev`, including the cross-process read
- [x] Accessibility: the highlight is inferable without colour (the lit cell
  holds the digit it is lit for — asserted in `accessibility_test.dart`), the
  auto-notes key carries the semantic label "Fill notes" and meets the 44pt
  target, and highlighting is unaffected by **reduce effects** — it is a state,
  not an animation, and the painter never reads the setting

**Not covered by the above.** Both platform runs used emulators, not physical
hardware, so they share the gap the backlog already records against
`add-grid-and-input`. The Android "don't keep activities" variant was not run:
that setting recycles activities rather than killing the process, so it would
not have exercised what the check claims. Real process-death coverage is the
cross-process assertion above, which does hold on both platforms.
