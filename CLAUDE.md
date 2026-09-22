# Doku Duty

A free-to-play sudoku game for iOS and Android (Flutter, single codebase) with a
comedic frontier setting and a deliberately non-punitive design.

**Current state: Milestones 0 and 1 are complete; Milestone 2 is two-thirds
done.** Sixteen changes are archived — foundation, design system, persistence,
remote config, puzzle engine, generation, grid and input, notes, note
automation, provisional notes, the mistake model, completion effects, the pad's
tools row, rank progression, technique tutorials, and the season map. A player
opens the app onto the **trail**: 42 **node**s of a six-week **season**, walked
in order, with **free play** beside it reaching any **rank** at any time. They
place values, mark notes in fixed positional slots, run a **chain test** in
**provisional note**s, and see **unit**s celebrate and hold a **completion
tint** — with **auto-cleanup**, **candidate highlighting**, and **auto-notes**
throughout. Their **rank** rises and never falls, and a **lesson** teaches each
technique the first time a puzzle demands it.

Nothing is in progress. The next item is **backlog change 14,
`add-daily-challenge`**; its dependencies (3, 5) are both archived. **Change 17,
`add-puzzle-variants`, is also unblocked** now that 15 has landed — the six
**variant node**s exist and play classic boards until it gives the **season** a
rule. Run `openspec status` to confirm before starting.

`add-pad-tools-row` is not in `openspec/BACKLOG.md` — it was an unnumbered
corrective change that replaced six unlabelled glyph keys with named controls
after `add-mistake-model` found the pad overflowing. Expect the archive to hold
changes the backlog does not number.

**Hardware verification is the standing debt, and change 15 added to it.** The
mid-tier Android latency profile is recorded as unmet against *both* change 6
and change 11 in `openspec/BACKLOG.md`; a **cascade** is the heavier frame, so
`integration_test/completion_effects_test.dart` on one physical phone settles
both. Haptics are covered by neither — a simulator reports success for a haptic
it never played. Change 15 then added its own:
`integration_test/season_map_test.dart` passes on the iOS simulator but has been
taken on **no** physical device — the attached iPhone reports Developer Mode off,
and no Android device is attached. **One session with a mid-tier Android phone
and a Developer-Mode iPhone closes all four.**

## Source of truth — read before proposing or implementing

| File | Holds |
|---|---|
| `docs/IDEA.md` | Product description, world, cast, business model |
| `docs/DECISIONS.md` | 101 numbered decisions (D-01 … D-101) with rationale |
| `docs/SPEC.md` | Long-form product spec |
| `openspec/project.md` | Platform requirements, conventions, glossary |
| `docs/TECH_STACK.md` | **Canonical for the stack** — client, AWS backend, auth and guest tier, purchases, offline and sync |
| `docs/doku-duty-game-bible.md` | Mechanism, rules, objectives, narrative in one place |
| `openspec/BACKLOG.md` | 34 changes in dependency order, grouped into 6 milestones |
| `docs/DESIGN.md` | Colour tokens with hex values, type, shape, motion, haptics |
| `docs/ART-BRIEF.md` | Character brief for the illustrator |
| `openspec/config.yaml` | The ten constraints + per-artifact rules the workflow enforces |

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

This project uses OpenSpec with a custom lightweight schema, `doku-lite`
(`openspec/schemas/doku-lite/`): three artifacts per change — proposal, delta
specs, tasks. There is no `design.md`; its questions live as prompts inside the
proposal template.

```
/opsx:propose <change-name>   # proposal + specs + tasks in one pass
/opsx:apply                   # implement, ticking tasks as you go
/opsx:archive                 # merge deltas into openspec/specs/
```

- `/opsx:ff` for fast-forward instead of step-by-step review.
- Set `skip_specs: true` in a change's `.openspec.yaml` only when the change has
  no observable behaviour (refactors, dependency bumps, CI). Anything a player
  or another capability can observe needs a spec.
- Tick each task checkbox the moment it is done, not in a batch — solo project,
  nobody else can reconstruct where you stopped.
- Work the backlog in dependency order. Capability names are fixed in
  `openspec/BACKLOG.md`; do not invent new ones without adding them there.

## The constraints that get violated by accident

The full list of ten is in `openspec/config.yaml`. These are the ones most
easily broken by a reasonable-looking implementation:

1. **Auto-check ships OFF by default.** No lives, energy, session limits, or
   failure states. Mistake limits exist only in opt-in strict mode. Turning any
   of this on by default destroys the product's entire positioning.
2. **Notes are positional and never reflow.** Nine candidates per cell in fixed
   3×3 slots — 1 top-left, 5 centre, 9 bottom-right, always. Removing a
   candidate must not move the others.
3. **One colour, one job.** Eight colour tokens: six carry state — ink, focus,
   candidate, provisional, error, completion — and two are surfaces (D-71).
   Never add a ninth hue. Season themes repaint surfaces only. Colour is never
   the sole signal for a state.
4. **No ad ever interrupts a grid in progress**, and ad removal is absolute —
   the "zero ads under an active entitlement" test is a release blocker.
5. **Full offline play.** Network is only for ads, cloud save, leaderboards, and
   pack top-ups, each degrading gracefully. Nothing blocks first frame.
6. **Input latency under 100ms**; no in-puzzle effect over 400ms; no effect
   blocks the next tap.

## Vocabulary

The glossary in `openspec/project.md` is canonical. Use these exact terms in
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
play**. Read `openspec/project.md` rather than this summary when it matters
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

Full list in `openspec/project.md`. In short:

- `flutter analyze` clean; `dart format` enforced in CI.
- Feature-first layout: `lib/features/<capability>/`, kebab-case capability
  names becoming snake_case directories.
- No business logic in widgets — controllers and services own it.
- Keep the solver, generator, technique grader, and progression rules pure Dart
  with no Flutter import, so they are unit-testable in isolation.
- Comments explain *why*, never *what*.

**Testing.** Test-first is required for the load-bearing pure-logic systems.
`openspec/config.yaml` names them canonically under `rules.tasks` — read it
there rather than working from memory, and do not copy the list into another
file. Four partial copies once disagreed about which systems were on it. They
carry no Flutter import, and a silent bug in any of them corrupts saved player
progress. Golden tests for the eight colour tokens and their derived tints. A task is
done when its test passes **on both platforms**, not when it compiles; the
simulator lies about haptics and frame timing.

Do not report a green test run you did not observe. Report what failed and the
actual output.

## Documentation layout

Domain context lives in `openspec/project.md` and decisions in `docs/DECISIONS.md`.
The `mattpocock/skills` tooling wants to create `CONTEXT.md` and a `docs/adr/`
directory instead — **do not let it.** `openspec/config.yaml` redirects that
output at the existing files; if a `CONTEXT.md` or `adr/` appears, the redirect
is not landing and the installed skill file needs editing.

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
  latency profile has never been taken, and `add-season-map` added a second
  runner in the same position. Recorded
  against both `add-grid-and-input` and `add-completion-effects` in
  `openspec/BACKLOG.md`: measured on the host, an emulator, and a simulator
  only, with roughly 200× headroom against the 100 ms budget — but that is an
  inference, not the measurement the backlog asked for. A **cascade** is the
  heavier frame, so `integration_test/completion_effects_test.dart` on the first
  physical phone that comes to hand settles both — and
  `integration_test/season_map_test.dart` is the second thing to run in the same
  session. Record the number, and check
  the haptics by hand in the same session.

Resolved, kept here only so they are not re-opened: the Sheriff's retired
wrong-advice gag (D-39 → D-60) is gone from `docs/ART-BRIEF.md`, whose animation
table now matches the bible and `docs/SPEC.md` §6; `docs/SETUP.md` and
`docs/pages/screens.html` both exist.
