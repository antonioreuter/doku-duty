# Shipped packs

Not content anybody wrote. Every puzzle here was produced by
`tool/generate_pack.dart`, verified to have exactly one solution by the engine's
exhaustive search, and graded by the engine's grader — so the `rank` on a row is
what the grader said about that grid, never what the tool was asked for
(D-07, D-32).

## `frontier-1.json`

Regenerate byte-for-byte with:

```
dart run tool/generate_pack.dart --seed 20260909 --version 2 --out assets/packs/frontier-1.json
```

| | |
|---|---|
| Seed | `20260909` classic, `20260923` **killer** |
| Pack id / version | `frontier-1` / 2 |
| Classic puzzles | 305 — Greenhorn 70, Deputy 70, Sheriff 60, Marshal 50, Ranger 35, Legend 20 |
| **Killer** puzzles | 72 — 12 at each of the six **rank**s (695 grid seeds, ~4 min) |
| Clue ceiling | 40 |
| Size | 334 KB |

Version 2 added the **killer** puzzles every **variant node** plays (D-127),
after the classic ones and with ids prefixed `k`: the two kinds share a seed
encoding, so a bare seed would collide. **Every classic row is identical to
version 1** — same ids, clues, solutions, **rank**s and seeds — so a player's
solved puzzles and a **daily challenge** derived from the **pack** are unmoved
by the upgrade. Each **killer** row carries its **cage**s as a list of
`{"sum", "cells"}`, verified unique under those **cage**s and graded on the same
ladder (D-128).

**Killer** givens run far lower than classic, because the **cage sum**s carry
the information: median 34.5 at Greenhorn, 12.5 at Deputy, and 4.5 to 6 from
Sheriff up. Legend is the slow **rank** to fill — about one grid seed in sixty
yields one.

A **pack** version is immutable: `add-persistence-layer` refuses to install a
version at or below the stored one, so a regenerated pack that differs in any
puzzle needs a new `--version`, not the same one edited.

`test/features/puzzle_engine/shipped_pack_test.dart` re-checks every puzzle in
this directory against the engine on every run. It is what makes the file above
evidence rather than a claim.
