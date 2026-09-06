# Doku Duty

A free-to-play sudoku game for iOS and Android (Flutter, single codebase) with a
comedic frontier setting and a deliberately non-punitive design.

**Current state: documentation only.** There is no Flutter project, no `lib/`,
and no commits yet. The first change to implement is
`openspec/changes/setup-mobile-foundation` — every other backlog item depends on
it.

## Source of truth — read before proposing or implementing

| File | Holds |
|---|---|
| `docs/IDEA.md` | Product description, world, cast, business model |
| `docs/DECISIONS.md` | 70 numbered decisions (D-01 … D-70) with rationale |
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

**node, season, rank, unit, settled note, provisional note, auto-cleanup,
cabinet, strict mode**

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

- **`docs/pages/screens.html` still says five reserved colours** (§ palette).
  It is a generated mockup page that `docs/DESIGN.md` §9 already flags as
  pre-rename and needing regeneration, so it was left alone when D-71 fixed the
  count everywhere else. Regenerate it rather than hand-editing.
- **`docs/ART-BRIEF.md` gives the Sheriff the retired wrong-advice gag.** It
  describes him as "the comic counterweight … frequently wrong" and cites D-39,
  and its animation table assigns him "Unhelpful suggestion" and "Claims
  credit". D-60 retired that gag and D-58 makes him the boss who dispenses dry,
  grudging approval. **These cannot both ship.** Resolve before any character
  art is commissioned — this is the one open conflict in the documents.
- **Two referenced files do not exist:** `docs/SETUP.md` (linked twice from
  `README.md`) and `docs/pages/screens.html` (cited by `docs/SPEC.md` §0 and flagged in
  `docs/DESIGN.md` as pre-rename and needing regeneration anyway).
