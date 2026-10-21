# Skills review — Matt Pocock skills, pstack, and what else to add

*Written 2026-10-21, right after OpenSpec was removed (D-135). Sections 1–3 review the skills; section 4 is the configuration strategy and rollout.*

**Recommendation in one line:** keep using most of the Matt Pocock skills you
already have. Don't install pstack as a whole; it brings its own workflow, which
would be a third system on top of `/propose-change`, `/apply-change` and
`/finish-change`. Take two of its ideas and build them here instead.

---

## 1. Matt Pocock skills (installed, version 1.3.1)

### A problem caused by the 1.3.1 update

Version 1.3.1 renamed its glossary file from `CONTEXT.md` to `GLOSSARY.md`, and
it looks for that file at the **repo root**. `tdd` and `diagnosing-bugs` say
"read `GLOSSARY.md` (if it exists)", and they skip silently when it's missing. So
they never see `docs/GLOSSARY.md`.

Two cheap fixes:

1. **Move `docs/GLOSSARY.md` to `/GLOSSARY.md`.** All the skills then find it
   with no redirect. The redirect in `CLAUDE.md` is then only needed for
   decisions, because the skills still want one file per decision in `docs/adr/`
   rather than the single `docs/DECISIONS.md`.
2. **Write `docs/agents/domain.md` and `docs/agents/issue-tracker.md` by hand.**
   This folder is where the setup skill stores the per-repo settings the other
   skills follow. Point the issue tracker at `docs/BACKLOG.md` and
   `docs/changes/<name>/`. Then `code-review`'s spec check finds the proposal
   and specs instead of asking where the spec is.

   Don't run `/setup-matt-pocock-skills` itself: its "local markdown" choice puts
   work in `.scratch/`, which would compete with `docs/changes/`.

### How each skill fits this project

| Use | Skills | Where it fits |
|---|---|---|
| Already in the workflow | `grilling`, `/grill-with-docs`, `tdd`, `diagnosing-bugs`, `research`, `codebase-design`, `code-review`, `domain-modeling`, `/handoff` | Already wired into the three workflow skills |
| **Start using** | `wizard` | Writes a step-by-step script for things only you can do. Good for the device session (turning on Developer Mode, finding device IDs, running the device tests in order), and later for setting up RevenueCat, Cognito and store signing (changes 26, 28, 34) |
| **Start using** | `prototype` | A throwaway screen or state model to try perks and chest openings before the proposal locks them in |
| **Start using** | `/retro` | After each `/finish-change`. The `wire-completion-events` lesson in CLAUDE.md is the kind of thing a retro catches |
| **Start using** | `/improve-codebase-architecture` | 22 changes in, a pass looking for messy wiring between modules, such as the completion hooks |
| **Start using** | `git-guardrails-claude-code` | Blocks `push`, `reset --hard` and similar commands. Worth having, since commits go straight to `main` |
| Later | `/wayfinder` | Milestone 4 (ads, purchases, auth, sync) has many open decisions that span several sessions |
| Skip | `to-spec`, `to-tickets`, `implement`, `implement-spec`, `triage` | They duplicate `docs/changes/` and `tasks.md` |
| Skip | `setup-pre-commit`, `migrate-to-shoehorn`, `setup-ts-deep-modules`, `scaffold-exercises` | Built for Node or TypeScript projects |

User-only skills (marked `disable-model-invocation`) still have to be typed by
you: `/grill-with-docs`, `/handoff`, `/retro`, `/improve-codebase-architecture`,
`/wayfinder`.

---

## 2. pstack

pstack is Lauren Tan's (poteto) Cursor skill pack, ported to Claude Code by
michael-denyer:

```
/plugin marketplace add michael-denyer/pstack-claude
/plugin install pstack@pstack-claude
```

Its entry point, `/poteto-mode`, picks a set procedure for each task. That would
compete with the project's three workflow skills and with `diagnosing-bugs`. It
is also third-party code — read it before installing.

### Worth taking

- **`/create-verification-skill` — the most valuable idea for this project.** It
  generates a project skill that knows how to launch the app, play through
  features and capture evidence. Here that means a `verify-doku-duty` skill:
  launch the `dev` build (`flutter run --flavor dev -t lib/main_dev.dart`), play
  a puzzle to the end through the real app, and run the 16 device tests under
  `integration_test/`. That targets the two biggest risks: code the running app
  never calls, and tests that have never run on a physical phone.
- **`/blast-radius`** — checks what a change could break outside its own diff.
  Worth it for persistence and notes changes, where breaking saved games shows
  no symptom (constraint 9), and for Drift migrations.
- **`/why`** — searches git history for the reasons behind code. More useful now
  that the archived OpenSpec changes live only in git
  (`git show d5b7dc5:openspec/changes/archive/<dir>/proposal.md`).

### Avoid or skip

- **Avoid `/no-comments`.** It strips comments before review, which goes against
  the rule that comments explain *why* and every public API is documented.
- **Skip `/arena`, `/swarm`** — expensive multi-model runs, little gain for a
  solo project.
- **Skip `/show-me-your-work`** — its decision log duplicates ticking `tasks.md`.

---

## 3. Other suggestions

*First pass. Section 4 replaces these with worked-out versions — read that
rather than this where they differ.*

1. **A `device-session` skill** (or the `verify-doku-duty` skill above). Runs
   every device test on attached phones, records the numbers in
   `docs/BACKLOG.md` and `docs/PERFORMANCE.md`, and lists the haptics checks to
   do by hand. Clears the largest outstanding item in one sitting.
2. **Hooks rather than reminders**, because a hook always runs:
   - block any write to `CONTEXT.md` or `docs/adr/`;
   - run `dart format` after edits;
   - reject edits to `docs/DECISIONS.md` that delete lines — decisions are never
     edited away.
3. **A vocabulary test** (`test/vocabulary_test.dart`) that fails if a banned
   word appears in identifiers under `lib/` or `test/`: "box", "level",
   "pencilMark", "difficulty", "coin". A test enforces it every run; a skill only
   applies when it's invoked.
4. **The Dart and Flutter MCP server** (`dart mcp-server`, built into Dart 3.9+;
   this machine has 3.12). It lets Claude run the analyzer and tests,
   hot-reload, and inspect the widget tree of the running app — what a
   verification skill needs to drive. Strictly a tool connection, not a skill.

## 4. Strategy — configuring the project for these skills

### 4.1 What I checked first

Before proposing anything I read the installed skills rather than working from
their descriptions. Five facts shape everything below:

1. **`tdd` and `diagnosing-bugs` read `GLOSSARY.md` at the repo root** and skip
   silently if it is missing. Today it is at `docs/GLOSSARY.md`, so they never
   see it.
2. **`domain-modeling` writes in its own formats**: the glossary as
   `**Term**:` + one-or-two-sentence definition + `_Avoid_:` line, and
   decisions as one file each in `docs/adr/NNNN-slug.md`. `/grill-with-docs` is
   nothing but `grilling` + `domain-modeling`, so it inherits both. The project
   uses a table glossary and a single `docs/DECISIONS.md` with `D-NN` entries.
3. **`code-review` looks for the spec** in commit messages, then a path you
   pass, then `docs/`, `specs/` or `.scratch/` matching the branch name. Commits
   go straight to `main` here, so the branch-name match never fires. It looks
   for **standards** by searching for files that document how code is written,
   with `CODING_STANDARDS.md` and `CONTRIBUTING.md` named explicitly. It does
   not know about `.claude/rules/`.
4. **`/retro` has a clear view of where rules belong**: mechanical rules become
   deterministic checks (tests, hooks, CI); judgement calls go in
   `CODING_STANDARDS.md`, read at review time; `CLAUDE.md` holds navigation
   pointers only, "used incredibly sparingly". This repo's `CLAUDE.md` is
   ~16 KB.
5. **The repo already enforces rules with tests.** There are
   `no_flutter_import_test.dart` files per feature and
   `design_system/no_stray_colours_test.dart`. CI runs `dart format`,
   `flutter analyze`, `flutter test` and both platform builds. There are no
   git hooks and no Claude Code hooks.

`prototype`'s UI branch and `setup-pre-commit` assume a web or Node project
(`pnpm`, URL routes, Husky). They need adapting or skipping.

The pstack descriptions here come from its README and two write-ups, not from
reading its source. Treat its details as second-hand until you read the repo.

### 4.2 Principles

1. **One spine.** `/propose-change`, `/apply-change`, `/finish-change` stay the
   only workflow. Every other skill is called *at a named stage inside it*.
   Nothing gets a second entry point — that rules out pstack's `/poteto-mode`
   and Matt Pocock's `to-spec` / `to-tickets` / `implement`.
2. **Make the skills' assumptions true instead of fighting them in prose.**
   Where a skill reads a fixed path, meet it there. Where its assumption can't be
   met (ADR files versus `D-NN`), enforce with a hook — a CLAUDE.md paragraph
   asking a skill to ignore its own instructions is a request, a hook is a wall.
3. **Each rule lives in exactly one layer:**

   | Kind of rule | Layer | Why |
   |---|---|---|
   | Mechanical (a banned word, an import, a file location) | Test, hook, or CI | Runs every time, no model needed |
   | Needed *while writing* a kind of file | `.claude/rules/` (path-scoped) | Loads only when that file is touched |
   | Judgement call, checked on the diff | `CODING_STANDARDS.md` | What `code-review` reads |
   | Where things are | `CLAUDE.md` | On every turn, so keep it small |
   | A procedure with steps | Skill | Description in context, body on demand |

   One canonical copy per rule; every other place points at it. The project has
   already been burned by four copies of the test-first list disagreeing.
4. **Spend new effort where the gap is.** Planning and review are well covered
   by existing skills. Verifying the *running app* — on a phone, through the
   production wiring — is not covered by anything, and it is the project's
   largest standing debt.

### 4.3 The workflow, stage by stage

```
 0. DECIDE   loose idea
             /grill-with-docs ─► GLOSSARY.md (root) + next D-NN in docs/DECISIONS.md
             prototype (optional) ─► throwaway branch, verdict recorded as D-NN
                     │
 1. PLAN     /propose-change <name>
             ├ research            external API or version facts
             ├ codebase-design     any new dependency or structural call
             └ impact-check  NEW   change touches persistence, notes, or a schema
                     │
 2. BUILD    /apply-change
             ├ tdd                 the test-first systems
             ├ diagnosing-bugs     engine or notes edits; any second failed attempt
             └ verify-app    NEW   before ticking a behaviour or platform task
                     │
 3. CLOSE    /finish-change
             ├ code-review         standards (CODING_STANDARDS.md) + spec (proposal + specs)
             ├ constraint-reviewer NEW subagent, third axis: the ten constraints
             └ suggest /retro      you type it
                     │
 OFF-CYCLE   /device-session NEW   whenever a physical phone is at hand
             /improve-codebase-architecture   once per milestone
             /wayfinder            planning Milestone 4
             /handoff              any long session
```

### 4.4 Configuration — making the installed skills see this repo

**a. Move the glossary to the repo root, in the skills' format.**
`docs/GLOSSARY.md` → `/GLOSSARY.md`, converted from the table to
`**Term**:` / definition / `_Avoid_:`. Conversion matters, not just the move:
once `domain-modeling` adds terms in its format, a table glossary becomes half
table, half list. The `_Avoid_:` line is also the natural home for the banned
words — "box" under **Unit**, "level" under **Node** and **Rank**, "pencil
mark" under **Settled note**, "coin / gem / token" under **Stamp** — so the
glossary itself carries the rule.

*Trade-off:* the format asks for one-or-two-sentence definitions with no
implementation detail. Several entries are longer and carry behaviour (e.g.
**Current node**, **Notes lesson**). Keep the `D-NN` references; move any
behaviour that is really a requirement into the matching `docs/specs/` file,
where it belongs anyway.

**b. Add `docs/agents/` and an `## Agent skills` block in CLAUDE.md** — the
setup skill's own convention, written by hand rather than by
`/setup-matt-pocock-skills` (whose local tracker uses `.scratch/`):

- `docs/agents/issue-tracker.md` — "issues" are `docs/BACKLOG.md` items; a spec
  for work in progress is `docs/changes/<name>/proposal.md` plus the
  `docs/specs/` files it names; a "ticket" is a task in
  `docs/changes/<name>/tasks.md`. No GitHub issues.
- `docs/agents/domain.md` — single context; glossary at `/GLOSSARY.md`;
  **decisions are `### D-NN · Title` entries appended to `docs/DECISIONS.md`
  with a Rationale and a "What breaks if reversed" paragraph, never edited away,
  replaced ones marked `> **Superseded by D-NN**`.** This is also where the
  decision format gets written down once, so no `record-decision` skill is
  needed.

**c. Add `CODING_STANDARDS.md` at the root, as an index plus a review list.**
It should not repeat the rules. It points to `.claude/rules/*.md` and the ten
constraints in `CLAUDE.md`, and adds only what is checked *on a diff*:

- every new hook, provider or service has a production caller, and a test
  drives it through the real wiring (`production_solve.dart`);
- no comment cites `docs/changes/`;
- glossary terms in new identifiers and test names;
- a native dependency comes with a stated on-device check.

`code-review`'s standards axis then finds everything through one file.

**d. Pass `code-review` its inputs explicitly from `/finish-change`**: the fixed
point is the commit before the change's first commit, and the spec is
`docs/changes/<name>/proposal.md` plus the touched `docs/specs/` files. That
removes the branch-name guess, which can't work when committing to `main`.

**e. Slim CLAUDE.md** (optional, but `/retro` will flag it every time). Keep
navigation, the ten constraints, the vocabulary pointer, and current state.
Move "Known inconsistencies" and the hardware-debt narrative to
`docs/BACKLOG.md`'s status block, where they already half-live. Target: under
8 KB.

### 4.5 Guardrails to build (deterministic)

**Claude Code hooks** in `.claude/settings.json`, each a small script under
`tool/hooks/`:

| Hook | Event | Does |
|---|---|---|
| `guard-doc-layout` | PreToolUse on Write/Edit | Blocks any path matching `CONTEXT.md`, `GLOSSARY-MAP.md`, `docs/adr/**`, `docs/GLOSSARY.md`. Exit code 2 with the message "Decisions are D-NN entries in docs/DECISIONS.md; the glossary is /GLOSSARY.md". The message steers the model, so `domain-modeling` lands in the right place without being edited |
| `guard-decisions` | PreToolUse on Edit/Write of `docs/DECISIONS.md` | Blocks an edit that removes any existing line. Appending and inserting a Superseded marker still pass |
| `format-dart` | PostToolUse on Write/Edit of `*.dart` | `dart format` on the touched file. CI enforces format; this stops the round-trip |

**Tests**, following the repo's existing `no_flutter_import_test` pattern:

- `test/vocabulary_test.dart` — fails on banned words in identifiers and test
  names under `lib/` and `test/`, reading the `_Avoid_:` lines straight from
  `GLOSSARY.md`, so the glossary is the single source of the ban list.
- `test/no_change_folder_citations_test.dart` — fails if any file under `lib/`,
  `test/` or `integration_test/` mentions `docs/changes/`.

**Git:** install `git-guardrails-claude-code` (from the Matt Pocock pack) to
block `push --force`, `reset --hard`, `clean`, `branch -D`. Skip
`setup-pre-commit`; it is Husky and Prettier. If you want a pre-commit at all,
the Claude hook plus CI already cover format and analysis.

### 4.6 New skills and agents — the gaps

Four additions. Each one either fills a gap nothing covers or combines existing
skills into one step the spine can call. Every other candidate I considered
(`record-decision`, a `status` skill, a pstack-style decision log) is better
served by a config file, CLAUDE.md, or `tasks.md`, which already exist.

**1. `verify-app` — model-invocable skill.**
*Combines:* pstack's verification-skill pattern + the built-in `run` skill +
`test/features/grid_input/support/production_solve.dart`.
*Fills:* "a service with passing tests and no production caller is
indistinguishable from a working one until someone plays the app."
*Holds:* how to launch each flavour
(`flutter run --flavor dev -t lib/main_dev.dart`); a feature map from each
`docs/specs/<capability>.md` to the integration runner or flow that exercises
it; how to capture evidence (screenshot, runner output, timings); what a
simulator cannot prove (haptics, frame timing) so it never claims them.
*Called by:* `/apply-change` before ticking any behaviour or platform task; and
as the feedback loop inside `diagnosing-bugs`, which needs a way to reproduce a
bug and this gives it one.
*Maintenance:* `/finish-change` adds a line to the feature map when a change
adds a capability or a runner, so it never goes stale.

**2. `device-session` — user-invoked skill (`disable-model-invocation: true`).**
*Combines:* `wizard` + `verify-app` + the OUTSTANDING notes in
`docs/BACKLOG.md`.
*Fills:* the hardware debt, which needs a human with a phone.
*Does:* a `wizard`-generated script (`tool/device_session.sh`) walks you through
the steps only you can do — turn on Developer Mode, trust the computer, read the
device id. The skill then runs every runner under `integration_test/` on each
device with `--flavor dev`, prints a checklist for the by-hand checks (haptics;
killer's 8.3 px notes and 8 px cage sums on the smallest phone, D-129), and
writes the numbers into `docs/PERFORMANCE.md` and the OUTSTANDING lines in
`docs/BACKLOG.md`. User-only because it can't do anything without you holding
the phone.

**3. `impact-check` — model-invocable skill.**
*Combines:* pstack's `/blast-radius` idea + `codebase-design` + the Drift
schema snapshots in `drift_schemas/`.
*Fills:* constraint 9 and saved-game compatibility, which show no symptom in a
diff.
*Does:* for a change touching `persistence`, notes, the mistake model or any
Drift table: list every caller of the touched code; confirm a schema bump has a
migration and a migration test against the previous snapshot in
`drift_schemas/`; confirm every note-state write path is still on-change and
awaited; write findings into the proposal's Technical notes.
*Called by:* `/propose-change` when the backlog entry's capability is one of
those, and again by `/finish-change` on the real diff.

**4. `constraint-reviewer` — subagent (`.claude/agents/constraint-reviewer.md`),
read-only tools.**
*Combines:* `code-review`'s separate-axes design + the ten constraints.
*Fills:* `code-review` checks standards and spec; neither axis is the product's
invariants, and constraints 2, 7 and 9 are invisible in a diff unless someone
looks for them.
*Does:* given the diff, walks the ten constraints one by one and reports per
constraint: touched / not touched / at risk, quoting the hunk. Runs in parallel
with `code-review`'s two axes, reported separately — the same reason
`code-review` keeps its two axes apart.
*Why a subagent and not a skill:* it should run in a fresh context with only the
diff, like `code-review`'s own reviewers.

**Changes to the three spine skills** to wire these in:

- `propose-change`: call `impact-check` for the listed capabilities; offer
  `prototype` when a UI or state question is still open. For UI, adapt the
  skill: a dev-flavour-only `go_router` route with switchable variants, kept on
  a throwaway branch.
- `apply-change`: call `verify-app` before ticking behaviour and platform tasks.
- `finish-change`: pass `code-review` its fixed point and spec; run
  `constraint-reviewer` alongside it; re-run `impact-check` where it applied;
  update `verify-app`'s feature map; end by suggesting `/retro`.

### 4.7 MCP

Add the **Dart and Flutter MCP server** (`dart mcp-server`, Dart 3.9+; this
machine has 3.12 — confirm the exact command when adding it). It gives
`verify-app` and `diagnosing-bugs` the analyzer, test runs, hot reload and the
widget tree of the running app. It is a tool connection, configured in
`.mcp.json`, not a skill.

### 4.8 What not to do

- **Don't install pstack's router or Matt Pocock's ticket flow** — two more
  entry points for the same job.
- **Don't fork or edit plugin skills.** They live in the plugin cache and an
  update overwrites them. Hooks, `docs/agents/` and the spine skills adapt them
  from outside.
- **Don't add a skill where a file or a test would do.** Each skill's
  description costs context on every turn.
- **Don't copy a rule into a second place.** Point at the canonical one.

### 4.9 Rollout

Ordered so each step is useful on its own, and the cheap structural fixes come
before anything that depends on them.

| # | Step | Effort | Depends on |
|---|---|---|---|
| 1 | Glossary to `/GLOSSARY.md` in the skills' format; update paths in CLAUDE.md, rules, spine skills, SETUP.md | Small | — |
| 2 | `docs/agents/domain.md`, `docs/agents/issue-tracker.md`, `## Agent skills` block | Small | 1 |
| 3 | Hooks: `guard-doc-layout`, `guard-decisions`, `format-dart` | Small | 1 |
| 4 | `CODING_STANDARDS.md` index + review list | Small | — |
| 5 | `vocabulary_test.dart`, `no_change_folder_citations_test.dart` | Small | 1 |
| 6 | `git-guardrails-claude-code` | Trivial | — |
| 7 | `constraint-reviewer` subagent; wire into `finish-change` with explicit `code-review` inputs | Medium | 4 |
| 8 | Dart MCP server | Trivial | — |
| 9 | `verify-app` skill; wire into `apply-change` | Medium | 8 |
| 10 | `device-session` skill + wizard script | Medium | 9, a phone |
| 11 | `impact-check` skill; wire into `propose-change` and `finish-change` | Medium | — |
| 12 | Slim CLAUDE.md | Small | 2, 4 |

Steps 1–6 are one sitting and change no app behaviour. Steps 7–11 are worth
doing before `add-perks`, so change 19 is the first change through the complete
loop. Run `/retro` after it to see what still leaks.

### 4.10 Decisions for you before starting

1. **Convert the glossary format?** Recommended: yes. The alternative keeps the
   table and accepts a mixed file the first time `domain-modeling` adds a term.
2. **Slim CLAUDE.md?** Recommended: yes, after steps 2 and 4 give its content
   somewhere to go.
3. **Record this setup as D-136?** It changes how decisions and vocabulary are
   written, so by the project's own rule it probably qualifies.

---

## Sources

- [GitHub – michael-denyer/pstack-claude](https://github.com/michael-denyer/pstack-claude)
- [A deep dive into pstack – Flavio Copes](https://flaviocopes.com/pstack/)
- [pStack Skills – MindStudio](https://www.mindstudio.ai/blog/pstack-claude-code-skills-engineering)
- Matt Pocock skills as installed, read directly:
  `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/1.3.1/` —
  `domain-modeling` (and its `ADR-FORMAT.md`, `GLOSSARY-FORMAT.md`),
  `setup-matt-pocock-skills` (and its `domain.md`, `issue-tracker-local.md`),
  `code-review`, `retro`, `prototype`, `handoff`, `grill-with-docs`, `tdd`,
  `diagnosing-bugs`
