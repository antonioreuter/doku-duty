# Tasks — add-provisional-notes

## 1. The ink in the note model (test-first, per the project rules)

`NoteSet` already packs presence and origin into one value. The ink is a third
nine-bit field on the same value, for the reason origin went there: two
structures that must agree about one cell are how they come to disagree.

- [x] 1.1 Failing test in `test/features/grid_input/note_set_test.dart`: a set
  carries ink per digit, `slotOf` is untouched, and presence, origin and ink are
  three independent facts about the same candidate
- [x] 1.2 Add the ink mask to `NoteSet`, keeping every existing operation's
  meaning — the whole `note_set_test.dart` and `board_notes_test.dart` suites
  pass unchanged
- [x] 1.3 Failing test: marking a digit in the ink it already carries removes it;
  marking it in the *other* ink converts it and leaves the slot alone (D-90)
- [x] 1.4 Failing test: a digit is never both inks at once, and converting one
  candidate changes no other candidate's ink, slot, or origin
- [x] 1.5 Failing test: ink and origin are independent — a **generated note**
  converted to provisional is provisional *and* still generated (D-15)

## 2. The ink axis in the session (test-first)

- [x] 2.1 Failing test in `test/features/grid_input/puzzle_session_test.dart`:
  `EntryKind` is still two-valued and the ink is a separate piece of session
  state (D-89)
- [x] 2.2 Failing test: changing the ink does not enter or leave notes mode, and
  changing the mode does not change the ink
- [x] 2.3 Failing test: a puzzle opens in the settled ink whatever ink the last
  one ended in
- [x] 2.4 Add the ink to `PuzzleSession` and route digit entry through it, so
  there is still one rule for both input modes and both entry kinds
- [x] 2.5 Failing test: a long-pressed digit in value mode writes a note in the
  ink in force, and leaves both mode and ink unchanged
- [x] 2.6 Failing test: digit-first sweeping marks and unmarks in the ink in
  force, and changing the ink puts down anything held — a held digit means
  something different in the other ink

## 3. Drawing the second ink

- [x] 3.1 Failing test in `test/features/grid_input/grid_painter_test.dart`: a
  **provisional note** is drawn in `turquoise` and a **settled note** in
  `nightIndigo`, each in the slot its digit owns
- [x] 3.2 Failing test: a provisional candidate carries a 1px rule 1.5px below
  its baseline, and a settled one carries none (D-73, `NoteInk.isUnderlined` and
  the two constants beside it)
- [x] 3.3 Add a third cached `TextPainter` set for the turquoise ink and draw the
  underline, laying the glyphs out once per instance as the other two are
- [x] 3.4 Failing test: the underline stays inside the note's own third of the
  cell, so the digit occupies the identical slot in either ink and nothing
  reflows (constraint 3)
- [x] 3.5 Golden for a cell holding all nine candidates in mixed inks, and for a
  board carrying both inks beside values — the reflow test from `add-notes`,
  re-run with the rule present
- [x] 3.6 **The colour-blind test.** Assert the two inks are distinguishable with
  hue removed: a golden or pixel comparison that fails if the underline is
  dropped. D-73 measured the inks at 1.07:1 under deuteranopia, so a test that
  only compares colours proves nothing (constraint 5)

## 4. Clear and promote (test-first)

- [x] 4.1 Failing test `test/features/grid_input/provisional_test.dart`: clearing
  removes every **provisional note** on the board and leaves every **settled
  note** exactly as it was
- [x] 4.2 Failing test: **promote** turns every provisional candidate settled,
  adds none, removes none, and leaves already-settled candidates untouched
- [x] 4.3 Implement both on `Board`, each returning one `EditApplied` carrying
  every cell it touched — the shape `add-note-automation` generalised the edit to
- [x] 4.4 Failing test: each is a single undo step that restores both the
  presence and the ink of what it changed
- [x] 4.5 Failing test: either control on a board with no **provisional note**
  refuses rather than pushing an empty step, and reports no error to the player
- [x] 4.6 Failing test: clearing and promoting are reachable without a selection
  or a held digit, because both are aimed at the board

## 5. Writing it down (constraint 9)

- [ ] 5.1 Failing test in `test/features/grid_input/note_storage_test.dart`: the
  sink writes `NoteKind.provisional` for a provisional candidate and `settled`
  for a settled one, in the same cell, with origin carried independently
- [ ] 5.2 Carry the ink through `RepositoryBoardSink.writeNotes` and the load
  path in `grid_providers.dart` — both currently hard-code `NoteKind.settled`
- [ ] 5.3 Failing test: a puzzle saved with both inks reopens with each candidate
  in its own ink, slot and origin
- [ ] 5.4 Failing test: a clearance and a promotion each reach the database as
  one commit, through the transactional `putCells` path
- [ ] 5.5 **Decide what happens to `NoteRepository.clearProvisional`.** It
  deletes rows directly, which undo cannot reverse and the board-diff write path
  does not use. Either route the clear through it *and* prove undo still
  restores, or delete it as superseded and say so in its place — leaving an
  unused second write path into note rows is how the two disagree later
- [ ] 5.6 Integration test in `integration_test/notes_test.dart`: a real database
  reopened after a clearance, a promotion, and a re-inking returns exactly the
  board that was on screen, and a second process finds the inks intact

## 6. The controls

- [ ] 6.1 Add the ink toggle, clear, and **promote** keys to `PadKey`, each with
  a glyph and a name
- [ ] 6.2 **Lay out a pad that now has six chrome controls.** Row 3 holds three
  today and the pad's rows are five wide. Add a fourth row rather than crowd one
  — and put clear and **promote** together, away from the keys a player taps
  constantly, because a mis-tap on clear discards the work they meant to keep
- [ ] 6.3 Failing widget test in `test/features/grid_input/notes_pad_test.dart`:
  each new key fires its own action, every key still holds the 44pt minimum, and
  none is ever disabled (constraint 1)
- [ ] 6.4 Failing test: the ink toggle reports itself as selected while the
  provisional ink is in force, so the ink is readable without marking a digit to
  find out (constraint 5)
- [ ] 6.5 Failing test: clear and **promote** are distinguishable to a screen
  reader by name, and each announces its name and not its glyph — the rule
  `add-note-automation` added to the `grid-input` spec
- [ ] 6.6 Route all three through `PuzzleController.tapKey`, firing the same
  haptic the other board-level actions do

## 7. Meeting what add-note-automation built

- [ ] 7.1 Failing test in `test/features/grid_input/auto_cleanup_test.dart`: a
  placement strips a **provisional note** from a **peer** exactly as it strips a
  settled one, and one undo restores it *in its own ink*
- [ ] 7.2 Failing test in `test/features/grid_input/auto_notes_test.dart`: the
  fill leaves a provisional candidate provisional — it adds what is missing and
  never re-inks what is there
- [ ] 7.3 Failing test in `grid_painter_test.dart`: **candidate highlighting**
  lights a cell carrying the digit in either ink
- [ ] 7.4 Confirm the fill still writes **settled note**s only, with a test that
  fails if it ever writes the second ink

## 8. Decisions and documents

- [ ] 8.1 Add **D-89** to `docs/DECISIONS.md`: the ink is a second axis rather
  than a third state on the notes toggle — the two are independent, and folding
  them into one control leaves long-press ("one entry in the opposite mode")
  with no defined meaning, because the opposite of provisional is two things
- [ ] 8.2 Add **D-90**: marking a digit in the other ink converts it rather than
  removing it, because the workflow that matters is deriving candidates and
  *then* testing one — removing would make the common path two taps and a mode
  change
- [ ] 8.3 Add **D-91**: **promote** ships alongside the clear D-11 names. A chain
  test ends one of two ways, and without promote the half that succeeds is the
  slower half
- [ ] 8.4 Add **promote** to the glossary in `openspec/project.md`
- [ ] 8.5 `flutter analyze` clean and `dart format` applied

## 9. Dynamic type overflow (finding, folded in)

Found while clamping the provisional underline in 3.4: the underline had to be
clamped because the *glyph* overflows, and nothing capped it. A candidate passes
its slot at about 1.2× and a value passes its cell at about 1.8× — ordinary
"Larger Text". Pre-existing in `add-grid-and-input`; folded in here because this
change already edits the same painter for the same reason.

- [x] 9.1 Failing test in `grid_painter_test.dart`: a candidate never exceeds its
  slot and a value never exceeds its cell, at 1×, 1.5×, 2×, 3× and 5×
- [x] 9.2 Cap each glyph at layout in `grid_painter.dart` — measure, and divide
  the font size by the overflow ratio. No tuned constant: the ratio between a
  size and the box it fills is a property of the face (D-74, D-92)
- [x] 9.3 Cap on the glyph's width and its **em box**, not `TextPainter.height`.
  A Nunito line is ~1.36em and mostly empty leading, so the laid-out height
  reports an overflow at the *default* scale and capping on it shrinks type that
  visibly fits — caught because the goldens moved at 1×
- [x] 9.4 Failing test: the cap is a ceiling, not a fixed size — type still grows
  below it — and the default scale renders exactly as it did
- [x] 9.5 Failing test: a narrower grid caps sooner, because the box is the cell
  rather than a constant
- [x] 9.6 Throw the glyph caches away when the grid is drawn at a new size, so a
  rotation or a split-screen drag cannot keep glyphs measured against a cell that
  no longer exists
- [x] 9.7 **Fix the test that let this ship.** `notes stay inside their cell at
  the largest type` asserted no exception and the *widget's* size — both true
  while every glyph inside overflowed. It now measures the glyphs, at 1.5× as
  well
- [x] 9.8 Record **D-92**, and the requirement in a `grid-input` delta — a reader
  at large type can observe this, so it needed a spec and not only a test

## Platform checks

- [ ] Verified on iOS — both inks render on a device at the default and largest
  dynamic type, and a clearance, a promotion and a re-inking each survive a force
  quit
- [ ] Verified on Android — the same, with the 11px underline confirmed to draw
  at the device's own pixel ratio rather than disappearing into rounding
- [ ] Accessibility: the two inks are distinguishable with hue removed (task
  3.6), the three new keys carry names and meet the 44pt target, the ink in force
  is reported as selected, and neither ink is affected by **reduce effects** —
  both are states, not animations
- [ ] Accessibility: the grid is legible at the OS's largest text setting on both
  platforms (D-92, group 9). Verified on the host at 1×–5×; the device check is
  what confirms the cap holds against the platform's own scaler rather than the
  linear one the tests use
