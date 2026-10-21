# Working on Doku Duty

How a change goes from an idea to a merged spec. Read this once; after that the
loop is three commands.

## The loop

```
   ┌─ idea is still loose ────────────────────────────────┐
   │  /grill-with-docs        settle it first             │
   │  → docs/DECISIONS.md (D-NN) + docs/GLOSSARY.md       │
   └──────────────────────────┬───────────────────────────┘
                              │ decisions settled
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │  PLAN     /propose-change <name>                     │
   │           → docs/changes/<name>/proposal.md, tasks.md│
   │           → spec edits in docs/specs/                │
   └──────────────────────────┬───────────────────────────┘
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │  BUILD    /apply-change                              │
   │           tick each checkbox as you finish it        │
   └──────────────────────────┬───────────────────────────┘
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │  CLOSE    /finish-change                             │
   │           review, backlog Done line, folder removed  │
   └──────────────────────────────────────────────────────┘
```

`docs/changes/<name>/` is temporary: the proposal and the task list, deleted
when the change finishes. `docs/specs/` is the permanent record of behaviour,
and a change edits it in place — the diff is the delta. The three commands are
project skills in `.claude/skills/`; the project moved off OpenSpec in D-135.

## Which document wins

They overlap on purpose, but only one is authoritative for each thing. When two
disagree, this table decides.

| Question | Authoritative source |
|---|---|
| What are we building, and why | `docs/IDEA.md` |
| What exactly does it do | `docs/specs/<capability>.md`, then `docs/SPEC.md` |
| Why is it that way | `docs/DECISIONS.md` — cite as `D-NN`, never re-argue |
| Colour, type, motion, haptic values | `docs/DESIGN.md` — newest and most precise |
| Character art and animation states | `docs/ART-BRIEF.md` |
| The ten constraints, platform requirements | `CLAUDE.md` |
| Tech stack | `docs/TECH_STACK.md` |
| Vocabulary | `docs/GLOSSARY.md` |
| What to build next, and in what order | `docs/BACKLOG.md` |
| Load-bearing systems that need test-first | `.claude/rules/testing.md` |
| Code and spec conventions | `.claude/rules/dart-code.md`, `.claude/rules/specs.md` |

`CLAUDE.md` is loaded on every turn, and each rule loads when a file under its
paths is touched. Everything else is read on request, so name the file when it
matters.

## Starting a change

**1. Pick from the backlog.** `docs/BACKLOG.md` is dependency-ordered across
six milestones. Take the lowest-numbered change whose dependencies are done. Do
not start later work because it sounds more fun — the ordering is the
schedule.

Each entry gives you the change name, its capability, the decisions it
implements, and a **Watch for** line naming the way that change usually goes
wrong. Read the Watch for line before you plan, not after.

**2. Check the decisions are settled.** Open the `D-NN` ids the backlog entry
cites. If the change needs a decision nobody has made, stop and run
`/grill-with-docs` as its own session first. Do not invent the decision inside
the proposal — a proposal is not where decisions get made.

**3. Propose.** `/propose-change add-perks`

**4. Read what it produced.**

| Artifact | Answers | Notes |
|---|---|---|
| `docs/changes/<name>/proposal.md` | Why now, what changes, what it will not do | One screen. The "Not doing" section is the scope guard |
| `docs/specs/<capability>.md` (edited) | What a player can observe | `MUST` + at least one `WHEN`/`THEN` scenario each |
| `docs/changes/<name>/tasks.md` | The build order | Atomic checkboxes, tests interleaved |

There is no design document. The proposal template carries its three questions
— grid performance, offline/cold-start/app-kill, and new dependency — answered
only where they apply.

**5. Build.** `/apply-change` works the list top to bottom. Tick each box as you
finish it, not in a batch at the end.

**6. Finish.** `/finish-change` checks every task is ticked and the specs match
what was built, reviews the diff against the ten constraints, records any
deviation as a `D-NN`, writes the backlog's **Done** line and the status in
`CLAUDE.md`, and removes the change folder.

## When to skip specs

A change where nothing a player or another capability can observe changes —
refactors, dependency bumps, CI work — edits no spec, and its proposal says so.
Anything observable needs a spec. When in doubt, write the spec; an unnecessary
requirement is cheaper than a capability with no record.

## Skills, and which ones you have to type yourself

This matters more than it looks. Roughly half cannot be invoked by the agent at
all — they are marked `disable-model-invocation`, so **you** type them. Asking
the agent to "run grill-with-docs" silently does nothing.

| You type | Agent can invoke |
|---|---|
| `/grill-with-docs` — settle a loose idea | `grilling` — the interview alone |
| `/handoff` — session getting long | `domain-modeling` — glossary discipline |
| `/to-spec`, `/to-tickets` | `research` — verify an external API claim |
| `/implement`, `/wayfinder` | `tdd` — failing test first |
| | `diagnosing-bugs` — before fixing anything |
| | `code-review` — before finishing a change |

Two rules that come from how these behave in practice:

- **Run `/grill-with-docs` on its own, before the change exists.** Nested inside
  another workflow it runs the interview but silently writes no files.
- **Its output goes to `docs/DECISIONS.md` and `docs/GLOSSARY.md`**, not the
  `CONTEXT.md` and `docs/adr/` it defaults to. `CLAUDE.md` redirects it. If a
  `CONTEXT.md` or `adr/` ever appears, move the content and delete it.

## Things that will bite you

- **The mattpocock skills live in the plugin cache, not this repo** —
  `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/`. Editing
  them is possible but a plugin update overwrites your edits. The three
  workflow skills (`propose-change`, `apply-change`, `finish-change`) are this
  repo's own, in `.claude/skills/`.
- **Capability names are permanent.** They become `docs/specs/<name>.md` and
  `lib/features/<name>/`, and the code cites them.
- **Code comments never cite `docs/changes/`.** The folder is deleted when the
  change finishes; cite the spec, the `D-NN`, or the backlog change number.
- **Archived OpenSpec changes are in git only.** Read one with
  `git show d5b7dc5:openspec/changes/archive/<dir>/proposal.md`; the backlog's
  **Done** lines name the directories.
