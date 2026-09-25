# add-stamps

## Why

D-66 prices five things a player earns **stamp**s for, and nothing pays them
yet. Change 15 opens a **chest node** that pays nothing, and a test names that
as a seam for this change. Change 19's perks need a balance to spend from, and
a player should see **stamp**s arrive before anything asks them to spend one.

**Depends on `wire-completion-events`, which lands first.** Today a solved
**daily challenge** never reaches the **calendar**, and the rank and
perfect-month trophy hooks are never called. Two of the five earning events
hang off that wiring, so this change builds on it rather than repairing it.

## What changes

- **Stamp**s are paid at D-66's values: 2 for a **daily challenge**, 3 for a
  puzzle solved with no **mistake**, 10 on every seventh day of a **streak**,
  12 for opening a **chest node**, and 20 for completing a **boss node**.
  Earnings stack: a perfect daily pays 5, and a perfect boss pays 23.
- **Each event pays once.** Each **earning** is recorded against the event
  that earned it — a date, a puzzle, a **streak** day, a **node** — so a replay, a
  retry, a re-completed board or a repeated write can never pay twice. A broken
  and restarted **streak** pays again at its own seventh day. **New decision,
  D-133.**
- **The balance is derived, never stored.** It is the sum of the recorded
  **earning**s, which cloud sync (change 29) can union without losing or duplicating
  anything, the way the **streak** is recomputed from the **calendar**.
  **D-133.**
- **An earning commits with its cause.** It is written in the same transaction
  as the completion that earned it, so the two survive an app kill together or
  not at all (constraint 9, the pattern D-124 set for **trophy**s).
- **No back-pay.** A player upgrading has earned nothing from before this
  version, as with **trophy**s (D-124).
- Glossary: **earning** — one payment of **stamp**s, recorded against the
  event that earned it. Distinct from an **award**, which is a **trophy**'s
  definition.
- **Where the player sees them:** a balance line in the **cabinet**, and a
  short earn notice ("+3 Stamps") once a celebration has finished. The notice
  never covers a grid still in play and never offers anything for sale.
  **New decision, D-134**, which also settles "every seventh day" as D-66's
  **streak** milestone.

## Constraints

**Capabilities:** `stamps` (new), `daily-challenge`, `trophy-cabinet`

**Constraint 10 — never purchasable.** There is no price, no store surface, no
bundle and no conversion from money, and a test asserts that no route in the
app sells a **stamp**. D-66 is the rule.

**Constraint 9 — written on every change.** An **earning** is a row in the cause's
transaction. There is no counter to update later and no timer.

**Constraint 1 — nothing is gated.** This change only earns. Spending, and the
guarantee that a balance of zero blocks nothing (D-67), belong to change 19.

**Constraints 2 and 6.** The earn notice waits for the celebration to finish,
takes no input, and blocks no tap. The **trail** carries no **stamp** count,
because D-114 records that a marker with a count on it drifts.

## Technical notes

**Offline, cold start, app kill:** Fully offline — **earning**s are local rows, like
**trophy**s. Schema v8 → v9 adds an **earning**s table that starts empty. A kill
mid-completion loses the **earning** and its cause together, never one without the
other.

**Grid performance:** None on the tap path. **Earning**s are written at completion,
which is already off the frame path. The balance is read by the **cabinet**
and by the notice, never by the grid.

**New dependency:** None.

## Not doing

- **Spending.** Perks, the hint meter and the free hint are change 19.
- **Any store, price, bundle or subscriber top-up.** D-66 and D-27.
- **Cosmetics from chests.** `docs/SPEC.md` §5.2 names them, but no cosmetic
  exists yet, and a **chest node** pays **stamp**s only.
- **Sync.** **Earning**s carry sync metadata, and change 29 merges them.
- **Fixing the daily and trophy wiring.** That is `wire-completion-events`.
- **A balance on the trail or in the grid.** D-114.
