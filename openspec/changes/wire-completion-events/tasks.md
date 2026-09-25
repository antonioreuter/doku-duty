# Tasks — wire-completion-events

**On test-first.** The **rank** half of this touches rank progression, which is
on the canonical list in `openspec/config.yaml`. The **calendar** half writes
saved progress. Every group below writes its failing test before the code that
satisfies it. The bug hid because each seam was tested alone, so the tests that
matter here drive a real solve through `RepositoryBoardSink` against a real
database, not a service called directly.

## 1. Decision and reproduction

- [x] 1.1 Append **D-132** to `docs/DECISIONS.md`: a **daily challenge** is
      credited to the date its board was opened for, not the date it was
      solved. Rationale: constraint 1, since the edge case always resolves for
      the player. Late credit is always for a board actually solved, and the
      daily screen only ever opens today's board. Record what breaks if reversed:
      a daily finished after midnight silently costs a day the player earned.
- [x] 1.2 Write the failing reproduction in
      `test/features/daily_challenge/solve_wiring_test.dart`. Open today's board
      as the daily, solve it through the production `boardSinkProvider`, and
      assert the day is on the **calendar**. It must fail on `main` for the
      reason the bug names, not for a setup error.
- [x] 1.3 Write the failing reproduction in
      `test/features/trophy_cabinet/solve_wiring_test.dart`. Solve a Sheriff
      **rank** puzzle in **free play** through the production sink, and assert
      the Sheriff **rank** **trophy** is earned. It must fail on `main`.

## 2. One origin per open board

- [x] 2.1 Test first, in `test/features/grid_input/puzzle_origin_test.dart`.
      Opening a **node**, then the daily, then **free play** leaves exactly the
      last origin. Opening the daily carries the `DatedDay` it was opened for.
- [x] 2.2 Add `lib/features/grid_input/application/puzzle_origin.dart`: a
      sealed `PuzzleOrigin` (`TrailOrigin(position)`, `DailyOrigin(DatedDay)`,
      `FreePlayOrigin`) and a `puzzleOriginProvider` notifier. Opening any
      origin replaces the previous one. Document why it is one value rather
      than two flags: a stale daily marker would credit a later solve in
      **free play**.
- [x] 2.3 Replace `activeNodeProvider` with `puzzleOriginProvider` in
      `trail_screen.dart`, `free_play_screen.dart` and `daily_screen.dart`, and
      delete `ActiveNode`. The daily card sets `DailyOrigin` with the day the
      card shows — `DailyStatus` now carries its `isVerified` flag — rather
      than re-reading the clock on the tap, which would credit a new day with
      the previous day's board if a stale card were tapped past midnight. The
      existing season-map and daily tests pass unchanged apart from the
      renamed provider.

## 3. The day commits with the solve

- [x] 3.1 Test first. Change `DailyService.complete` to take the `DatedDay` it
      records, instead of reading the clock. A test pins the midnight case:
      complete a day opened on the 14th with the clock on the 15th, and assert
      the 14th is recorded and the 15th is not.
- [x] 3.2 Test first, in `minting_events_test.dart`: `MintingService.completeDay`
      records the day and mints the month's **trophy** when that day completes
      the month, returns the `DailyCompletion`, and does both in one
      transaction. A failure injected after the day's write leaves neither.
- [x] 3.3 Implement `MintingService.completeDay(DatedDay)`, wrapping
      `DailyService.complete` and the perfect-month check (today's
      `afterDailyCompleted` body) in one transaction. Give `MintingService` the
      `DailyService` it needs through `mintingServiceProvider`.
- [x] 3.4 In `boardSinkProvider`, replace `nodeCompletion` with a completion
      chosen by origin: `TrailOrigin` → `minting.completeNode` as today,
      `DailyOrigin` → `minting.completeDay`, and `FreePlayOrigin` → nothing.
      The origin is read at the moment of completion, as `activeNodeProvider`
      is now. Task 1.2 passes.

## 4. Rank trophies on every solve

- [x] 4.1 Test first, in `test/features/rank_progression/`:
      `ProgressionRepository.record` runs an `afterInTransaction` callback
      after the **solve record** is written, inside the same transaction. It
      also runs when the puzzle already holds a record, so a player who
      reached a **rank** before this fix gets the **trophy** on their next
      solve. A throw from it rolls back the **solve record**.
- [x] 4.2 Implement `afterInTransaction` on `record`, and thread it through
      `RepositoryBoardSink`.
- [x] 4.3 In `boardSinkProvider`, pass a callback that reads `playerRank()`
      inside the transaction and calls `minting.afterRankReached`. It runs for
      every origin. Task 1.3 passes.
- [x] 4.4 Test: a daily solve that also raises the **rank** writes the day, the
      **solve record** and the **rank** **trophy** together, or none of them.

## 5. Screens read fresh

- [x] 5.1 Widget test: solve the daily from the daily screen, go back, and see
      the card read "Completed today" and the **calendar** mark the day. Then
      open the **cabinet** and see the **rank** **trophy** earned, with no
      restart.
- [x] 5.2 Add `dailyStatusProvider`, `earnedTrophiesProvider`,
      `earnedIdsProvider` and `cabinetStatisticsProvider` to `onSolveRecorded`'s
      invalidations. Task 5.1 passes.

## 6. Retire the stale seams

- [x] 6.1 Rewrite the daily test for "Nothing is minted yet" to its new
      text: a perfect month now files its **trophy**, and only the **stamp** is
      absent. Search `test/` for other tests asserting that a
      daily or a **rank** mints nothing, and correct each one.
- [x] 6.2 Remove `MintingService.afterDailyCompleted` if nothing calls it once
      3.3 lands, and move its tests onto `completeDay`.
- [x] 6.3 Extend `integration_test/daily_challenge_test.dart` with one real solve
      from the daily card through to the **calendar**, instead of seeding by
      `completeDay`.

## 7. Docs

- [x] 7.1 `openspec/BACKLOG.md`: under items 14 and 16, note that their
      completion hooks were never wired to a real solve and that
      `wire-completion-events` wired them. Add the change to the status
      block's list of archived changes the backlog does not number.
- [x] 7.2 `CLAUDE.md`: count the change among the archived, add it to the
      unnumbered list beside `add-pad-tools-row` and `add-trail-path`, and name
      `add-stamps` as next.
- [x] 7.3 `flutter analyze` clean, `dart format` clean, and the full
      `flutter test` suite green. Report the actual output.

## Platform checks

- [x] Verified on iOS: the simulator runs `integration_test/daily_challenge_test.dart` and `trophy_cabinet_test.dart`.
      iPhone 17e simulator, iOS 26.5: 6/6 and 3/3 pass (safe area 47/34pt).
      The new solve test skips the **notes lesson** only when it appears — the
      simulator keeps that it was seen between runs. No physical device: the
      attached iPhone still reports Developer Mode off.
- [x] Verified on Android: the emulator runs the same two runners.
      Pixel emulator, API 37: 6/6 and 3/3 pass (safe area 52/24pt). No physical
      Android phone attached.
- [x] Accessibility: the daily card's semantics label reads "completed" after a
      real solve, and the newly earned **trophy** is announced as earned. No
      colour, motion or haptic changes.
