# Tasks — add-trophy-cabinet

**On test-first.** `trophy-cabinet` is **not** on the canonical test-first list
in `openspec/config.yaml` — that list is the puzzle engine, notes, the mistake
model, and **rank** progression, and this change does not extend it. Group 3 is
written test-first anyway, as a judgment call: minting is a write that happens
inside somebody else's transaction, and a **trophy** minted twice or lost with
its cause is the kind of defect a player reports as "my cabinet is wrong" with
nothing in the logs.

## 1. Vocabulary and decisions

- [x] 1.1 Add three terms to the glossary in `openspec/project.md`: **trophy**,
      **award**, **unfiled**. **Cabinet** is already there and its definition
      still holds. Nothing below may be written before the words exist.
- [x] 1.2 Append **D-124** to `docs/DECISIONS.md`: a **trophy** is minted when
      earned, not derived. Record why this departs from D-104's derive-first
      rule — a **trophy** is a record of an *event*, like a **solve record**,
      not a *state* like a **streak**; and a seasonal one cannot be derived at
      all once the **season** document it came from has rotated away.
- [x] 1.3 Append **D-125**: a **season** declares its own **award**s in the
      published document. Record what it buys — a new territory's **trophy**s
      become a publish rather than a release — and the fallback that keeps the
      **cabinet** whole when nothing is published.

## 2. The award catalogue *(pure logic)*

- [x] 2.1 Add the **award** model in `lib/features/trophy_cabinet/domain/`,
      carrying an id, a name, the **season** it belongs to, and what earns it.
      No Flutter and no Drift import; add the guard test the other capabilities
      use (`no_flutter_import_test.dart`).
- [x] 2.2 Read **award**s from the **season** document, refusing a malformed
      entry per-entry rather than per-document — the shape the daily schedule
      and the **season** itself already use.
- [x] 2.3 Compile in season one's **award**s as the fallback, and test that an
      absent or empty list still yields a fully populated **cabinet**.
- [x] 2.4 Test the permanent **award**s — those belonging to no **season** —
      are always present whatever is published.

## 3. Minting *(test-first)*

- [x] 3.1 Write the failing test: a **boss node** completion mints exactly one
      **trophy**, in the same transaction as the completion.
- [x] 3.2 Write the failing test for the negative cases: the same event twice
      mints once and keeps the first date; a completion that fails to write
      mints nothing; a **trophy** never appears without its cause.
- [x] 3.3 Implement minting, and the **trophy** table with the **season** id and
      name captured at mint time (D-124).
- [x] 3.4 Move the Drift schema v6 → v7, export `drift_schema_v7.json`, and
      extend `test/drift/app_database/migration_test.dart` with v6 → v7,
      keeping the existing cases intact. **The new table arrives empty** — there
      is no retroactive minting, and the test should say so.
- [x] 3.5 Add the **trophy** table to `syncableTables` and to
      `no_deferred_writes_test.dart`'s watch list, the day it lands.
- [x] 3.6 Test that a **trophy** minted under a **season** whose document is
      gone still shows its name and territory.

## 4. Filling the seams other changes left

- [x] 4.1 `add-season-map` (15) left a test asserting a **boss node** completes
      and files no trophy. **Delete that test** and replace it with one
      asserting it now does — it was written to hand over, not to be edited
      into agreement.
- [x] 4.2 The same for the season-completion seam, if 15 left one.
- [x] 4.3 `add-daily-challenge` (14) left the equivalent for a perfect month in
      `seams_test.dart`. Delete and replace it the same way.
- [x] 4.4 Confirm no **stamp** is minted by any of this — `add-stamps` (18)
      still owns that, and its seam test should survive untouched.

## 5. The cabinet

- [x] 5.1 Add the **cabinet** to the navigation. It is the fourth destination,
      and `home_shell.dart` already stacks the bar above 3x text for exactly
      this reason — re-run the 1x–5x checks, because four is the case that
      was never tried.
- [x] 5.2 Defer every database read past the first frame, the way the **trail**
      and the **daily challenge** do, and extend `lazy_open_test.dart`.
- [x] 5.3 Draw earned and **unfiled** with a glyph and a word as well as a fill,
      and no ninth hue (constraints 4 and 5).
- [x] 5.4 Show lifetime and per-technique statistics read from the existing
      counters. Test that the **cabinet** keeps no count of its own.
- [x] 5.5 Golden the **cabinet** in three states: nothing earned, some earned,
      and a **trophy** from a rotated **season**. Pass every date in — no
      golden may read the wall clock (D-118).

## 6. Reparenting the lessons

- [x] 6.1 Move `LessonsScreen` into the **cabinet** and remove the settings row
      that currently opens it. Its own doc comment says "Reparented by change
      16"; update it to say where it now lives.
- [x] 6.2 Test that every **lesson** is still replayable and that replaying one
      changes no progression state (D-106).
- [x] 6.3 Test the old settings route is gone, so the list has one home.

## 7. Publishing

- [x] 7.1 Document the **award**s key in
      `lib/features/remote_config/PUBLISHING.md`, beside the **season** and the
      daily schedule: its shape, what the client refuses, and what an **award**
      cannot do.
- [x] 7.2 Test a malformed **award** list degrades to the fallback rather than
      failing, matching how a bad **season** and a bad daily schedule are
      handled.

## Platform checks

- [x] Verified on iOS — the **cabinet** on a simulator, inside the safe area,
      with the four-destination navigation.
- [x] Verified on Android — the same. Extend
      `integration_test/` with a cabinet runner, the way changes 15 and 14 each
      added theirs.
- [x] Accessibility: the **cabinet** at text scales 1x–5x on the smallest phone
      the app targets (D-84) — **four** destinations is the untested case; every
      **trophy** and statistic announced in words; earned and **unfiled**
      distinguishable with colour removed.
