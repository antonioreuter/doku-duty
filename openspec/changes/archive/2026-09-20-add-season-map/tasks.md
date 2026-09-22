# Tasks — add-season-map

`season-map` is not on the project's test-first list, but its **season** model
and its node-ordering rule are the parts a silent bug corrupts progress from, so
sections 2 and 3 write the failing test first and the domain carries no Flutter
import. Everything below section 4 is ordinary interleaving.

The app stays runnable after every task: **free play** is the route to a puzzle
until section 6 lands the trail, and it stays the route afterwards.

## 1. The decisions and the vocabulary

- [x] 1.1 `docs/DECISIONS.md` gains **D-108**: the trail is walked in order —
      completing **node** N makes N+1 current — and that order is not the lock
      D-103 refused. Rationale draws the line: D-103 refused to withhold a
      **rank** the player had *earned*, where the trail withholds only what they
      have not walked to yet, takes nothing away, and ends no attempt. Record the
      phrasing rule with it: a **node** ahead reads as **not yet reached**, never
      as locked, following D-104's discipline for **technique unlock**s
- [x] 1.2 `docs/DECISIONS.md` gains **D-109**: a **season** whose six weeks
      elapse with no successor defined holds open and playable, and stops showing
      a countdown rather than showing an elapsed one. Rationale names the
      alternative — closing the map at expiry, honest to "rotates out" (D-18) but
      in v1 it darkens the game's spine six weeks after launch with nothing
      behind it, and takes something from a player mid-play
- [x] 1.3 `docs/DECISIONS.md` gains **D-110**: a **node** names a **rank**, not a
      puzzle id; the puzzle is resolved from the **pack** when the **node** is
      opened. Rationale: naming puzzles pins a **season** to a **pack** version,
      so a top-up (D-32) or a regenerated pack would strand **node**s or revert
      completions. The cost is that two players' **season**s are not the same 42
      boards — which the **season** never promised, unlike the daily challenge
- [x] 1.4 `docs/DECISIONS.md` gains **D-111**: **free play** survives the trail.
      Rationale is the conflict it resolves — `grid-input` requires every
      **rank** openable and D-103 forbids gating one, while a trail walked in
      order puts Legend forty **node**s away; a trail-only route would re-impose
      exactly D-103's refused gate under another name. Note that this reverses
      the backlog's "15 deletes `rank_picker_screen.dart`": the screen is
      promoted, not deleted
- [x] 1.5 Glossary entries for **trail**, **node type**, **variant node**,
      **chest node**, **boss node**, **current node**, **not yet reached**, and
      **free play** in `openspec/project.md` *(added while writing the specs —
      verify each against what was built and correct it if it drifted)*
- [x] 1.6 Correct `openspec/BACKLOG.md` item 15: it says this change deletes
      `rank_picker_screen.dart`, and D-111 says otherwise. Leave the sentence's
      intent — the map is the spine — and fix the claim

- [x] 1.7 `docs/DECISIONS.md` gains **D-112**: the **current node** is
      `badgeGold`, not the mockup's `sunsetRed`. Added during implementation
      rather than planned — `docs/pages/screens.html` and `docs/DESIGN.md` §1
      disagree here, and without an entry the next person to redraw the
      mockup's figures would "correct" the trail back to red

## 2. The season model, in pure Dart

- [x] 2.1 Failing test: a **season** is exactly 42 **node**s — 30 puzzle, 6
      **variant node**, 4 **chest node**, 2 **boss node** (D-18) — and a
      composition that is not that is rejected rather than trimmed or padded
- [x] 2.2 Failing test: **chest node**s fall at 25/50/75/100% and **boss node**s
      at the midpoint and the finale, and a definition placing them elsewhere is
      rejected
- [x] 2.3 Failing test: every puzzle-bearing **node** names a **rank** and no
      **node** names a puzzle (D-110)
- [x] 2.4 `lib/features/season_map/domain/` — the model satisfying 2.1–2.3, pure
      Dart. A `no_flutter_import_test.dart` asserts the import is absent, matching
      how `puzzle-engine`, `mistake-model`, `rank-progression`, and
      `technique-tutorials` each guard theirs
- [x] 2.5 Season 1 as the compiled-in fallback: 42 **node**s with a **rank** ramp
      across the six **rank**s and D-19's front-loaded pacing. A test asserts it
      satisfies 2.1–2.3, so the fallback cannot be the one definition nobody
      checked

## 3. The ordering rule, in pure Dart

- [x] 3.1 Failing test: a **season** with no progress has its first **node**
      current, and that is a starting position rather than an absence
- [x] 3.2 Failing test: completing the **current node** makes the next **node**
      current; completing a **node** already completed moves nothing
- [x] 3.3 Failing test: a **node** beyond the furthest reached is **not yet
      reached**, and a completed **node** can be reopened without changing
      progress or taking anything away
- [x] 3.4 Failing test: no elapsed time, absence, **mistake**, or ended
      **attempt** moves the **current node** backwards or withdraws a completion
      (D-20, constraint 1)
- [x] 3.5 The rule satisfying 3.1–3.4, in the same pure-Dart domain as section 2

## 4. Persistence

- [x] 4.1 Failing test, then the schema bump: **season** progress — which
      **season** is in force, which **node**s are completed, which is current,
      and the per-**boss node** attempt count. Follow D-107 and spell the foreign
      key out rather than relying on `references()`
- [x] 4.2 Migration test from the current schema version, on the terms the
      existing versioned-migration requirement already sets
- [x] 4.3 Failing test, then the code: a **node** completion is written in the
      same transaction as its **solve record**, so a failure leaves neither and
      the **node** still reads current (constraint 9)
- [x] 4.4 Failing test: the app killed immediately after a **node** completes
      relaunches with that **node** completed and the next one current
- [x] 4.5 Failing test: a player with no **season** record reads as standing at
      the first **node**, never as an error
- [x] 4.6 Failing test: rotating a **season** leaves lifetime counters,
      per-technique counters, seen **lesson**s, and solved puzzles untouched, and
      starts the successor at its first **node** (D-17)
- [x] 4.7 Failing test: **boss node** attempts are counted and the count never
      restricts, prices, or ends access (D-22)

## 5. The season document

- [x] 5.1 Failing test, then the code: the **season** is read from the remote
      configuration document, degrading one key at a time as the existing
      requirement demands
- [x] 5.2 Failing test: a malformed **season**, or one failing section 2's
      composition rules, is ignored — the **season** in force continues and the
      player is told nothing
- [x] 5.3 Failing test: a **season** arriving mid-play does not disturb a
      **season** already in progress
- [x] 5.4 Failing test: with no configuration ever fetched, the compiled-in
      **season** is in force and all 42 **node**s are playable
- [x] 5.5 `lib/features/remote_config/PUBLISHING.md` gains the **season** keys,
      written as the specification the first upload is checked against — matching
      how the ad caps are documented there rather than from memory
- [x] 5.6 A fixture **season** in `test/features/remote_config/fixtures/`, valid
      byte for byte, exercising rotation so the mechanism is tested without a
      second territory being authored

## 6. The trail

- [x] 6.1 The trail screen: 42 **node**s on a winding path, **season** name, days
      remaining, progress count. Structure paints on the first frame and reads no
      database on the path to it — assert it the way the **free play** screen's
      test already does
- [x] 6.2 Node states — completed, current, **not yet reached** — with the
      **current node** drawn larger as well as differently coloured, and **chest
      node**s and **boss node**s identifiable by type in every state
- [x] 6.3 A test asserting no string shown to the player calls a **node**
      locked (D-108), alongside the **not yet reached** label
- [x] 6.4 Opening a **node**: resolve a puzzle of its **rank** from the **pack**
      at open time, and report a **rank** with nothing left as an ordinary
      absence rather than a block (constraint 1)
- [x] 6.5 Carry the **rank** mark onto the trail for a **node** naming a **rank**
      above the player's, asking `PlayerRank.above` rather than comparing enum
      indices
- [x] 6.6 Invalidate the trail's cached reads on the **solve record** write,
      explicitly — D-105 was found by a test and not by reasoning, and a screen
      mounted beneath the puzzle keeps its listener and never disposes
- [x] 6.7 Bottom navigation: Trail and Free play. Leave the Daily and Cabinet
      positions for changes 14 and 16 rather than stubbing screens behind them
- [x] 6.8 Promote `rank_picker_screen.dart` to **free play** — move it out of
      `grid_input/presentation/`, drop the scaffolding doc comment, and put it
      behind the nav. No redesign (D-111)
- [x] 6.9 Golden tests for the node states and for a season repaint, proving the
      repaint touches surfaces and props only and no **state colour** (constraint
      4, D-55)

## 7. Node types

- [x] 7.1 A **chest node** opens directly, completes on opening, needs no puzzle
      and no network, and grants no currency — with a test naming change 18 as
      the seam so the gap reads as deliberate rather than forgotten
- [x] 7.2 A **boss node** plays a puzzle and retries without limit or cost,
      including after an **attempt** ends on the third **mistake** in **strict
      mode**; it files no trophy, with a test naming change 16 as the seam
- [x] 7.3 A **variant node** is typed as one and plays a classic puzzle, with a
      test naming change 17 as the seam
- [x] 7.4 The node-completed signal carrying **node type**, for
      `add-ads-integration` to count against. A test asserts chest, boss, and
      daily carry the type that makes them never-eligible (constraint 6)

## 8. Season expiry

- [x] 8.1 Failing test, then the code: a **season** whose six weeks elapse with
      no successor holds open, every incomplete **node** stays completable, and
      no countdown is shown (D-109)
- [x] 8.2 Failing test: a defined successor may be rotated in, and section 4.6's
      permanence holds across it

## 9. Offline and first run

- [x] 9.1 An integration test: first launch with no network reaches a full
      42-**node** trail and completes a **node** of each type
- [x] 9.2 A test that the trail is not on the path to the first frame's database
      reads, and that cold start to the trail stays inside the budget in
      `openspec/project.md`

## Platform checks

- [ ] Verified on iOS — the trail scrolls and lays out inside the safe area on a
      notched device, and the **current node** is reachable without scrolling on
      first open
      *(**Partly done, and the runner exists.**
      `integration_test/season_map_test.dart` is the device runner and its four
      tests pass on the iOS 26.5 simulator: safe area top 62pt / bottom 34pt,
      navigation bottom at 840pt of 874 — the home indicator exactly clear —
      the **current node** on screen without scrolling, all 42 reachable, and a
      **node** completion surviving a round trip through a real SQLite file.
      **Not taken on the physical iPhone**: the connected device reports
      Developer Mode off, which is a Settings toggle on the phone, not
      something the build can enable. Turn on Settings → Privacy & Security →
      Developer Mode, then
      `flutter test integration_test/season_map_test.dart -d 00008120-001169481EC2201E --flavor dev`.
      Whether the trail *looks* right is still a pair of eyes either way.)*
- [ ] Verified on Android — same, plus back from a **node** returns to the trail
      with progress applied rather than to a stale frame
      *(**Not taken — no Android device or emulator is attached.**
      `flutter devices` finds an iOS simulator, macOS, Chrome, and one wireless
      iPhone. Run the same
      `integration_test/season_map_test.dart` on the first Android phone that
      comes to hand; the back-from-a-node case is the one it does not cover, and
      is a manual check.)*
- [ ] **Take the outstanding mid-tier Android profile in this session.** It is
      recorded as unmet against changes 6 and 11 and a **cascade** is the heavier
      frame, so run `integration_test/completion_effects_test.dart` on the phone
      while it is in hand, record the number in `docs/PERFORMANCE.md`, and clear
      both OUTSTANDING notes in `openspec/BACKLOG.md`. Check the haptics by hand
      in the same session — the simulator reports success for a haptic it never
      played
      *(**Not taken — no Android device is attached**, as above. Unchanged from
      how changes 6 and 11 left it, and still one session's work whenever a
      phone is to hand.)*
- [x] Accessibility: dynamic type on the trail's node labels and header; screen
      reader labels naming each **node**'s type and state in words; reduce
      effects and OS reduce-motion silence any trail motion; every node state and
      the **rank** mark readable with colour removed (constraint 5)
      *(`trail_accessibility_test.dart`, on the host. It found two real defects
      rather than confirming the design: Material's `NavigationBar` overflowed
      by 139px at 4x and 381px at 5x, and the **season** name ellipsised in the
      `AppBar` from 2x — a screen named after a place, with the place cut off.
      The nav now grows with the text the way the **tools row** does (D-100),
      and the name moved into the scrolling header where it wraps. Reduce-motion
      is asserted as **nothing to silence**: the trail animates nothing, and the
      test fails if a later change adds motion here without wiring the setting.)
