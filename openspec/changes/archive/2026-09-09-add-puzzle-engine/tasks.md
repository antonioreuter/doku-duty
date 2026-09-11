# Tasks — add-puzzle-engine

The puzzle engine, including grading, is on the test-first list in
`openspec/config.yaml` under `rules.tasks`. Every technique below gets its
failing test before its implementation, and the reason is specific rather than
ceremonial: a technique that is subtly too eager makes puzzles grade *easier*
than they are, and the symptom is a player finding a Ranger puzzle trivial,
which nobody reports as a bug.

Pure Dart throughout. No Flutter import in `lib/features/puzzle_engine/`, and a
test asserts it.

## 1. The model

- [x] 1.1 Write the failing test: a cell belongs to exactly three **units**, and
      each **unit** holds nine cells including it.
- [x] 1.2 Write the failing test: a cell has exactly twenty peers, each listed
      once — the classic off-by-one here is counting the cell itself or
      double-counting the block overlap.
- [x] 1.3 Implement the grid, its units, and peer lookup. Precompute the unit and
      peer tables once rather than deriving them per query; they are the same
      for every puzzle ever played.
- [x] 1.4 Implement candidates as a nine-bit mask per cell, and test that
      eliminating a digit leaves the others untouched.
- [x] 1.5 Test parsing and rendering an 81-character grid, round-tripping the
      format `add-persistence-layer` already stores.
- [x] 1.6 Test that a malformed grid — wrong length, a stray character — is
      rejected as a value, not an exception.
- [x] 1.7 Test: no file under `lib/features/puzzle_engine/` imports Flutter.

## 2. Uniqueness, before any technique

- [x] 2.1 Write the failing test: a known-unique puzzle reports exactly one
      solution.
- [x] 2.2 Write the failing test: a grid with two solutions reports ambiguous,
      and one with contradictory clues reports unsolvable. Three distinct
      answers, not a boolean.
- [x] 2.3 Implement exhaustive search. It must stop as soon as a second solution
      is found rather than enumerating them all.
- [x] 2.4 Test the empty grid: it is ambiguous, not unsolvable, and the check
      returns rather than running for ever.
- [x] 2.5 Test that uniqueness does not consult the technique solver — a puzzle
      no technique can finish still reports one solution if it has one. This is
      constraint 8, and conflating the two questions is the way it breaks.

## 3. The techniques, one at a time

Each: failing test first, naming a grid where the technique is the only thing
that applies; then the implementation; then a test that it makes **no** deduction
on a grid where it does not apply. The second half matters more than the first —
an over-eager technique is what silently lowers a grade.

- [x] 3.1 Full house.
- [x] 3.2 Naked single.
- [x] 3.3 Hidden single.
- [x] 3.4 Naked pair.
- [x] 3.5 Pointing pair.
- [x] 3.6 Box-line reduction.
- [x] 3.7 Naked triple.
- [x] 3.8 Hidden pair.
- [x] 3.9 X-wing.
- [x] 3.10 Swordfish.
- [x] 3.11 XY-wing.
- [x] 3.12 Simple chains.
- [x] 3.13 Test that every technique named in D-57 is implemented and that
      nothing outside that table is. Read the list from `Technique`, not from
      memory — this is the test that fails when the ladder and the solver drift
      apart.

## 4. The solver

- [x] 4.1 Implement single-step solving: return one deduction with its technique,
      the cells affected, and what changed.
- [x] 4.2 Test: the easiest applicable technique wins. A grid where both a hidden
      single and an X-wing apply must report the hidden single, or every puzzle
      grades too hard.
- [x] 4.3 Test: a grid where nothing applies returns a plain "no progress" and
      the grid unchanged.
- [x] 4.4 Test: a completed grid reports solved and invents no deduction.
- [x] 4.5 Implement solving to completion by repeated stepping, and test it
      against puzzles of each **rank**.
- [x] 4.6 Test that solving is deterministic — the same grid yields the same
      deductions in the same order every time. Grading depends on it, and so
      will a hint that must not change its mind between taps.

## 5. The grader

- [x] 5.1 Write the failing test: a puzzle solvable by singles alone grades
      Greenhorn.
- [x] 5.2 Write the failing test for each remaining **rank**, using the corpus
      from group 6.
- [x] 5.3 Implement grading as the hardest technique the solver actually needed.
- [x] 5.4 Test: clue count does not move a grade. Two puzzles needing the same
      hardest technique but with different clue counts get the same **rank**
      (D-07).
- [x] 5.5 Test: a puzzle no technique can solve is reported ungradable, not
      Legend. Filing the unsolvable under the top **rank** is the failure that
      would put a guess-and-check puzzle in front of a player, and constraint 8
      forbids it.
- [x] 5.6 Test the boundary directly: for each **rank**, a puzzle needing that
      rank's hardest technique grades there, and one needing the next technique
      up grades one higher. The ladder is only meaningful at its edges.

## 6. The corpus

- [x] 6.1 Assemble a hand-verified corpus: for each of the twelve techniques, at
      least one puzzle that provably requires it.
- [x] 6.2 Record beside each puzzle *why* it requires that technique — the cells,
      the digits, the deduction. A corpus without its reasoning is a set of
      magic numbers that nobody can re-verify when a test starts failing.
- [x] 6.3 Verify every corpus puzzle is unique by the group 2 check before using
      it to test grading. A non-unique puzzle would make the grader's answer
      meaningless.
- [x] 6.4 Test the corpus against itself: solving each entry with techniques
      restricted to its **rank** and below must succeed, and restricting to one
      technique lower must fail. This is what makes "provably requires" a
      property the suite checks rather than a claim in a comment.

## 7. Placement questions

- [x] 7.1 Implement and test conflict detection: a digit repeating in a **unit**
      is reported with the cells that conflict.
- [x] 7.2 Implement and test disagreement with the solution, distinctly from
      conflict — a digit can break no unit and still be wrong, and
      `add-mistake-model` needs to tell those apart.
- [x] 7.3 Implement and test grid completion.
- [x] 7.4 Test that a value overwriting a correct cell is reported for what it is
      and nothing more. D-05 says that is never a mistake, and the engine must
      not be the layer that decides otherwise.

## 8. Move the shared vocabulary

- [x] 8.1 Move `Rank` and `Technique` from `lib/features/persistence/domain/` to
      the puzzle engine. The files say this change owns them; persistence held
      them only because it was the first capability that had to name one.
- [x] 8.2 Update persistence to import them from their new home, and confirm the
      stored enum names are unchanged — they are written into the database as
      text, so a rename is a silent data migration.
- [x] 8.3 Test that the persisted names still round-trip, so moving the file
      cannot quietly invalidate every stored statistic.

## 9. Close out

- [x] 9.1 Add `add-puzzle-generation` to `openspec/BACKLOG.md` between changes 5
      and 6, covering the generator and the first real pack. Without it Milestone
      1 cannot be reached, and the gap should be tracked rather than remembered.
- [x] 9.2 `flutter analyze` clean and `dart format --set-exit-if-changed`
      passing.
- [x] 9.3 Record the solver's timing for a single step and for a full solve at
      Legend, so `add-perks` has a number to design a hint against rather than a
      hope.

## Platform checks

- [x] Both platforms: the engine is pure Dart and has no platform behaviour to
      differ. The check that matters is that it *stays* that way — task 1.7
      asserts no Flutter import, which is what would introduce one
- [x] Solver timing measured on an Android emulator and an iOS simulator, for a
      single step and a full Legend solve. Not a pass/fail gate here: nothing
      calls it on a frame path yet, and change 19 is where a hint has to answer
      while a player waits. Recorded so that change starts with a measurement
- [x] Accessibility: this change renders nothing, so there is no contrast,
      dynamic type, motion, or colour cue to check. Recorded rather than
      silently skipped
