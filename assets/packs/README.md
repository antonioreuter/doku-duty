# Shipped packs

Not content anybody wrote. Every puzzle here was produced by
`tool/generate_pack.dart`, verified to have exactly one solution by the engine's
exhaustive search, and graded by the engine's grader — so the `rank` on a row is
what the grader said about that grid, never what the tool was asked for
(D-07, D-32).

## `frontier-1.json`

Regenerate byte-for-byte with:

```
dart run tool/generate_pack.dart --seed 20260909 --out assets/packs/frontier-1.json
```

| | |
|---|---|
| Seed | `20260909` |
| Pack id / version | `frontier-1` / 1 |
| Puzzles | 305 — Greenhorn 70, Deputy 70, Sheriff 60, Marshal 50, Ranger 35, Legend 20 |
| Clue ceiling | 40 |
| Size | 87 KB |

A **pack** version is immutable: `add-persistence-layer` refuses to install a
version at or below the stored one, so a regenerated pack that differs in any
puzzle needs a new `--version`, not the same one edited.

`test/features/puzzle_engine/shipped_pack_test.dart` re-checks every puzzle in
this directory against the engine on every run. It is what makes the file above
evidence rather than a claim.
