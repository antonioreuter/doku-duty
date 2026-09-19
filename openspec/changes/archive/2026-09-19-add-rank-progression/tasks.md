# Tasks — add-rank-progression

`rank-progression` is on the project's test-first list, so every task under
sections 2 and 3 writes the failing test before the code that satisfies it. The
domain carries no Flutter import.

## 1. The decisions and the vocabulary

- [x] 1.1 `docs/DECISIONS.md` gains **D-102**: a player's **rank** is the hardest
      **rank** they have completed a puzzle at, it rises on a **solve record**
      and never falls. Rationale covers what was rejected — a solve threshold per
      **rank**, which holds a capable player at a **rank** until they have
      repeated themselves, and is a grind gate constraint 1 has no room for
- [x] 1.2 `docs/DECISIONS.md` gains **D-103**: **rank**s above the player's are
      marked and stay fully openable. Rationale names the alternative — a hard
      gate — and why it is refused: it would make **rank** a permission rather
      than an achievement, and be the first place the game tells a player no
- [x] 1.3 `docs/DECISIONS.md` gains **D-104**: a **technique unlock** is derived
      from that technique's counter standing above zero, never stored separately.
      Rationale: a stored set and a counter are two answers to one question, and
      they drift
- [x] 1.4 Glossary entries for **technique unlock** and **solve record** in
      `openspec/project.md` *(done while writing the specs — verify they are
      still accurate against what was built, and correct them if not)*

## 2. The rank rule, in pure Dart

- [x] 2.1 Failing test: the **rank** of a player with no **solve record** is
      Greenhorn, and that is a starting position rather than an absence
- [x] 2.2 Failing test: the rule takes the hardest **rank** among the records —
      a harder solve raises it, an easier one leaves it alone, and order of
      arrival does not matter
- [x] 2.3 Failing test: nothing lowers it — a **mistake**, an **attempt** ended
      in **strict mode**, an abandoned puzzle, and a rotated **season** each
      leave it where it was
- [x] 2.4 `lib/features/rank_progression/domain/` — the rule satisfying 2.1–2.3,
      pure Dart, no Flutter import. A test asserts the import is absent, matching
      how `puzzle-engine` and `mistake-model` already guard theirs
- [x] 2.5 Failing test, then the code: which **rank**s are above a given one, so
      the picker's mark and any later gate ask the capability rather than
      comparing enum indices at the call site

## 3. The solve record

- [x] 3.1 Failing test: a completed puzzle writes all four parts — marked solved,
      lifetime counters, the counters for the techniques it required, and the
      **attempt**'s perfection
- [x] 3.2 Failing test: the parts are written in **one** transaction, so a
      failure part-way leaves none of them. `markSolved` and `recordSolve` live
      in two repositories today and each opens its own transaction; one of them
      committing alone is the bug this test exists to catch
- [x] 3.3 Failing test: a puzzle already holding a **solve record** does not
      raise the counters a second time. `markSolved` is idempotent but
      `recordSolve` increments unconditionally, so the guard is real work, not a
      restatement
- [x] 3.4 Failing test: an abandoned puzzle and an **attempt** ended in **strict
      mode** without a solved board write nothing
- [x] 3.5 The recorder satisfying 3.1–3.4
- [x] 3.6 Failing test, then the code: the techniques counted are the grader's
      `techniquesUsed`, and a puzzle requiring fewer techniques than its **rank**
      permits counts only the ones it needed
- [x] 3.7 Failing test: the **technique unlock** reads from the counter — above
      zero is unlocked, zero is not yet met, and no separate set is stored

## 4. Wiring completion to the record

- [x] 4.1 The grade is taken once when a puzzle is opened and carried on the
      session, so `techniquesUsed` is in hand at completion. Test that no
      grading happens on a placement, an erase, or an undo (constraint 2)
- [x] 4.2 Measure the open-path grade on host, emulator, and simulator, and
      record it in `docs/PERFORMANCE.md` beside the existing figures. If it is
      slow enough to be felt on open, move it off the open path rather than
      accepting it
- [x] 4.3 Completing a board writes the **solve record**, once, at the moment of
      completion. Test that it does not wait for the completion **cascade** to
      finish and does not delay it
- [x] 4.4 Test through the real widget that finishing a puzzle and returning to
      the picker offers a different puzzle — the `nextUnsolved` break named in
      the proposal, proven closed from the UI rather than the repository
- [x] 4.5 Test that a kill immediately after completion leaves the full record on
      relaunch, and the player's **rank** with it (constraint 9)

## 5. The mark on the rank picker

- [x] 5.1 A **rank** above the player's is marked on `rank_picker_screen.dart`,
      in words as well as whatever visual treatment it carries (constraint 5).
      The screen is scaffolding `add-season-map` deletes — the rule stays in the
      capability, only the presentation is here
- [x] 5.2 Test that a marked **rank** opens with no confirmation, no warning, and
      no extra step, and that nothing on the screen is disabled (constraint 1)
- [x] 5.3 Test that solving above one's **rank** clears the mark from that
      **rank** and every **rank** below it
- [x] 5.4 Test that the six rows still paint on the first frame, with marks
      applied after the player's **rank** is read — the existing first-frame test
      must still pass, not be relaxed
- [x] 5.5 Golden test of the picker in three states: a new player, a mid-ladder
      player, and a player at Legend with nothing marked

## Platform checks

- [x] Verified on iOS — `integration_test/rank_progression_test.dart` on the
      iPhone 17 simulator: the **solve record** written and read back through the
      platform's own SQLite, the **rank** risen, the ratchet holding against an
      easier solve, the record surviving a close-and-reopen of a real database
      file, and the mark cleared from the earned **rank** and every one below.
      `grade()` 42 µs, the record's transaction 5.6 ms
- [x] Verified on Android — the same four on the API 37 emulator: `grade()`
      1.1 ms, the record's transaction 41 ms, both well clear of a frame and
      neither on the input path. **The "database from the previous build" check
      was made as a host test, not on the emulator** — no schema change comes
      with this change, and the real upgrade case is that every existing install
      has an empty `solvedPuzzles` table, because nothing ever called
      `markSolved`; that is covered in `progression_repository_test.dart`, which
      asserts it reads as Greenhorn rather than as an error
- [x] Accessibility: the mark is announced in words and is not carried by colour
      alone (constraint 5) — one string serves the label and the screen reader,
      so they cannot drift; the picker rows hold their labels at 1× through 5×
      on a 320×568 phone with no overflow and no truncation, asserted on the
      render object rather than on the widget being present (D-84, D-93); and no
      new motion — after the picker settles, no further frame is scheduled, so
      there is nothing for **reduce effects** to silence. **Haptics are not
      covered**: nothing in this change fires one, which is asserted only by
      there being no haptic call in it
