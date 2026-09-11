# add-puzzle-generation

## Why

`add-puzzle-engine` can verify and grade a puzzle but cannot produce one, so the
app ships with no content: change 6 can render a grid and change 7 can mark
notes, and neither has anything behind it. Milestone 1 — "a player can solve a
puzzle at any of six **rank**s" — is unreachable until something fills the
`puzzles` table the persistence layer has been waiting to hold since change 3.

## What changes

- **A generator**, run offline by a developer, not on the device (D-32,
  `docs/TECH_STACK.md` §4). It proposes a grid, keeps removing clues while the
  engine's exhaustive check still reports one solution, and asks the grader what
  it made. All three steps already exist.
- **The first shipped pack**: about 300 puzzles, weighted toward the easier
  **rank**s where players actually spend time rather than spread evenly across
  six. It is a committed file, so every build ships byte-identical puzzles and
  the content is reviewable in a diff.
- **A pack file format** and the code that reads it — one place that decides
  what a pack is on disk, since seasons arrive on a six-week cadence (D-18) and
  a second reader would be a second answer.
- **Install on first launch**, off the first frame, idempotent, and versioned by
  the rule `add-persistence-layer` already enforces: a pack version is immutable
  and never installs backwards.
- **A graded rank is the grader's answer, never a generator parameter.** The
  generator asks for puzzles at a **rank**; what lands on the row is what the
  grader said about the puzzle that came out.

## Constraints

**Capabilities:** `puzzle-engine`

**Constraint 8 (one solution, solvable by logic alone)** is where this change
either delivers or breaks the product. `add-puzzle-engine` made the property
*checkable*; this is the change that puts puzzles in front of a player, so every
one of them is verified by the exhaustive uniqueness search at generation time
**and** re-verified by a test over the committed pack. A puzzle that reaches the
pack ungraded, or graded by anything other than the solver, is the failure mode.

**Constraint 1 (non-punitive).** Running out of unsolved puzzles at a **rank** is
an ordinary condition, not a wall: `nextUnsolved` already answers null rather
than throwing, and nothing in this change turns exhaustion into a blocked player.
The pack is sized so it does not happen in a season, which is a comfort measure,
not the guarantee.

**Constraint 2 (latency).** Generation is offline and costs the device nothing.
The one thing on a frame path is the first-launch install of ~300 rows, which
must not delay the first frame — the same discipline `add-remote-config` follows.

**Constraints 3, 4, 5, 6, 7, 9, 10** are untouched: no notes, no colour, no ads,
no note writes, no currency.

## Technical notes

**Grid performance:** Nothing renders. The only cost that reaches a frame is the
first-launch install, which is a single batch insert of bulk content — the one
place `add-persistence-layer` already says deferring a write costs nothing,
because no player action is waiting on it.

**Offline, cold start, app kill:** The pack is a bundled asset, so there is no
network in this change at all and a fresh install in airplane mode has full
content. A kill during the install leaves the pack partly written; the install is
idempotent and re-runs, and the version row is written in the same transaction so
a half-installed pack is never recorded as installed.

**New dependency:** None. The generator is a Dart tool under `tool/` that imports
the engine, so the code that grades the shipped pack is the same code the app
trusts at runtime — a generator in another language would have to reimplement the
solver and would then be grading with something the app has never run. Reading
the pack needs `dart:convert` and Flutter's asset bundle, both already present.

**Device verification.** A bundled asset that is missing from the APK or the IPA
is invisible to every host test, because the host reads the file from disk — the
same shape of defect as D-77. An `integration_test` loads the pack on an Android
emulator and an iOS simulator and asserts the puzzle count, on both platforms.

## Not doing

- **No server top-up and no pack downloading.** D-32 promises it, and it needs a
  bucket that does not exist. Deferred whole rather than half-built, following
  the precedent `add-remote-config` set for the transport it could not yet reach.
- **No second pack and no season rotation.** One pack. Seasons are change 15.
- **No daily challenge.** Change 14 picks the puzzle; this only makes puzzles
  exist.
- **No variants.** Killer and the rest are change 17. Classic sudoku only, and
  nothing is generalised in advance for rules that have not been designed.
- **No difficulty tuning beyond the ladder.** No clue-count targets, no timing
  data, no adaptive difficulty (`docs/TECH_STACK.md` §4 rejects the last
  outright). The **rank** is the hardest technique required and nothing else
  (D-07).
- **No puzzle selection UI.** What the player is offered at a node is change 15.
- **No symmetry requirement.** Pretty clue patterns are a cosmetic property that
  costs generation time and buys nothing a player has asked for. If it is wanted
  later it is a filter on the same generator.
