# Tasks — add-completion-effects

## 1. Completion detection

Pure Dart under `lib/features/completion_effects/domain/`, no Flutter import.
Not on the canonical test-first list in `openspec/config.yaml`, but it is pure
logic the rest of the change hangs off, so it is written test-first anyway.

- [x] 1.1 Failing tests for unit completion: a **unit** holding nine distinct
      digits is complete; one holding nine values with a repeat is not; one with
      an empty cell is not; erasing from a complete **unit** un-completes it
- [x] 1.2 `UnitCompletion` — given a board and the cell just changed, report which
      of its three **unit**s became complete and which stopped being complete,
      touching only those three
- [x] 1.3 Failing test that completion never reads the solution: a **unit** of
      nine distinct digits that disagrees with the solution reports complete, and
      the detector's signature takes no solution
- [x] 1.4 Failing tests for board completion: full and no **unit** repeating a
      digit is finished; full with a repeat is not; and neither case reports
      anything about which cell is wrong
- [x] 1.5 Tint derivation — given a board, the set of cells carrying a
      **completion tint**, with a test that a cell in three completed **unit**s is
      returned once and identically to a cell in one (D-48)
- [x] 1.6 Failing test that notes complete nothing: filling a **unit**'s last
      empty cell with candidates rather than a value leaves it incomplete

## 2. The persistent record

- [x] 2.1 Paint the **completion tint** in `grid_painter.dart` from the derived
      cell set, one flat level, using the `cactusGreen` derived tint token — no
      new colour
- [x] 2.2 Golden test: a board with one completed **unit** and a board with three
      overlapping completed **unit**s produce the same tint value on the shared cell
- [x] 2.3 **Corner mark** on every tinted cell, drawn from the shape tokens
- [x] 2.4 Enforce the D-49 paint order in the painter — selection, then
      **candidate highlighting**, then **completion tint** — with a golden per pair
- [x] 2.5 "Hide completion tints" row in `settings_screen.dart`, off by default,
      persisted with the existing settings
- [x] 2.6 Test that hiding tints leaves the **corner mark**s and that a new player
      sees tints on and the setting off
- [x] 2.7 Test that reopening a part-finished puzzle shows tints and marks on the
      first frame and replays no effect

## 3. Effect infrastructure

- [x] 3.1 An effect event stream on the puzzle controller carrying what completed,
      where, and when — the seam `add-character-system` and a later sound layer
      subscribe to, with nothing audio-shaped in it yet
- [x] 3.2 Particle pool with the §6 caps, preallocated, reused rather than
      reallocated; unit test that a three-step **cascade** allocates no more than a
      single effect
- [x] 3.3 Cull particles over cells holding no value; test with an effect adjacent
      to empty ground
- [x] 3.4 Draw effects above cells and behind glyphs; golden test that a value
      crossed by an effect stays at full opacity
- [x] 3.5 Test that the effect layer reads board state and never writes it, so
      constraint 9 stays untouched

## 4. The effects

- [x] 4.1 Lasso for a completed row or column — 260ms, running from the placed
      cell along the **unit**, 18ms stagger, light impact haptic
- [x] 4.2 Dynamite for a completed block — 340ms, radial from the placed cell,
      medium impact haptic
- [x] 4.3 Test that a placement into an already-complete **unit** fires nothing
- [x] 4.4 Fresh-completion hold: `goldPale` for ~2s settling to `greenPale`, held
      as a state duration rather than a motion token, so the `design-system` build
      check still fails anything over 400ms that is not one of the two recorded
      exceptions
- [x] 4.5 Test that a second placement during the hold is accepted immediately and
      neither restarts nor waits on it, and that an app kill mid-hold reopens to
      the settled tint

## 5. Cascade

- [x] 5.1 Failing test for **cascade** ordering: a placement completing row,
      column, and block yields the three in that order at 90ms offsets, total
      520ms, and never two starting together (D-47)
- [x] 5.2 Failing test for the two-**unit** case — row and block chain at one 90ms
      offset, with the column step absent rather than held empty
- [x] 5.3 Chain the effects on those offsets, one haptic per step
- [x] 5.4 Named, empty slot for Biscuit's stamp on the third step, asserted by test
      to be absent and not to alter the 520ms timing

## 6. Puzzle completion sequence

- [x] 6.1 Beat list as an ordered, named structure, so a later change fills a beat
      without re-cutting the sequence
- [x] 6.2 Beat 1 — the wave crossing the grid from the final cell
- [x] 6.3 Beat 3 — the scrap burst, within the 40-scrap cap
- [x] 6.4 Beats 2 and 4 present as named empty slots for
      `add-character-system`; test that the sequence runs through them with no
      visible stall
- [x] 6.5 Test that a full board with a repeated digit plays no sequence and flags
      no cell
- [x] 6.6 Test that tapping away mid-sequence ends it and the puzzle is still
      recorded as solved

## 7. Latency and interruption

- [x] 7.1 Tap ends a running effect and is handled as the input it was, with the
      tint it would have settled into applied
- [x] 7.2 Test that placements made faster than the effects run are all accepted
      and that effects do not accumulate as a backlog
- [~] 7.3 Measure input latency with a **cascade** in flight and record it against
      the 100ms budget in `openspec/BACKLOG.md`, on a physical Android phone —
      the mid-tier profile that change 6 never took.
      **Everything except the phone is done.** `effect_latency_test.dart` takes
      it on the host (median 399 µs) and
      `integration_test/completion_effects_test.dart` takes it on any device —
      run on an Android emulator (median 3.9–4.5 ms) and an iOS simulator
      (median 409 µs), all recorded in `docs/PERFORMANCE.md` and against
      change 11 in `openspec/BACKLOG.md`. No physical Android phone is
      available. **Do not tick this until the phone number exists** — the
      emulator is the same evidence change 6 already has and the backlog
      already calls insufficient.

## Platform checks

- [~] Verified on iOS — effect timing, the two haptic weights, and 60fps through a
      **cascade** on a physical device. **Simulator only** (iPhone 17, iOS 26.5):
      painter median 224 µs across a cascade, 156 µs across the completion
      sequence, both far inside a 16.6 ms frame. **The haptics are unverified
      and cannot be verified here** — the simulator reports success for a
      haptic it never played, so whether the light impact and the medium impact
      feel different is still unknown. No physical device available.
- [~] Verified on Android — same, on a mid-tier physical phone, with the particle
      cap holding 60fps. **Emulator only** (Pixel, API 37): painter median
      3.0–3.6 ms across a cascade with the pool full at 60 particles, about a
      fifth of a 60fps frame. Haptics unverified, as above. **A mid-tier
      physical phone is the whole point of this line** and none is available,
      so it stays open.
- [x] Accessibility: **reduce effects** and OS reduce-motion each silence every
      effect and haptic on their own, with the **completion tint** and **corner
      mark** applied directly in their settled state; completion readable with
      tints hidden and under a deuteranopia simulation; dynamic type does not
      displace the **corner mark**; the grid's screen reader output states that a
      **unit** is complete
