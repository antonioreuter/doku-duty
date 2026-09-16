# Project context

## What this is

Doku Duty — a free-to-play sudoku game for iOS and Android with a comedic frontier setting, a cast of characters, and a deliberately non-punitive design. See `docs/IDEA.md` for the full product description.

## Tech stack

`docs/TECH_STACK.md` is canonical for the stack and holds the reasoning for each
choice. It is not repeated here — this table drifted from it once already, and
three entries were wrong (Isar, AdMob, Firebase) before anyone noticed.

Summary only, so this file is not useless on its own: **Flutter / Dart**, grid on
a `CustomPainter` canvas, **Riverpod** state, **go_router**, **Rive** characters,
**Drift over SQLite** locally, **AWS** (S3 + CloudFront for packs, API Gateway +
Lambda + DynamoDB for cloud save, Cognito for auth with a fully functional guest
tier), **AppLovin MAX** mediation with AdMob as a demand source, **RevenueCat**
for purchases, **Sentry**, **GitHub Actions** with Fastlane.

Puzzles are **pre-generated offline** into packs shipped with the app and topped
up from a server. Each puzzle carries its solution, its required-technique grade,
and a seed. On-device generation of a graded expert puzzle is too slow to be
acceptable.

## Platform requirements

- iOS 15+ and Android 8.0 (API 26)+
- Portrait primary; landscape supported on tablets only
- **Full offline play is mandatory.** Network is required only for ads, cloud save, leaderboards, and pack top-ups. Every one of those degrades gracefully.
- Cold start to playable under 2 seconds on a mid-tier Android device

## Non-negotiable product constraints

The ten constraints are defined in `openspec/config.yaml` under `context`, and
that copy is canonical. They are not repeated here on purpose: OpenSpec injects
the config context into every artifact prompt automatically, while this file is
only read when an instruction asks for it, so a second copy here drifts without
anyone noticing. It did drift once — this file and the config disagreed about
constraint 9.

Read them there before proposing or implementing anything.

## Conventions

**Code**
- `flutter analyze` clean; `dart format` enforced in CI
- Feature-first directory layout: `lib/features/<capability>/`
- Capability names in code match OpenSpec capability names, kebab-case → snake_case
- No business logic in widgets; keep it in controllers and services
- Every public API documented; comments explain *why*, never *what*

**Testing**
- Unit tests for the load-bearing pure-logic systems. `openspec/config.yaml` names them canonically under `rules.tasks`; it is not restated here, because four partial copies of this list once disagreed with each other
- Widget tests for grid interaction and input modes
- Golden tests for the eight colour tokens and their derived tints (D-71)
- Integration test asserting no ads are served when entitlement is active

**Specs**
- Capabilities are kebab-case directories under `openspec/specs/`
- Requirements use `The system MUST/SHALL` phrasing
- Every requirement carries at least one scenario
- Requirements that encode a product decision reference its ID (D-01 … D-70) from `docs/DECISIONS.md`

## Decision log

`docs/DECISIONS.md` holds 70 numbered product decisions with rationale. Specs reference these IDs rather than restating the argument. If implementation reveals a decision is wrong, amend the decision log first and then the spec — do not quietly diverge.

## Glossary

| Term | Meaning |
|---|---|
| **Node** | One stop on the season map: a puzzle, a variant, a chest, or a boss |
| **Season** | A six-week territory containing 42 nodes, then rotated out |
| **Pack** | A versioned, immutable shipment of pre-generated puzzles, each carrying its solution, its rank, and its seed (D-32). A pack is content; a season is play. One pack can supply several seasons, and a pack version never installs backwards |
| **Rank** | One of six difficulty tiers, from Greenhorn to Legend |
| **Unit** | A row, column, or 3×3 block |
| **Peer** | One of the twenty other cells a cell shares a unit with. A digit may appear at most once among a cell and its peers |
| **Settled note** | A candidate the player has derived (indigo) |
| **Provisional note** | A hypothesis under test (turquoise), clearable in one action |
| **Generated note** | A candidate **auto-notes** marked rather than the player. Identical on screen to one marked by hand; the distinction exists for undo, **auto-cleanup**, and clearing (D-15) |
| **Auto-cleanup** | Removing a placed value's candidate from its row, column, and block |
| **Auto-notes** | The one action that marks every empty cell with each candidate its peers do not already hold as a value. Unions with what is already marked; never replaces it (D-87) |
| **Candidate highlighting** | Lighting every cell that holds the held digit, or failing that the selected cell's digit, as a candidate or as a value. Derived rather than set by the player (D-88). Free and always on, unlike **digit sweep** (D-13) |
| **Promote** | The one action that turns every **provisional note** on the board into a **settled note**, adding and removing nothing. The other way a chain test ends, beside the D-11 clear (D-91) |
| **Cabinet** | The permanent trophy and statistics screen |
| **Mistake** | A placement that disagrees with the puzzle's solution. Counted per placement, never per cell, and never lowered by a correction, an erase, or an undo (D-96). Overwriting an already-correct cell is exempt (D-05), and no note is ever one (D-14) |
| **Attempt** | One run at a puzzle, and the **mistake**s recorded during it. Ends at the third in **strict mode** (D-95); starting again is the only route back to zero |
| **Strict mode** | Opt-in setting, off until the player turns it on: immediate error flagging *and* a three-**mistake** limit, together in one switch (D-04, D-94) |
| **Stamp** | The perk currency. Earned in play only, never purchasable |
| **Perk** | An assist bought with Stamps — hint, reveal a cell, scan a unit, digit sweep, solve a row, auto-notes charge |
| **Digit sweep** | The perk that reveals every remaining cell where a chosen digit belongs. Distinct from free candidate highlighting |
| **Guest** | A player with no account. Keeps full local save, streaks, and cabinet; lacks cross-device sync and reinstall recovery |
| **Signed in** | A player with a Cognito account. Adds cloud sync and recovery, free of charge (D-68) |
| **Flavour** | One of the three builds — `dev`, `staging`, `prod`. Each has its own identifier and launcher name and installs alongside the others (D-69) |
| **Design token** | A named value in the design system — a colour, type role, radius, stroke weight, duration, depth, or haptic. Code reads tokens; it never writes a literal |
| **State colour** | One of the six colour tokens that carries meaning on the grid: ink, focus, candidate, provisional, error, completion. Fixed across every season, unlike the two surface tokens (D-71, D-55) |
| **Reduce effects** | The in-app setting that silences tokenised motion. Independent of the OS reduce-motion setting; either one alone is enough |
