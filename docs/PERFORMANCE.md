# Measured performance

Numbers that a later change has to design against, recorded when they were
taken rather than reconstructed later. Nothing here is a budget — the budgets
are the ten constraints in `openspec/config.yaml`. This is what the code
actually costs.

Each entry says what was measured, on what, and when. Re-measure rather than
trust an old row when the code underneath it has moved.

## Puzzle engine solver — `add-puzzle-engine`, 2026-09-09

Measured over the three Legend puzzles in the engine's test corpus
(`test/features/puzzle_engine/support/corpus.dart`), medians over repeated runs.
"Worst step" is the slowest single deduction anywhere in a full solve, which is
the number that matters for a hint: it is what a player would wait for on the
unluckiest tap.

| Where | Single step (median) | Worst step in a full solve | Full solve (median) |
|---|---|---|---|
| Host — macOS, Apple silicon, `flutter test` | 12 µs | 4.7 ms | ~1 ms |
| Android — Pixel emulator, API 37, debug build | 14 µs | 3.1 ms | 5.8 ms |
| iOS — iPhone 17 simulator, iOS 26.5, debug build | 17 µs | 1.0 ms | 3.6 ms |

Both device figures are **debug** builds; a release build is faster, so treat
these as a ceiling rather than an estimate.

**What this means for `add-perks` (change 19).** A hint asks the solver for one
step. The median step is microseconds and the worst is a few milliseconds, so a
hint can be answered synchronously inside the 100 ms input-latency budget
(constraint 2) without an isolate, and without a spinner. A full solve is the
expensive operation, and nothing on a frame path needs one.

Reproduce with:

```
flutter test test/features/puzzle_engine/timing_test.dart          # host
flutter test integration_test/puzzle_engine_timing_test.dart \
  -d <device> --flavor dev                                          # device
```

Both print their measurements. The assertions in them are loose on purpose —
they catch a hundredfold regression and nothing subtler, because a tight bound
on a shared machine is a flaky test rather than a budget.

## Puzzle generation — `add-puzzle-generation`, 2026-09-09

Offline only; none of this runs on a device (D-32). Measured on the host, macOS
on Apple silicon, generating the shipped `frontier-1` pack from seed `20260909`.

| | |
|---|---|
| Whole pack — 305 puzzles, six **rank**s | **7.0 s**, 1,232 grid seeds |
| Candidates considered / discarded | 19,049 / 18,744 |
| Shipped file size | 87 KB — 89,444 bytes, uncompressed in the APK at `assets/flutter_assets/assets/packs/frontier-1.json` |

Per **rank**, generated on its own from the same seed:

| Rank | Wanted | Grid seeds | Time |
|---|---|---|---|
| Legend | 20 | 42 | 0.3 s |
| Marshal | 50 | 375 | 2.1 s |
| Ranger | 35 | 1,232 | 6.8 s |

**Ranger is the bottleneck, not Legend, and that is worth knowing before the
next pack is planned.** A puzzle is Ranger when the hardest thing it needs is a
hidden pair or an X-wing — a narrow band, because a dig that gets hard enough to
need an X-wing usually keeps going until it needs a chain, and lands in Legend
instead. Legend is thirty times cheaper to hit. A future season wanting a
Ranger-heavy split should budget grid seeds accordingly rather than assuming
cost rises with **rank**.

Reproduce with:

```
dart run tool/generate_pack.dart --seed 20260909 --out assets/packs/frontier-1.json
```

## Grid input — `add-grid-and-input`, 2026-09-09

Tap to repaint: selecting a cell, placing a digit, and painting the whole board.
Measured over the 51 placements that solve one Legend puzzle, so the later
samples are of a nearly full grid.

| Where | Median | Worst |
|---|---|---|
| Host — macOS, Apple silicon | 285 µs | 23 ms |
| Android — Pixel emulator, API 37, debug | 464 µs | 7.8 ms |
| iOS — iPhone 17 simulator, iOS 26.5, debug | 416 µs | 11.8 ms |

**Constraint 2 allows 100 ms.** The median is under half a percent of that and
the worst sample is about a tenth, on debug builds. Filling the grid does not
make it slower: the first twenty-five placements median 323 µs on the host and
the last twenty-six median 300 µs, because the painter's cost is the eighty-one
cells it always draws, not the digits that accumulate in them.

**These are an emulator and a simulator, and that is not the measurement the
backlog asks for.** `openspec/BACKLOG.md` says of this change: *"the sub-100ms
latency budget is a product requirement, not an aspiration. Profile on a
mid-tier Android device before this change is considered done."* An emulator
runs on the desktop's CPU and will happily report a budget a £150 phone misses.
Read the numbers above as an upper bound on good hardware. The headroom is large
enough — roughly 200× on the median — that a phone several times slower still
clears the budget, but that is an inference, not a measurement.

Reproduce with:

```
flutter test test/features/grid_input/latency_test.dart            # host
flutter test integration_test/grid_latency_test.dart \
  -d <device> --flavor dev                                          # device
```

## Notes — `add-notes`, 2026-09-10

A board at maximum note density: every empty cell holding all nine candidates.
459 glyphs where a board of values alone has 81.

| What | Median | Worst |
|---|---|---|
| Host — repaint at 459 candidates | 754 µs | 1.7 ms |
| Host — tap to repaint, values only (for comparison) | 451 µs | 25 ms |

Roughly 1.7× the cost of an empty board's repaint, against a 100 ms budget. The
shape of the cost is what makes that hold: a candidate's glyph is laid out once
per digit and cached, so nine candidates in a cell is nine draws and no text
shaping, and a candidate's position comes from `NoteSet.slotOf` rather than from
a layout pass.

**Not measured on a phone.** The outstanding device profile recorded against
change 6 in `openspec/BACKLOG.md` applies here too, and more so — this change
multiplies the glyph count by up to nine. When a mid-tier Android phone is
available, measure it with a dense board rather than an empty one.

Reproduce with:

```
flutter test test/features/grid_input/latency_test.dart
```

