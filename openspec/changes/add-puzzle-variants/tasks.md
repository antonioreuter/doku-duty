# Tasks — add-puzzle-variants

**On test-first.** The puzzle engine (generation and grading included), all
notes logic, and rank progression are on the canonical list in
`openspec/config.yaml`, and this change touches all three. Every group below
that changes one of them writes its failing test first.

**On order.** A **cage** is invisible to the player until group 9, so the app
stays runnable and classic play stays byte-identical after every task until
then. Group 2 comes first because it is the one finding that can send the design
back to the developer.

## 1. Vocabulary and decisions

- [x] 1.1 Add **killer**, **cage**, and **cage sum** to the glossary in
      `openspec/project.md`. Amend **peer** to say a **killer** board adds
      **cage** mates, and **unit** to say a **cage** is not one. Nothing below
      is written before the words exist.
- [x] 1.2 Append **D-127** to `docs/DECISIONS.md`: **killer** is the v1 variant,
      compiled in for every **season**, reachable only from a **variant node**.
      Record why the **season** document gets no rule key yet, and cite D-34 and
      D-35.
- [x] 1.3 Append **D-128**: **killer** is graded on the same ladder. It adds
      cage combination at Greenhorn and the 45 rule at Sheriff, each with a
      **lesson**, and a **killer** solve counts toward **rank** and **technique
      unlock**s. Record why a separate ladder was rejected.
- [x] 1.4 Append **D-129**: how a **cage** is drawn. A dashed `duskInk` outline
      as a fifth stroke token, the sum at 8px in `inkSoft` top-left of the
      first cell, and every note grid on a **killer** board inset below the sum
      band. Record why the inset is board-wide rather than per-cell
      (constraint 3). Record the 2.1 measurements, and that notes on killer
      boards fall below D-74's 11px as a deliberate amendment of D-74 for
      killer boards only. Add a note to D-74 pointing at D-129.
- [x] 1.5 Append **D-130**: a **cage** is not a **unit**. **Cage** mates are
      **peer**s, and filling a **cage** fires no completion effect.
- [x] 1.6 Update `openspec/BACKLOG.md` item 17's capabilities to the seven in
      the proposal, and add the **cage** stroke and the sum label to
      `docs/DESIGN.md` §2 and §3.

## 2. Will the notes fit? *(stop point)*

- [x] 2.1 Before any engine work, measure on paper and in a throwaway golden: on
      a 320×568 screen at 1x (D-84), with the grid at its real size, the cell
      width, the sum band height at grid-note size, and the note size left
      below it. **If a note falls below 11px (D-74), stop and bring it back to
      the developer**, with the numbers and the options (smaller band, sum
      outside the cell, or accepting a smaller note on **killer** boards only).
      Record the numbers in D-129 either way.

## 3. The cage model *(test-first)*

- [ ] 3.1 Write the failing tests for a **cage** set: every cell in exactly one
      **cage**, every **cage** orthogonally connected, **cage sum**s between the
      least and greatest possible for their size, and refusal of each violation.
- [ ] 3.2 Implement the **cage** model in `puzzle_engine/domain/`, pure Dart,
      and extend the domain's `no_flutter_import_test.dart`.
- [ ] 3.3 Write the failing tests for per-puzzle peers. A classic puzzle's peers
      are exactly `GridGeometry.peersOf`, for all 81 cells. A **killer**
      puzzle's are those plus **cage** mates, each listed once. Candidates never
      exclude a digit by arithmetic.
- [ ] 3.4 Move peer lookup from the static `GridGeometry` table to a per-puzzle
      source that falls back to the table when there are no **cage**s. Every
      existing caller keeps its behaviour. The full suite must be green here
      with no classic test edited.

## 4. Uniqueness *(test-first)*

- [ ] 4.1 Write the failing tests: a **killer** grid unique only through its
      sums, the same grid with one **cage sum** changed reported as ambiguous or
      unsolvable, and a classic grid answering exactly as before.
- [ ] 4.2 Extend the exhaustive search to prune on **cage** repeats and partial
      sums. It stays independent of the technique solver (D-08).
- [ ] 4.3 Re-run `test/features/puzzle_engine/timing_test.dart` on a
      zero-given **killer** grid and record the time. It is offline only, but
      the generator will call it thousands of times.

## 5. The two killer techniques and the grader *(test-first)*

- [ ] 5.1 Write the failing tests for cage combination: a two-cell **cage** of
      3 restricts to {1,2}, a three-cell **cage** of 24 to {7,8,9}, a **cage**
      with a placed value narrows the rest, and nothing is deduced on a classic
      grid.
- [ ] 5.2 Implement cage combination at `Rank.greenhorn`.
- [ ] 5.3 Write the failing tests for the 45 rule: a single innie and a single
      outie of a block, row, or column are placed from the **cage** sums around
      them. Again, nothing is deduced on a classic grid.
- [ ] 5.4 Implement the 45 rule at `Rank.sheriff`.
- [ ] 5.5 Write the failing grader tests: a **killer** puzzle's **rank** is its
      hardest technique across both sets, one finishable only by cage
      combination grades Greenhorn, and one no technique finishes is
      ungradable.
- [ ] 5.6 Make the grader and solver **cage**-aware. Add the two values to
      `Technique`, and confirm `TechniqueStats`' text enum takes them without a
      migration.

## 6. Generation and the pack *(test-first)*

- [ ] 6.1 Write the failing tests for **killer** generation: seeded and
      reproducible, every output unique under its **cage**s, and graded by the
      grader rather than by a parameter (the shipped-pack rule).
- [ ] 6.2 Implement the **killer** generator: a solved grid, a **cage**
      partition, then clue removal down to the fewest givens that still grade
      at the target **rank**. Givens are allowed; D-82's forty-clue ceiling
      still applies.
- [ ] 6.3 Extend the **pack** format with an optional `cages` field and bump the
      **pack** to version 2. Rewrite `pack_test.dart`'s "an unknown `variant`
      field is ignored" case, which was written to hand over, into one that
      reads and round-trips `cages`.
- [ ] 6.4 Generate killer puzzles into `assets/packs/frontier-1.json` at all six
      **rank**s. Aim for at least 12 per **rank** and record the actual split
      in `assets/packs/README.md`. Classic puzzles must be byte-identical to v1.
- [ ] 6.5 Extend `shipped_pack_test.dart`: every **killer** puzzle is unique and
      re-grades to its shipped **rank**, and every **rank** has at least one.

## 7. Storage

- [ ] 7.1 Add a nullable `cages` column to `Puzzles`, moving schema v7 → v8, and
      export `drift_schema_v8.json`. Extend `migration_test.dart` with v7 → v8,
      which must prove an in-progress classic save survives and stays classic.
- [ ] 7.2 Carry `cages` through `StoredPuzzle`, `PackInstaller`, and
      `PackRepository.installPack`.
- [ ] 7.3 Write the failing tests, then give `nextUnsolved` a kind. Free play
      asks for classic, and a **variant node** asks for **killer**.
      `puzzleByRankAndSeed` returns classic only, so the daily's derived board
      can never be **killer**.
- [ ] 7.4 Refuse a published daily schedule entry that names a **killer**
      puzzle, the same way as one naming an unknown puzzle, with a test.

## 8. Variant nodes resolve killer

- [ ] 8.1 `add-season-map` left
      `test/features/season_map/node_types_test.dart`'s "plays a classic puzzle
      — change 17 owns the rule". **Delete it** and replace it with a test that
      a **variant node** opens a **killer** board, as 16 did with the boss
      seam.
- [ ] 8.2 Resolve a **variant node** to a **killer** puzzle in
      `nodePuzzleProvider`, and test that exhaustion reports an absence rather
      than substituting classic.
- [ ] 8.3 Update `offline_first_run_test.dart` and `trail_screen_test.dart`
      where they assume a **variant node** opens a classic grid.

## 9. Notes and the board *(test-first)*

- [ ] 9.1 Write the failing **auto-cleanup** test: a placement removes the digit
      from a **cage** mate outside its row, column, and block, in both inks, and
      undo restores ink and slot.
- [ ] 9.2 Write the failing **auto-notes** tests: a **cage** mate's value is
      excluded, and a sum-impossible digit is still added.
- [ ] 9.3 Route `board.dart`'s **auto-cleanup**, **auto-notes**, and
      duplicate/conflict checks through the per-puzzle peers from 3.4.
- [ ] 9.4 Confirm the mistake model and the solved check still compare against
      the stored solution and need no change, with one **killer** test each.

## 10. Drawing the cage

- [ ] 10.1 Add the **cage** stroke to `DokuStroke`, and a dashed-path helper
      with its own unit test.
- [ ] 10.2 Draw the **cage** outlines in `grid_painter.dart`, built once per
      puzzle and cached rather than per frame. Add the **cage sum** label and
      the board-wide note inset measured in 2.1. The inset must apply to every
      cell and never to a classic board.
- [ ] 10.3 Mark **cage** mates with the selection highlight.
- [ ] 10.4 Announce the **cage sum** and **cage** size in each cell's semantics
      label.
- [ ] 10.5 Goldens: every existing grid and note golden unchanged, plus new
      **killer** goldens for an empty board, a board with notes in every head
      cell, and a solved board.
- [ ] 10.6 Re-run `latency_test.dart` — per-tap median and maximum note density
      — on a **killer** fixture, and record both numbers against the classic
      ones.

## 11. Completion and progression *(test-first)*

- [ ] 11.1 Write the failing test: filling a **cage** with no row, column, or
      block completing fires no effect and no haptic, and a row on a **killer**
      board still completes.
- [ ] 11.2 Write the failing rank-progression tests: a **killer** solve above
      the player's **rank** raises it, and one needing the 45 rule increments
      its counter and unlocks it.
- [ ] 11.3 Make `_techniquesFor` in `grid_providers.dart` grade with the
      puzzle's **cage**s. The classic grader returns `Ungradable` on a
      **killer** grid, which today would silently skip every counter and every
      **lesson**.

## 12. Lessons

- [ ] 12.1 Author the cage combination and 45 rule **lesson**s. Find their
      board positions with `tool/find_lesson_positions.dart`, extended for
      **cage**s.
- [ ] 12.2 Extend the catalogue test with the two killer **lesson**s and the
      rule that they exist although cage combination is Greenhorn. Check that
      the **cabinet**'s replay list shows both.

## 13. Publishing

- [ ] 13.1 Add one paragraph to `lib/features/remote_config/PUBLISHING.md`:
      every **variant node** plays **killer**, there is no rule key, and a
      daily entry naming a **killer** puzzle is refused.

## Platform checks

- [ ] Verified on iOS — a **variant node** opened on a simulator shows
      **cage**s, sums and inset notes, inside the safe area.
- [ ] Verified on Android — the same. Extend `integration_test/` with a
      **killer** runner that opens a **variant node**, places a value into a
      **cage**, and checks that **auto-cleanup** reached a **cage** mate.
- [ ] Accessibility: a **killer** board at text scales 1x–5x on a 320×568
      screen with no sum clipped. Every **cage** is identifiable with colour
      removed, and the screen reader announces each cell's **cage sum**.
