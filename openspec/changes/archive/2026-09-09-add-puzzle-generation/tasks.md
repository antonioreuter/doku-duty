# Tasks — add-puzzle-generation

Generation and grading are on the test-first list in `openspec/config.yaml` under
`rules.tasks`. Every group below writes its failing test first, and the reason is
specific: a generator bug does not crash, it ships. A puzzle with two solutions
or a wrong **rank** reaches a player as "this game is broken" months after the
commit that did it, and the committed pack means the bad content outlives the
bug.

Pure Dart for the generator and the pack format — the same no-Flutter-import
rule `add-puzzle-engine` asserts, so the tool can run outside a device.

## 1. The pack format

- [x] 1.1 Write the failing test: a **pack** round-trips through its file form —
      id, version, and every puzzle with its clues, solution, **rank**, and seed
      (D-32). Nothing derived on read that was not written.
- [x] 1.2 Implement the format. One reader and one writer in one file; seasons
      arrive on a six-week cadence (D-18) and a second reader would be a second
      answer to what a **pack** is.
- [x] 1.3 Test that a malformed **pack** — bad JSON, a missing field, a grid that
      is not 81 characters, a **rank** name that is not one of the six — is
      rejected as a value carrying what was wrong, never as an exception. The
      engine's `GridParseResult` already sets this shape.
- [x] 1.4 Test that an unknown extra field is tolerated rather than rejected, so
      a later pack format can add one without stranding an installed app on a
      file it refuses to read.
- [x] 1.5 Test: no file in the pack format or the generator imports Flutter.

## 2. Generating one puzzle

- [x] 2.1 Write the failing test: a seeded solved grid is a complete, valid grid,
      and the same seed gives the same grid every time.
- [x] 2.2 Implement seeded solved-grid generation.
- [x] 2.3 Write the failing test: digging clues out of a solved grid stops while
      the grid still has exactly one solution, checked by the engine's exhaustive
      search and not by the technique solver.
- [x] 2.4 Implement digging. Every intermediate grid is verified before it is
      accepted, so a non-unique grid is never carried forward.
- [x] 2.5 Test that a generated puzzle's stored solution is the one the
      uniqueness check returned, not the grid it was dug from — they are the same
      grid, and a test is what keeps them so.
- [x] 2.6 Test that generation is deterministic end to end: same seed, same
      puzzle, same clue positions.

## 3. Grading what came out, not what was asked for

- [x] 3.1 Write the failing test: a puzzle is stored with the **rank** the grader
      returned. A request for Marshal that grades Deputy is stored as Deputy or
      discarded, and never as Marshal (D-07).
- [x] 3.2 Write the failing test: a candidate the grader calls ungradable is
      discarded, not filed under Legend. This is constraint 8 at the only point
      where breaking it reaches a player.
- [x] 3.3 Implement rank-targeted generation as *generate, grade, keep or
      discard* — never as a parameter that decides the answer.
- [x] 3.4 Test the loop terminates: asking for a **rank** that is slow to hit
      gives up after a bounded effort and reports how many it found, rather than
      running for ever with nothing to show.
- [x] 3.5 Write the failing test and implement the clue ceiling: nothing over
      forty clues is ever selected for a **pack**. A dig passes through every
      clue count, so without this the pack fills with grids one full house from
      solved that grade Greenhorn honestly and are no kind of puzzle. Added
      after measurement showed Greenhorn spanning 26 to 80 clues; the ceiling is
      a selection rule, not a change to what a seed names.

## 4. The shipped pack

- [x] 4.1 Write `tool/generate_pack.dart`: takes a seed and a per-**rank** count,
      writes the pack file, prints what it produced and what it discarded.
- [x] 4.2 Generate the first pack with a recorded seed. Target split, weighted to
      where players spend time rather than spread evenly: Greenhorn 70, Deputy
      70, Sheriff 60, Marshal 50, Ranger 35, Legend 20 — 305 puzzles.
- [x] 4.3 Commit the pack as a bundled asset and declare it in `pubspec.yaml`
      alongside the fonts. Record the seed and the tool invocation beside it, so
      the file can be re-derived rather than trusted.
- [x] 4.4 Record the generation time for the pack, and for the Legend puzzles
      specifically. It is the number the next season's pack is planned against.

## 5. Auditing the committed pack

These run against the file that actually ships. Group 2 tests the generator;
this tests the artefact, and they are not the same claim.

- [x] 5.1 Test that every puzzle in the shipped **pack** has exactly one solution
      by the exhaustive check, and that the stored solution is that solution.
- [x] 5.2 Test that every puzzle's stored **rank** is what the grader returns for
      it now — the check that catches a pack generated against an older engine.
- [x] 5.3 Test that all six **rank**s are present and the counts match 4.2.
- [x] 5.4 Test that no two puzzles in the **pack** share a clue grid, so a player
      is never handed the same puzzle twice under two ids.
- [x] 5.5 Test that every puzzle id is unique and stable, so a re-generated pack
      does not silently re-key a puzzle the player has already solved.
- [x] 5.6 Test that no puzzle in the shipped **pack** carries more than forty
      clues, at any **rank**.

## 6. Installing it

- [x] 6.1 Test that the bundled **pack** installs on first launch and its puzzles
      are readable through `PackRepository`.
- [x] 6.2 Test that the install does not hold the first frame.
- [x] 6.3 Test that a second launch reinstalls nothing and forgets no solved
      puzzle — the immutable-version rule `add-persistence-layer` already
      enforces, exercised through this **pack**.
- [x] 6.4 Test an interrupted install: a **pack** partly written is not recorded
      as installed, and the next launch completes it.
- [x] 6.5 Test the fresh-install-offline case: with no network at all, puzzles
      are available. This change adds no network, and the test is what keeps it
      that way.

## 7. Running out is not a wall

- [x] 7.1 Test that solving every puzzle at a **rank** reports nothing left at
      that **rank** as an ordinary absence — no error, no lock, no failure state
      (constraint 1).
- [x] 7.2 Test that the other five **rank**s are unaffected when one is
      exhausted.

## 8. Close out

- [x] 8.1 Confirm the glossary row for **pack** in `openspec/project.md`, added
      with this change's proposal, still describes what was built.
- [x] 8.2 `flutter analyze` clean and `dart format --set-exit-if-changed`
      passing.
- [x] 8.3 Check the shipped asset's size against the bundle, and record it beside
      the generation time in 4.4.

## Platform checks

- [x] Verified on iOS: an `integration_test` loads the bundled **pack** on a
      simulator and asserts the puzzle count. A bundled asset missing from the
      IPA is invisible to every host test, because the host reads the file from
      disk — the same shape of defect as D-77
- [x] Verified on Android: the same test on an emulator, asserting the same count
- [x] Accessibility: this change renders nothing — no contrast, dynamic type,
      motion, or colour cue to check. Recorded rather than silently skipped
