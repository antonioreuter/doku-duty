# Doku Duty

A free-to-play sudoku game for iOS and Android (Flutter, single codebase) with a
comedic frontier setting and a deliberately non-punitive design.

**Current state: Milestones 0, 1 and 2 are complete.** Twenty-two changes are
archived — foundation, design system, persistence, remote config, puzzle
engine, generation, grid and input, notes, note automation, provisional notes,
the mistake model, completion effects, the pad's tools row, rank progression,
technique tutorials, the season map, the trail path, the daily challenge, the
trophy cabinet, puzzle variants, the wiring of completion events, and stamps. A player opens the app onto
the **trail**: 42 **node**s of a six-week **season**, walked in order, with
**daily**, **free play**, and the **cabinet** beside it. They place values, mark
notes in fixed positional slots, run a **chain test** in **provisional note**s,
and see **unit**s celebrate and hold a **completion tint** — with
**auto-cleanup**, **candidate highlighting**, and **auto-notes** throughout.
Their **rank** rises and never falls, a **lesson** teaches each technique the
first time a puzzle demands it, a **daily challenge** keeps a **streak** on the
**calendar**, and every **boss node**, closed **season**, perfect month and
**rank** reached mints a **trophy** into the **cabinet**. The six **variant
node**s of every **season** play **killer**: **cage**s with a **cage sum**, graded
on the same ladder, never reached from **free play** or the **daily**. Every
daily, perfect solve, seventh **streak** day, **chest node** and **boss node**
pays **stamp**s — each event once, as an **earning** in its cause's transaction
— and the balance, a sum never stored, sits in the **cabinet** (D-133, D-134).

Nothing is in progress. **Change 19, `add-perks`, is next and unblocked** — the
first thing that spends a **stamp**. Start it with `/propose-change add-perks`;
check `docs/changes/` is empty first.

Three finished changes are not in `docs/BACKLOG.md`'s numbering:
`add-pad-tools-row`, a corrective change that replaced six unlabelled glyph keys
with named controls after `add-mistake-model` found the pad overflowing;
`add-trail-path`, which drew the line joining the **trail**'s **node**s; and
`wire-completion-events`, which connected the **daily challenge**'s
**calendar** and the **rank** and perfect-month **trophy**s to real solves —
changes 14 and 16 had built and tested each hook in isolation, and nothing in
the running app called them. Expect finished changes the backlog does not
number; the backlog's status block lists them.

**Test a hook through the production wiring, not only in isolation.** That is
the lesson of `wire-completion-events`: a service with passing tests and no
production caller is indistinguishable from a working one until someone plays
the app. `test/features/grid_input/support/production_solve.dart` drives a
solve through the real `boardSinkProvider` for exactly this.

**Hardware verification is the standing debt, and every change since 11 has
added to it.** The mid-tier Android latency profile is recorded as unmet against
*both* change 6 and change 11 in `docs/BACKLOG.md`; a **cascade** is the
heavier frame, so `integration_test/completion_effects_test.dart` on one
physical phone settles both. Haptics are covered by neither — a simulator
reports success for a haptic it never played. Changes 15, 14, 16 and 17 each
added a runner — `season_map_test.dart`, `daily_challenge_test.dart`,
`trophy_cabinet_test.dart`, `killer_test.dart` under `integration_test/` — that
passes on the iOS
simulator and the Android emulator and has been taken on **no** physical device.
The attached iPhone reports Developer Mode off, and no Android phone is
attached. **One session with a mid-tier Android phone and a Developer-Mode
iPhone closes all of it.**

## Source of truth — read before proposing or implementing

| File | Holds |
|---|---|
| `docs/IDEA.md` | Product description, world, cast, business model |
| `docs/DECISIONS.md` | 135 numbered decisions (D-01 … D-135) with rationale |
| `docs/SPEC.md` | Long-form product spec |
| `docs/specs/<capability>.md` | **The permanent record of behaviour** — one file per capability, `MUST` + scenarios |
| `docs/GLOSSARY.md` | **Canonical vocabulary** |
| `docs/TECH_STACK.md` | **Canonical for the stack** — client, AWS backend, auth and guest tier, purchases, offline and sync |
| `docs/doku-duty-game-bible.md` | Mechanism, rules, objectives, narrative in one place |
| `docs/BACKLOG.md` | 34 changes in dependency order, grouped into 6 milestones |
| `docs/DESIGN.md` | Colour tokens with hex values, type, shape, motion, haptics |
| `docs/ART-BRIEF.md` | Character brief for the illustrator |
| `.claude/rules/` | Path-scoped rules: `specs.md`, `dart-code.md`, `testing.md` (the canonical test-first list) |

Cite decisions by ID (`D-33`) rather than restating the argument. If
implementation shows a decision is wrong, **amend `docs/DECISIONS.md` first, then the
spec** — never let the code quietly become the spec.

Decisions are never edited away. A replaced decision keeps its entry and gains a
`> **Superseded by D-NN**` marker; the replacement is appended as a new entry.
**D-56 … D-65 record the move from the original bureau setting to the frontier
setting** — so D-01, D-07's rank names, D-27, D-37 … D-45, D-51, and D-54 are
all historical. Read the superseding entry, not the original, but do not delete
the original.

## Workflow

Three project skills, one change at a time (D-135 records the move off
OpenSpec):

```
/propose-change <name>   # docs/changes/<name>/{proposal,tasks}.md + spec edits in docs/specs/
/apply-change            # implement, ticking tasks as you go
/finish-change           # verify, review against the constraints, update backlog, remove the folder
```

- Specs are edited **in place** in `docs/specs/` within the change — no delta
  files; the diff is the delta. A change with no observable behaviour
  (refactor, dependency bump, CI) writes no spec. Anything a player or another
  capability can observe needs one.
- Tick each task checkbox the moment it is done, not in a batch — solo project,
  nobody else can reconstruct where you stopped.
- Work the backlog in dependency order. Capability names are fixed in
  `docs/BACKLOG.md`; do not invent new ones without adding them there.
- A loose idea is settled before a change exists: `/grill-with-docs`, which the
  developer types, run on its own (nested in another workflow it writes
  nothing). `docs/SETUP.md` has the full loop.

## The ten constraints

Settled and not open to reinterpretation. **This list is canonical** — other
files point here rather than restating it, so it cannot drift.

1. **Non-punitive.** No lives, hearts, energy, session limits, or failure
   states. No timer can fail a puzzle. Auto-check off by default; mistake
   limits only in opt-in **strict mode**. Turning any of this on by default
   destroys the product's entire positioning.
2. **Input latency under 100ms.** No animation ever blocks the next tap. No
   in-puzzle effect exceeds 400ms, and every effect is skippable.
3. **Nine candidates per cell, in fixed positions.** 1 top-left, 5 centre,
   9 bottom-right, always. Adding or removing a candidate never moves the
   others.
4. **One colour, one job.** Eight tokens: six carry state — ink, focus,
   candidate, provisional, error, completion — and two are surfaces (D-71).
   Decoration draws from that set and never adds a ninth. Pale tints, depth
   shades, and on-colour text derive from one of the eight and are not a route
   around the count. Season themes repaint surfaces only.
5. **Colour is never the sole signal for any state.** Completion carries a
   **corner mark**; notes carry position; errors carry character animation.
6. **No ad ever interrupts a grid in progress.** Interstitials fire only after
   a **node** completes, after the celebration, and after an explicit tap.
7. **Ad removal is absolute**, verified by automated test on every release — a
   release blocker, not a support ticket category.
8. **Every puzzle has exactly one solution and is solvable by logic alone** at
   every **rank**. No guess-and-check.
9. **Note state is written on every change, never on a timer.** This protects
   saved games, and a plausible-looking change to notes logic can violate it
   without any visible symptom.
10. **No purchasable currency and no gacha.** **Stamp**s are earned in play
    only (D-66) and can never be bought — no coin store, no bundles. Running
    out never blocks play (D-67).

7 and 9 are the two that pass review unnoticed, because neither shows a
symptom in a diff.

**Platform requirements.** Both platforms are first-class: iOS 15+ and Android
8.0 (API 26)+, and nothing is complete until it works on both, including
haptics, safe areas, and store behaviour. Portrait primary; landscape on
tablets only. **Full offline play** — network only for ads, cloud save,
leaderboards, and pack top-ups, each degrading gracefully; nothing blocks first
frame. Cold start to playable under 2 seconds on a mid-tier Android device.

## Vocabulary

`docs/GLOSSARY.md` is canonical. Use these exact terms in
proposals, specs, tasks, code identifiers, and test names:

**node, season, rank, unit, peer, settled note, provisional note, generated
note, auto-cleanup, auto-notes, candidate highlighting, cabinet, strict mode,
stamp, perk, digit sweep**

The list grows: `add-note-automation` added **auto-notes**, **candidate
highlighting**, and **generated note**; `add-completion-effects` added
**completion tint**, **corner mark**, and **cascade**; `add-pad-tools-row`
added **tools row** and **chain test**; `add-rank-progression` added
**technique unlock**; `add-technique-tutorials` added **lesson** and **notes
lesson**; `add-season-map` added **trail**, **node type**, **variant node**,
**chest node**, **boss node**, **current node**, **not yet reached**, and **free
play**; `add-daily-challenge` added **daily challenge**, **calendar**,
**streak**, and **streak freeze**; `add-trophy-cabinet` added **trophy**,
**award**, and **unfiled**; `add-puzzle-variants` added **killer**, **cage**, and
**cage sum**. Read `docs/GLOSSARY.md` rather than this summary when it matters
— a change that needs a new concept adds it there in the same change.

Never write "box" for unit, "level" for node or rank, "pencil mark" for note, or
"difficulty" where rank is meant. A change that needs a new concept adds it to
the glossary in the same change.

**The six ranks, in order** (D-57): Greenhorn, Deputy, Sheriff, Marshal, Ranger,
Legend. Nothing is graded by clue count — a rank is the hardest technique the
puzzle requires.

**The cast** (D-58): the **Sheriff** (your boss, dry grudging approval), **Ace**
(the outlaw, tallies your mistakes, cheats at numbers), **Biscuit** (a wordless
burro, the only warmth in the cast), and **Number Four** (a digit with opinions).
Biscuit never speaks (D-59) and no character ever gives deliberately wrong
advice (D-60) — hints are correct or absent.

Note the collision: Sheriff and Deputy are both ranks *and* characters, and the
player is "the Deputy". Write "Sheriff rank" and "the Sheriff" as fixed
phrasings, and never use a bare rank name as a speaker label.

## Code conventions

The detail is in `.claude/rules/`, which load when you touch matching files —
`dart-code.md` for `lib/`, `testing.md` for tests, `specs.md` for `docs/specs/`.
In short:

- `flutter analyze` clean; `dart format` enforced in CI.
- Feature-first layout: `lib/features/<capability>/`, kebab-case capability
  names becoming snake_case directories.
- No business logic in widgets — controllers and services own it.
- Keep the solver, generator, technique grader, notes logic, mistake model and
  progression rules pure Dart with no Flutter import.
- Comments explain *why*, never *what*.

**Testing.** Test-first is required for the load-bearing pure-logic systems.
`.claude/rules/testing.md` names them canonically — read it there, and do not
copy the list into another file; four partial copies once disagreed. A task is
done when its test passes **on both platforms**, not when it compiles; the
simulator lies about haptics and frame timing.

Do not report a green test run you did not observe. Report what failed and the
actual output.

## Documentation layout

The glossary lives in `docs/GLOSSARY.md` and decisions in `docs/DECISIONS.md`
as the next `D-NN` with a rationale paragraph. Requirements live only in
`docs/specs/`. The `mattpocock/skills` tooling (`/grill-with-docs`,
`domain-modeling`) wants to create `CONTEXT.md` and a `docs/adr/` directory
instead — **do not let it.** Redirect its output to those two files; if a
`CONTEXT.md` or `adr/` appears, move the content and delete it.

## Known inconsistencies to resolve

- **`docs/pages/screens.html` is a historical mockup.** Its prose has been
  corrected to the decisions in force, and it now opens with a banner saying so
  — but **the artwork was never redrawn**. Every figure still shows the
  five-character bureau cast including Ruby, whom D-58 removed, and the §7 store
  screen is still presented by her. There is no generator for this page: earlier
  guidance here said to regenerate rather than hand-edit, and no such tool was
  ever written, which is why the page stayed stale for so long. Either redraw
  the figures or build the generator; do not trust the drawings meanwhile.
  **One colour in it is deliberately not followed** — it draws the **current
  node** on the **trail** in `sunsetRed`, whose documented job is "errors,
  duplicates, Ace". The built trail uses `badgeGold`, and D-112 records why, so
  that a redraw does not "correct" it back.
- **Nobody presents the store.** D-58 removed Ruby and named no replacement, so
  the store, the pass offer, and chest openings have no character attached. The
  argument for giving monetisation a face is still in `docs/SPEC.md` §7 and still
  good. Settle it before `add-purchases-and-entitlements` (change 26).
- **No integration test has run on a physical device.** The mid-tier Android
  latency profile has never been taken, and `add-season-map`,
  `add-daily-challenge`, `add-trophy-cabinet` and `add-puzzle-variants` each
  added a runner in the same position. Recorded
  against both `add-grid-and-input` and `add-completion-effects` in
  `docs/BACKLOG.md`: measured on the host, an emulator, and a simulator
  only, with roughly 200× headroom against the 100 ms budget — but that is an
  inference, not the measurement the backlog asked for. A **cascade** is the
  heavier frame, so `integration_test/completion_effects_test.dart` on the first
  physical phone that comes to hand settles both — and
  `integration_test/season_map_test.dart`, `daily_challenge_test.dart`,
  `trophy_cabinet_test.dart` and `killer_test.dart` follow in the same session.
  Record the number, and check the haptics by hand in the same session — and
  whether **killer**'s 8.3px notes and 8px **cage sum**s read on the smallest
  real phone (D-129).
- **The grid has no per-cell semantics on any board.** A screen reader hears one
  node, "Sudoku grid", and cannot focus a cell — so a **killer** cell's **cage
  sum** is not announced either. D-131 hands both to `add-accessibility-settings`
  (change 30).

Resolved, kept here only so they are not re-opened: the Sheriff's retired
wrong-advice gag (D-39 → D-60) is gone from `docs/ART-BRIEF.md`, whose animation
table now matches the bible and `docs/SPEC.md` §6; `docs/SETUP.md` and
`docs/pages/screens.html` both exist; an earned **trophy** keeps its minted
name when its **award** is renamed mid-**season** (D-126), and a perfect month
mints one **trophy** per month.
