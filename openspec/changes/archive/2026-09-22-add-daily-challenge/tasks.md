# Tasks — add-daily-challenge

**On test-first.** The **streak**, the **streak freeze**, and schedule
resolution are pure Dart with no Flutter import, and a silent bug in any of them
breaks a counter a player may have held for a year. They are **not** on the
canonical test-first list in `openspec/config.yaml` — that list is the puzzle
engine, notes, the mistake model, and **rank** progression, and it is not
extended here. Test-first is applied to groups 2 and 3 as a judgment call,
recorded so nobody later reads it as the list having grown.

## 1. Vocabulary and decisions

- [x] 1.1 Add four terms to the glossary in `openspec/project.md`: **daily
      challenge**, **calendar**, **streak**, **streak freeze**. Nothing in
      groups 2–6 may be written before the words exist.
- [x] 1.2 Append **D-115** to `docs/DECISIONS.md`: a published schedule names
      the day's puzzle; when it is exhausted the board is derived from the
      installed **pack** by date seed. Record what is traded — sameness across
      players yields to the **daily challenge** existing at all — and why that
      is the right way round for a player who has been offline for months.
- [x] 1.3 Append **D-116**: the weekly difficulty ramp, and why the **rank**
      cannot scale to the player the way **free play** does.
- [x] 1.4 Append **D-117**: one **streak freeze**, regenerating every 7 days,
      never banked, consumed automatically. Record why banking was refused — a
      pile of freezes makes the **streak** stop measuring anything.

## 2. The date and the schedule *(pure logic, test-first)*

- [x] 2.1 Write the failing test for `DailyDate`: which date a given instant
      belongs to at local midnight, across a timezone change and across DST in
      both directions.
- [x] 2.2 Implement `DailyDate`, deriving from the stored server-time offset
      where one is known and the device clock otherwise, marking the latter
      unverified.
- [x] 2.3 Write the failing test for schedule resolution: a named puzzle when
      the schedule covers the date; the date-seeded **pack** board when it does
      not; the same fallback when the schedule names a puzzle that is not
      installed.
- [x] 2.4 Implement `DailySchedule` resolution against those three cases.
- [x] 2.5 Test that the derived fallback is stable — the same date and the same
      installed **pack** always yield the same board, across process restarts.
- [x] 2.6 Test that every board either route returns carries its solution and
      its **rank**, and that nothing calls the generator or the grader
      (constraint 8, D-32).

## 3. The calendar, the streak, and the freeze *(pure logic, test-first)*

- [x] 3.1 Write the failing test for **streak** recomputation from a set of
      completed dates: an empty **calendar**, a single day, a run, a run broken
      yesterday, and a run broken today.
- [x] 3.2 Implement the recomputation. Assert by test that no **streak** number
      is stored anywhere (`docs/TECH_STACK.md` §3b).
- [x] 3.3 Write the failing test for **streak freeze** accrual: granted every 7
      days, never more than one held, and a second 7 days holding one grants
      nothing.
- [x] 3.4 Write the failing test for automatic consumption: one missed day with
      a freeze continues the **streak**; one missed day without breaks it; two
      consecutive missed days with one freeze breaks it.
- [x] 3.5 Implement accrual and consumption. The player is never asked.
- [x] 3.6 Test that unioning two devices' **calendar**s and recomputing gives
      the same **streak** whichever order they merge in.
- [x] 3.7 Test that moving the clock forward marks those days unverified, and
      that a timezone change costs neither a **streak** nor a **calendar** day.

## 4. Persistence

- [x] 4.1 Add the **calendar** and **streak freeze** tables and move the Drift
      schema v5 → v6. Model completed days as a set of dates, unioned on merge,
      never as a counter.
- [x] 4.2 Export `drift_schema_v6.json` and extend
      `test/drift/app_database/migration_test.dart` with v5 → v6, keeping the
      existing v4 → v5 case intact.
- [x] 4.3 Test that a completed day is written before the celebration is shown,
      and that killing the app mid-puzzle marks nothing (constraint 9).
- [x] 4.4 Extend `no_deferred_writes_test.dart` to cover the **calendar**.

## 5. The screens

- [x] 5.1 Add the **daily challenge** entry to the navigation beside **trail**
      and **free play**. `app_router.dart` already says the daily arrives with
      the change that owns it — this is that change.
- [x] 5.2 Build the month-grid **calendar**, showing completed, missed, and
      freeze-covered days, each distinguishable without colour (constraint 5).
- [x] 5.3 Show the **streak** and whether a **streak freeze** is held.
- [x] 5.4 Open the day's board through the existing puzzle screen, marking it
      above the player's **rank** where it is, and never withholding it (D-103).
- [x] 5.5 Widget-test that midnight passing with the app open rolls the day over
      without discarding a puzzle in progress.
- [x] 5.6 Golden test the **calendar** in its three day states.

## 6. The seams other changes will use

- [x] 6.1 Signal a completion carrying the date and any **streak** milestone.
- [x] 6.2 Test that completing a **daily challenge** mints no **stamp** — a seam
      `add-stamps` (18) will fill, named so the absence is deliberate.
- [x] 6.3 Test that a full month files no trophy — `add-trophy-cabinet` (16).
- [x] 6.4 Test that no interstitial is shown and that a completed **daily
      challenge** does not advance any interstitial counter, so
      `add-ads-integration` (24) inherits the rule rather than re-deciding it
      (D-24).
- [x] 6.5 Test that nothing syncs — the shape supports §3b's union-and-recompute,
      and `add-cloud-sync` (29) implements it.

## 7. Publishing

- [x] 7.1 Extend `lib/features/remote_config/PUBLISHING.md` with the daily
      schedule document: its keys, the weekly ramp rule (D-116), and what the
      client refuses. Follow the **season** section's shape.
- [x] 7.2 Test that a malformed or absent schedule is refused into the fallback
      rather than crashing, matching how a bad **season** document is handled.

## Platform checks

- [x] Verified on iOS — iPhone 17 simulator (iOS 26.5), dev flavour.
      `integration_test/daily_challenge_test.dart` was written as the device
      runner for this capability and passes all five: safe area top 62.0pt /
      bottom 34.0pt with the nav at 840.0 of 874.0, the title clear of the
      status bar, every day of the month drawn, the day rolling over across
      local midnight (Monday's Greenhorn → Tuesday's Deputy), and a
      **calendar** surviving a real SQLite round trip through a second database
      over the same file. The same five pass on the Android emulator (safe area
      52/24pt, nav 928.0 of 952.0). **Neither is a physical device**, and the
      standing hardware debt against changes 6, 11 and 15 is untouched.
- [x] Verified on Android — Pixel 10 Pro emulator, Android 17 (API 37), dev
      flavour, cold launch after `pm clear`. **The timezone check earned its
      place: it found a bug.** With the app running, the device timezone was
      changed (Europe/Amsterdam → Pacific/Noumea, local date Mon 21 → Wed 23
      Sep). The app survived with no crash and no Flutter exception, but came
      back still showing Monday's Greenhorn board — `dailyStatusProvider` is a
      cached read and nothing invalidated it. Fixed by re-reading on resume
      when the date has moved, covered by two tests in `daily_screen_test.dart`
      (a plain rebuild hides it; only a resume with the tree still mounted
      reproduces it). Re-verified: after a second change (→ America/Tijuana,
      local date Tue 22 Sep) the screen reports **Deputy**, which is Tuesday on
      the ramp. Two other defects were caught on the same device and fixed —
      the title drew under the status bar, and a new player's **calendar**
      showed every past day of the month as *missed*.
- [x] Accessibility: `daily_accessibility_test.dart` passes all 9. Nothing
      overflows or truncates at 1x, 2x, 3x, 4x or 5x on a 320×568 screen (D-84)
      — the navigation stacks above 3x to make that true, because three
      destinations at a third of the width wrapped "Free play" to four lines
      and overflowed by 186 pixels. Every day state is announced in words —
      "completed", "streak freeze used", "missed", "not yet", "no record" — so
      a greyscale render and a screen reader both lose nothing; five states,
      five distinct labels. Today's **rank** is spoken too, because a player
      cannot infer it from their own ladder (D-116).
