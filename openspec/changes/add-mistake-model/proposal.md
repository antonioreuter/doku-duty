# add-mistake-model

## Why

Four places in the code defer to this capability by name — `Board`,
`PlacementReport`, `PuzzleController.isSolved`, and the settings screen, which
already shows strict mode greyed out as "arrives with mistakes". Nothing yet
knows whether a placement was wrong, so `StatisticsRepository.recordSolve` takes
`wasPerfect` as a bool no caller can compute, and the three Stamps for a
mistake-free solve have nothing behind them. The engine already produces every
fact needed: `inspectPlacement` returns `agreesWithSolution` and
`overwritesCorrectValue` and nothing reads them.

## What changes

- **A mistake is recorded silently.** A placement that disagrees with the
  solution is counted, and nothing on screen changes (D-04). Auto-check stays
  off — the grid still refuses to say which digit is wrong, because finding it
  is the game (D-04).
- **Counted per wrong placement**, so the same wrong digit placed twice counts
  twice. The tally is what the player did, not which cells ended up wrong.
- **Overwriting an already-correct cell never counts**, in either mode (D-05).
  That is a mis-tap, not a wrong answer.
- **Notes never count**, in either mode, whatever the solution says (D-14). No
  ink, no origin, no automation output is ever a mistake.
- **Strict mode is one opt-in switch** (D-04): errors flag the moment they are
  placed, and the third mistake ends the attempt. `AppSetting.autoCheck` is
  **retired** — it was the other half of a two-setting reading this change
  settles against, and a stored setting nothing reads is worse than none.
- **The third mistake locks the board** and offers the same puzzle from the
  start. Input stops, the attempt is recorded as failed, and the player chooses
  a fresh start or the map.
- **The count is part of the save**, written with the placement that caused it
  (D-33), so it survives an app kill and a reopen mid-puzzle.
- **`wasPerfect` is computed rather than supplied**, so `perfectSolves` finally
  counts something real.
- **Glossary:** **mistake** and **attempt** join `openspec/project.md`.

## Constraints

**Capabilities:** `mistake-model`

**Constraint 1** is the one this change exists under rather than near. The whole
capability is a counter that says nothing by default: no flag, no colour, no
limit, no failure. The single failure state in the product lives behind a switch
the player has to find and turn on, and the backlog's warning is the right one —
if auto-check ever ships on, the positioning is gone. The default is a release
blocker, not a preference, and it gets a test that fails on a fresh install if
either behaviour is on.

**Constraint 5.** A flagged cell in strict mode cannot rest on `sunsetRed`
alone. The error carries a second signal — the cell's own mark, not its hue —
so a player who cannot separate red from ink still reads it. The mistake count
itself is a number, which is a signal colour cannot carry away.

**Constraint 9.** A mistake is written with the placement that caused it, in the
same commit, never on a timer. A count that resets on an app kill would be a
silent undercount with no symptom, and in strict mode it would hand the player
back a lost attempt.

**Constraint 2.** The check is one character comparison against a solution
string the controller already holds, on the placement path. Strict mode adds one
fill per flagged cell to a painter that already paints fills.

**Constraint 3** and **constraint 4** are untouched: no note behaviour changes,
and `sunsetRed` is already one of the eight, reserved for exactly this.

## Technical notes

**Grid performance:** the per-placement check is `solution[cell]` against the
digit — cheaper than the `_solves` whole-board comparison already running on
every placement. Strict mode's flag is one more entry in the painter's existing
fill pass; no new glyph cache and no new layer.

**Offline, cold start, app kill:** entirely local. The solution ships in the
pack (D-32), so nothing here needs a network. The count is a column on the
existing save row, written in the transaction that writes the placement, so a
kill leaves the board and its tally agreeing. A save written before this change
has no count; it reopens at zero, which is the only honest answer — the
placements that made it were never inspected.

**New dependency:** none. The engine's `inspectPlacement`, the pack's solution,
the settings table, and `LifetimeStats.perfectSolves` all exist.

## Not doing

- **Ace reacting to any of it.** The first and third mistake both have entries
  in the reaction table, and the cast arrives in change 20.
- **Telling the player which cell is wrong when strict mode is off.** That is
  the hint engine and `add-perks` (change 19), and it is the one thing D-04
  exists to prevent.
- **The cabinet's per-technique breakdown.** This change writes the numbers;
  displaying them is `add-cabinet`.
- **A mistake affecting rank progression, streaks, or a season node's state.**
  Change 12 onward decides what a failed attempt means to the map.
- **Any timer behaviour.** The timer is display-only and fails nothing (D-06).
- **Backfilling mistake counts** for puzzles already in progress or already
  solved.
- **A second chance, a revive, or watching an ad to undo the third mistake.**
  A strict-mode attempt that ends is over; monetising the failure state of an
  opt-in mode is a worse idea than the mode.
