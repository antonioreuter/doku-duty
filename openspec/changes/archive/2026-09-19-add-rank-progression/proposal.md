# add-rank-progression

## Why

The engine has known what a **rank** is since change 5 — `Rank`, and
`Technique.introducedAt` carrying D-57's ladder — but the *player* has no rank.
Nothing records that a puzzle was finished, either. Neither
`StatisticsRepository.recordSolve` nor `PackRepository.markSolved` has a
production caller — both are exercised only by their own tests — so completing a
puzzle in the real app writes nothing at all. That already breaks a shipped
requirement: `grid-input` says choosing a **rank** opens "a puzzle of that
**rank** that they have not solved", and since nothing is ever marked solved,
`nextUnsolved` hands back the same puzzle forever. Milestone 2 opens here, and
changes 13, 15, and 16 all depend on a solve being recorded and a **rank**
existing.

## What changes

- A **rank** for the player: the hardest **rank** they have completed a puzzle
  at. It rises the moment a solve is recorded and never falls (D-102).
- Completing a puzzle records a solve — the puzzle marked solved, lifetime
  counters, the per-technique counters, and whether the **attempt** was perfect.
  One durable write, wiring two repositories that have sat unused since change 3
  and closing the `nextUnsolved` break above.
- The techniques a solve required come from the grader's `techniquesUsed`, not
  from the puzzle's stored **rank**. A **rank** is the hardest technique a puzzle
  *may* need; the statistics want what it actually needed.
- **Rank**s above the player's are marked on the **rank** picker and stay fully
  openable — a label, never a lock (D-103).
- A technique reads as unlocked once a solved puzzle has required it, which is
  its counter standing above zero (D-104). No second source of truth to drift.
- Three new decisions and one glossary term, **technique unlock**.

## Constraints

**Capabilities:** `rank-progression`

**1 — Non-punitive.** The soft mark is the whole reason this change is not a
lockout. A player at Greenhorn can open a Legend puzzle and, on solving it,
becomes Legend. Rank never falls, expires, or is spent, and no rank is ever
withheld. This is the constraint that decided D-103, and a later change turning
the mark into a gate would need to reopen it.

**9 — Write on change.** A solve is durable at the moment it happens, in the
transaction `recordSolve` already opens, not on a timer and not at app exit. A
rank earned and lost to a crash is the failure this constraint exists to prevent.

**2 — Latency.** Grading is a solver run, so it must never sit on the input path.
It happens once per puzzle, off the tap path, and its cost is measured rather
than assumed.

## Technical notes

**Grid performance:** the only new work on a puzzle is one `grade()` call to
recover `techniquesUsed`, and the plan is to make it once when the puzzle is
opened — not per placement, and not on the frame that completes the board, where
it would land inside the completion **cascade**. Nothing is added to the painter
or to a tap. The open path is already asynchronous and off the first frame.

An alternative was to store the technique set in the **pack** alongside the
**rank**. Rejected for now: the shipped pack's format would change and every
pack would need regenerating, to save a computation the engine does cheaply from
data already loaded. `pack.dart` is deliberate that the *stored* grade is the one
that was checked, so the stored **rank** stays what the player is told; the
re-derived set is only ever used for counting.

**Offline, cold start, app kill:** all of it is local — Drift rows and a pure
comparison. Nothing here touches the network. The player's **rank** is derived
from what has been recorded rather than stored as a separate fact that could
disagree with the counters, so an app kill between the two cannot happen. First
frame is untouched: the **rank** picker paints its six rows before reading
anything, and that test already exists.

**New dependency:** none.

## Not doing

- **The cabinet.** Displaying lifetime statistics, trophies, or a technique list
  is `add-trophy-cabinet` (change 16). This change writes the numbers and exposes
  them; it draws no cabinet.
- **Tutorials.** Firing a lesson when a technique unlocks is
  `add-technique-tutorials` (change 13). D-104 defines the unlock so 13 has
  something to key off, and stops there.
- **The season map awarding rank.** `add-season-map` (change 15) may add its own
  routes to progression; this change does not anticipate them.
- **Rank-aware generation or pack top-up.** Which puzzles a player is served next
  is the map's business, not this change's.
- **Cloud sync.** **Rank** and statistics carry the sync metadata change 3
  already gave them, and `add-cloud-sync` (change 29) is where they move.
- **Redrawing the rank picker.** It is scaffolding `add-season-map` deletes; the
  mark goes on it because that is where a player stands today. The rule that
  decides which **rank**s are above the player's lives in the capability and
  survives the screen.
- **Character reaction on promotion.** The Sheriff's grudging approval on a
  technique unlock is in the reaction table (D-58, `docs/SPEC.md` §6) and belongs
  to `add-character-system` (change 20). This change fires no character.
