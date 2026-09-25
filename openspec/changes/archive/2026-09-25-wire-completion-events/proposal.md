# wire-completion-events

## Why

In the running app, a solved **daily challenge** never reaches the **calendar**,
so the **streak** never grows. **Rank** **trophy**s and perfect-month
**trophy**s never mint. Changes 14 and 16 built `DailyService.complete`,
`MintingService.afterDailyCompleted` and `MintingService.afterRankReached`, but
tested them in isolation, and only tests call them. The daily screen opens its
board as an ordinary puzzle, and `RepositoryBoardSink.complete` has no daily or
**rank** hook. `add-stamps` (18) pays two of its five **earning** events from
this wiring, so this change must land first.

A corrective change, like `add-pad-tools-row`: it carries no backlog number.

## What changes

- **Solving the daily board records the day.** The date written to the
  **calendar** is the one the board was opened for, not the date at the moment
  of solving. A daily opened at 23:58 and solved at 00:02 credits the day it
  was opened. **New decision, D-132.**
- **Only a board opened as the daily records a day.** The same puzzle reached
  from the **trail** or **free play** records no day, just as a daily board
  completes no **node** (D-111).
- **The day and its perfect-month trophy commit with the solve record**, in one
  transaction (D-124, constraint 9). An app kill leaves all three or none.
- **Every solve mints the rank trophies the player now holds**, in the solve's
  transaction. This covers every board: **trail**, **free play**, and the daily.
  A player who reached a **rank** before this fix gets its **trophy** on their
  next solve, dated then. That is minting at the next earning event, not
  back-pay, and no earlier date exists to recover.
- **Screens read fresh after a solve.** The daily card, the **calendar** and the
  **cabinet** re-read after a completion, as the **trail** and **free play**
  already do (D-105).
- Docs: `openspec/BACKLOG.md` (items 14 and 16, and the list of unnumbered
  changes) and `CLAUDE.md` record that the wiring was missing and that this
  change fixed it. add-stamps' planned decisions have been renumbered to D-133
  and D-134 to make room for D-132.

## Constraints

**Capabilities:** `daily-challenge`, `trophy-cabinet`

**Constraint 9 (written on every change):** this change exists to meet it. Each
day and each **trophy** is written in the transaction of the solve that earned
it. Nothing is deferred to a timer, and nothing is written after a celebration.

**Constraint 1 (non-punitive):** D-132 always resolves the edge case in the
player's favour. A daily that is solved never goes uncredited because of the
moment it was solved.

**Constraint 6 (latency):** completion is already off the tap path. This change
adds one indexed upsert and a handful of idempotent **trophy** inserts to a
transaction that already exists.

## Technical notes

**Offline, cold start, app kill:** fully local, like the **trail**'s completion.
Where a board was opened from is held in memory, as `activeNodeProvider` holds
it today, and an app kill clears it. That is safe because the app has no other
route back to a board: a daily resumed after a kill is reopened from the daily
card, which sets its origin again. The three origins (**node**, daily, and
**free play**) become one value, not two flags. Opening a board from any of
them replaces the previous origin, so a stale daily marker cannot credit a
later solve in **free play**.

**Grid performance:** no change on the frame path.

**New dependency:** none.

## Not doing

- **Stamps**, and the streak-milestone **earning**. That is `add-stamps`.
- **A daily celebration or any new screen.** The existing completion effects
  are unchanged.
- **Back-dating** a **rank** **trophy** to the day the **rank** was first
  reached.
- **Clock reconciliation.** `ClockTrust` and the verified flag are unchanged.
  The day records the verified flag the clock gave when the board was opened.
