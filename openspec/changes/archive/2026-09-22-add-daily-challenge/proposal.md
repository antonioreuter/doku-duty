# add-daily-challenge

## Why

The **daily challenge** is the third of D-17's three progression layers and the
only one not yet built — permanent and seasonal both ship. Without it there is
one reason to open the app, and it is a **season** that rotates out every six
weeks. It also unblocks `add-trophy-cabinet` (change 16), which waits on nothing
else, and it is the earn surface D-66 already prices.

## What changes

- One puzzle per day, the same board for every player, rolling over at midnight
  **local time**.
- Which board is a **published schedule** under `remote-config` naming a puzzle
  per date, with a long compiled-in run as fallback — the same shape as the
  **season** document, for the same reason.
- When a player outruns the schedule — offline for months, or a lapsed publish —
  today's board is derived deterministically from the installed **pack** by date
  seed. Sameness across players degrades; the **daily challenge** never stops
  being offered. **New decision, D-115.**
- The schedule's difficulty follows a **weekly ramp**: easier early in the week,
  hardest at the weekend, cycling. A publishing rule, so the shape is data.
  **New decision, D-116.**
- A month-grid **calendar** fills in as days are completed.
- A **streak** counts consecutive completed days, and is **recomputed from the
  calendar**, never stored as a number (`docs/TECH_STACK.md` §3b).
- A **streak freeze** regenerates every 7 days, at most one held, consumed
  automatically on the first missed day (D-20). **New decision, D-117.**
- The **daily challenge** carries no interstitial, ever (D-24) — recorded now,
  where `add-ads-integration` will read it, rather than left for change 24 to
  remember.
- Dates come from the stored server-time offset where one exists, and from the
  local clock offline, marked unverified and reconciled on reconnect
  (`docs/TECH_STACK.md` §3b, "Clock trust").
- Four glossary terms are added to `openspec/project.md`: **daily challenge**,
  **calendar**, **streak**, **streak freeze**.

## Constraints

**Capabilities:** `daily-challenge`

**Constraint 1 — non-punitive.** The load-bearing one here, because a streak is
the classic place a casual game turns a habit into an obligation. The **streak
freeze** applies itself; a freeze the player must remember is a trap, not a
safety net (D-20). Missing a day costs no **season** progress (D-20), no
**node** expires, and running out of schedule never withholds a puzzle. No timer
can fail the daily. A wrong clock never costs a **streak** — the reconciliation
exists to stop fabrication, not to catch travellers.

**Constraint 6 — no ad interrupts a grid, and none on the daily at all.** No ad
code ships here; the requirement is written so change 24 inherits it rather than
re-deciding it.

**Constraint 8 — one solution, solvable by logic.** Nothing is generated on
device (D-32). Every board the **daily challenge** offers comes from the
installed **pack**, already uniqueness-checked and graded, by both routes —
named by the schedule or derived by seed.

**Constraint 9 — written on every change, never on a timer.** A completed day
and the **calendar** are save state and inherit the rule. A day lost to an app
kill is a broken **streak**, which is the one failure this capability cannot
have.

**Full offline play.** The compiled-in schedule and the **pack** are both local,
so the **daily challenge** works on a fresh install in airplane mode and keeps
working indefinitely. Nothing blocks the first frame.

## Technical notes

**Grid performance:** Not affected. The **daily challenge** opens the existing
puzzle screen with an existing board; no new in-puzzle rendering.

**Offline, cold start, app kill:** Works fully offline by design, above. The
**calendar** lives in Drift and is written on completion. The schema moves v5 →
v6, so a migration and its test are part of this change — v5 shipped with
`add-season-map` and the migration test already covers v4 → v5.

**New dependency:** None. Drift, Riverpod, and the existing `remote-config`
transport cover all of it.

## A fix carried out of scope, deliberately

**`trail_golden_test.dart` baked the wall clock into two images.** The trail
header read `DateTime.now()` directly, so both goldens captured whatever "N days
left" said on the afternoon they were generated — and failed the next morning,
every morning, for the life of the **season**. It surfaced mid-implementation of
this change when the date rolled over, and it is `season-map`'s defect, not this
one's: `add-season-map` introduced it and `add-trail-path` inherited it, both
invisible because the images were generated the same day they were checked.

Regenerating would have been green for one day. Fixed instead: a `nowProvider`
in `platform_shell`, threaded into the header, pinned in the golden test, with
two regression tests in `trail_screen_test.dart` that fail if anyone reverts to
the wall clock. Recorded as **D-118**.

This widens the change across a capability boundary, which is why it is written
down here rather than folded in quietly. The alternative was leaving the suite
red for the rest of this change's implementation.

## Not doing

- **No leaderboards.** Explicitly out of v1 (`openspec/BACKLOG.md`), and
  `docs/TECH_STACK.md` says server-verified times are what they would need.
- **No Stamps minted.** D-66 prices a completed daily at 2 and a 7-day
  milestone at 10, but `add-stamps` (18) owns the one place a **stamp** is
  minted. This change fires the completion; nothing mints. A test names the seam.
- **No trophy for a full month.** `add-trophy-cabinet` (16) owns it; same seam
  treatment.
- **No extra freezes for subscribers** (D-27) and **no daily archive replay** —
  both are `add-purchases-and-entitlements` (26).
- **No bonus daily chest** — `add-rewarded-video` (25).
- **No cloud sync of the calendar.** The merge rule is already written
  (`docs/TECH_STACK.md` §3b: union the days, recompute the number) and
  `add-cloud-sync` (29) implements it. This change shapes the data so that rule
  is possible, and syncs nothing.
- **No push notification or reminder.** Nothing owns notifications yet, and a
  streak that nags is the failure mode constraint 1 exists to prevent.
