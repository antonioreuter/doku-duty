# Tasks — add-stamps

**Blocked until `wire-completion-events` is archived.** That change makes a
solved **daily challenge** reach the **calendar** and calls the **trophy** hooks
from real solves. Group 0 re-checks this plan against what it actually built.

**On test-first.** `stamps` is not on the canonical list in
`openspec/config.yaml`, but the earning rules are pure logic that write saved
progress, and a silent bug pays twice or not at all. So groups 2 and 3 write
their failing tests first anyway.

## 0. After `wire-completion-events` lands

- [ ] 0.1 Re-read the archived `wire-completion-events` and the main
      `daily-challenge` and `trophy-cabinet` specs. If they changed "A completed
      daily is announced to the rest of the app", rebase this change's
      `daily-challenge` delta onto the new text before anything else. Confirm
      that the daily and the solve record reach `MintingService` in one
      transaction each. If either does not, stop and bring it back.

## 1. Vocabulary and decisions

- [ ] 1.1 Add **earning** to the glossary in `openspec/project.md`: one payment
      of **stamp**s, recorded against the event that earned it, and distinct
      from an **award**. Amend **stamp** to say its balance is the sum of its
      **earning**s.
- [ ] 1.2 Append **D-133** to `docs/DECISIONS.md`. Each event pays once and is
      recorded against a key naming it — `daily:<date>`, `perfect:<puzzleId>`,
      `streak:<run start>:<length>`, `chest:<season>:<position>`,
      `boss:<season>:<position>`. The balance is derived from the **earning**s,
      so sync can union them the way the **calendar** is unioned
      (`docs/TECH_STACK.md` §3b), and there is no back-pay (as D-124). Record why
      a stored counter was rejected: it can neither be merged nor made
      idempotent.
- [ ] 1.3 Append **D-134**. D-66's **streak** milestone is every seventh day of
      a run, and a restarted run pays again. The balance lives in the
      **cabinet** and nowhere on the **trail** or grid (D-114). The earn notice
      appears after the celebration, gives one total per completion, takes no
      input, and never offers anything for sale.
- [ ] 1.4 Add `stamps` to the merge table in `docs/TECH_STACK.md` §3b, as a union of
      **earning**s with the balance recomputed. Point `openspec/BACKLOG.md` item
      18 at D-133 and D-134.

## 2. What an event earns *(pure Dart, test-first)*

- [ ] 2.1 Write the failing tests in `test/features/stamps/earning_rules_test.dart`
      for the pure function that turns a completion into **earning**s:
  - each of the five events pays D-66's value under its key;
  - a perfect daily yields two **earning**s, and a perfect **boss node** two;
  - a solve with a **mistake** yields no perfect **earning**;
  - **streak** lengths 7, 14 and 21 pay, and 6, 8 and 13 do not;
  - two runs that each reach 7 get different keys;
  - a puzzle **node** and a **variant node** earn only through the perfect
    solve.
- [ ] 2.2 Implement it in `lib/features/stamps/domain/`, with no Flutter
      import, and add a `no_flutter_import_test.dart` for the domain.

## 3. Storage *(test-first)*

- [ ] 3.1 Add an `earnings` table — key, amount, earned-at and the sync metadata
      every progress table carries — moving the schema from v8 to v9. Export
      `drift_schema_v9.json`, and extend `migration_test.dart` with a v8 → v9
      case proving every save, calendar day, **trophy** and completion comes
      through with the table empty.
- [ ] 3.2 Write the failing `StampRepository` tests. Earning the same key twice
      leaves one row and moves the balance once. The balance is the sum of
      **earning**s and reads 0 when there are none. It survives closing and
      reopening a file database.
- [ ] 3.3 Implement `StampRepository`, earning with insert-or-ignore on the key.
      The balance is a `SUM` query with no stored counter.

## 4. Earning with the cause

- [ ] 4.1 Route every **earning** through `MintingService`, inside the
      transaction it already opens. That covers `completeNode` for **chest
      node**s and **boss node**s (it has to be told the **node type**),
      `afterDailyCompleted` for the day and the **streak**, and the
      solve-record hook for the perfect solve. Each call returns the
      **earning**s it wrote, for the notice.
- [ ] 4.2 Delete `node_types_test.dart`'s "grants no currency — change 18 owns
      the balance" and replace it with a test that opening a **chest node**
      earns 12 exactly once, the way 16 replaced the **boss node** seam.
- [ ] 4.3 `seams_test.dart`'s group "add-stamps (18) — nothing is minted" was
      written to be deleted by this change, as its own header says. **Delete
      it** and replace it with a test that a completed day earns 2, and a
      seventh day 12.
- [ ] 4.4 Atomicity tests, each on a file database, following
      `node_completion_atomicity_test.dart`:
  - a failure injected after the **earning** leaves neither it nor its cause;
  - a completed **boss node** played again earns nothing more;
  - a solved board erased and completed again earns nothing more.

## 5. What the player sees

- [ ] 5.1 A balance line in the **cabinet**, showing 0 for a new player, read
      after the first frame like the rest of the **cabinet**. Add a widget test,
      and a golden at 1x and 5x on a 320×568 screen.
- [ ] 5.2 The earn notice. It shows once per completion, with the total, after
      the celebration's last beat, or at once under reduce-motion. It is not
      modal, takes no taps, dismisses itself, and is absent when nothing was
      earned. Opening a **chest node** folds the 12 into the existing "Chest
      opened" message rather than adding a second notice. Widget tests cover
      each case, and one confirms a tap during the notice still reaches the
      screen.
- [ ] 5.3 Assert that the **trail** shows no **stamp** count, and that no route,
      screen or string in the app offers **stamp**s for money: search the
      widget tree and `lib/` for price and store vocabulary beside "Stamp".

## 6. Publishing and docs

- [ ] 6.1 In `lib/features/remote_config/PUBLISHING.md`, record that **stamp**
      values are compiled in (D-66) and that no config key can change or
      sell them.

## Platform checks

- [ ] Verified on iOS: open a **chest node** on a simulator and see the 12 in
      its message and in the **cabinet**. Kill the app and relaunch; the
      balance is unchanged.
- [ ] Verified on Android: the same. Extend `integration_test/` with a
      **stamps** runner that earns on a file database, reopens it, and reads
      the balance back.
- [ ] Accessibility: the screen reader announces the **cabinet** balance and
      the earn notice. The notice needs no colour to be read, obeys
      reduce-motion, and neither it nor the balance clips at 5x on a 320×568
      screen.
