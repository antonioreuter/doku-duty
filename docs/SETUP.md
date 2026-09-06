# Working on Doku Duty

How a change goes from an idea to merged specs. Read this once; after that the
loop is three commands.

## The loop

```
   ┌─ idea is still loose ────────────────────────────────┐
   │  /grill-with-docs        settle it first             │
   │  → docs/DECISIONS.md (D-NN) + glossary in project.md      │
   └──────────────────────────┬───────────────────────────┘
                              │ decisions settled
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │  PLAN     /opsx:propose <name>     (or /opsx:ff)     │
   │           → proposal.md · specs/ · tasks.md          │
   └──────────────────────────┬───────────────────────────┘
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │  BUILD    /opsx:apply                                │
   │           tick each checkbox as you finish it        │
   └──────────────────────────┬───────────────────────────┘
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │  MERGE    /opsx:archive                              │
   │           deltas fold into openspec/specs/           │
   └──────────────────────────────────────────────────────┘
```

Everything under `openspec/changes/<name>/` is temporary. `openspec/specs/` is
the permanent record, and archive is the only thing that writes to it. That is
the whole reason specs are worth keeping on a solo project.

## Which document wins

They overlap on purpose, but only one is authoritative for each thing. When two
disagree, this table decides.

| Question | Authoritative source |
|---|---|
| What are we building, and why | `docs/IDEA.md` |
| What exactly does it do | `docs/SPEC.md` |
| Why is it that way | `docs/DECISIONS.md` — cite as `D-NN`, never re-argue |
| Colour, type, motion, haptic values | `docs/DESIGN.md` — newest and most precise |
| Character art and animation states | `docs/ART-BRIEF.md` |
| The ten constraints | `openspec/config.yaml` (`context`) |
| Tech stack, conventions, glossary | `openspec/project.md` |
| What to build next, and in what order | `openspec/BACKLOG.md` |
| Load-bearing systems that need test-first | `openspec/config.yaml` (`rules.tasks`) |

Only `openspec/config.yaml` is injected automatically into every artifact
prompt. Everything else is read on request, so name the file when it matters.

## Starting a change

**1. Pick from the backlog.** `openspec/BACKLOG.md` is dependency-ordered across
six milestones. Take the lowest-numbered change whose dependencies are done. Do
not start Milestone 2 work because it sounds more fun — the ordering is the
schedule.

Each entry gives you the change name, its capability, the decisions it
implements, and a **Watch for** line naming the way that change usually goes
wrong. Read the Watch for line before you plan, not after.

**2. Check the decisions are settled.** Open the `D-NN` ids the backlog entry
cites. If the change needs a decision nobody has made, stop and run
`/grill-with-docs` as its own session first. Do not invent the decision inside
the proposal — a proposal is not where decisions get made.

**3. Propose.**

```bash
/opsx:propose add-notes        # step-by-step
/opsx:ff add-notes             # same artifacts, one pass, no review gate
```

Use `ff` when the change is well understood and you want momentum. Use
`propose` when you want to read each artifact as it lands.

**4. Read what it produced.** Three files:

| Artifact | Answers | Notes |
|---|---|---|
| `proposal.md` | Why now, what changes, what it will not do | One screen. The "Not doing" section is the scope guard |
| `specs/<capability>/spec.md` | What a player can observe | `MUST` + at least one `WHEN`/`THEN` scenario each |
| `tasks.md` | The build order | Atomic checkboxes, tests interleaved |

There is no `design.md`. `doku-lite` folds its questions into the proposal
template as three prompts — grid performance, offline/cold-start/app-kill, and
new dependency — that you answer only where they apply.

**5. Build.** `/opsx:apply` works the list top to bottom. Tick each box as you
finish it, not in a batch at the end.

**6. Archive.** `/opsx:archive` merges the delta into `openspec/specs/`.

## When to skip specs

Set `skip_specs: true` in the change's `.openspec.yaml` when nothing a player or
another capability can observe changes — refactors, dependency bumps, CI work.
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
| | `code-review` — before archive |

Two rules that come from how these behave in practice:

- **Run `/grill-with-docs` on its own, before the change exists.** Nested inside
  a spec-driven workflow it runs the interview but silently writes no files.
- **Its output goes to `docs/DECISIONS.md` and `openspec/project.md`**, not the
  `CONTEXT.md` and `docs/adr/` it defaults to. `openspec/config.yaml` redirects
  it. If a `CONTEXT.md` or `adr/` ever appears, the redirect stopped working.

## Things that will bite you

- **`/opsx:verify` does not exist here.** The installed workflows are `propose`,
  `explore`, `apply`, `ff`, `sync`, `archive`. Add more with
  `openspec config set workflows '[...]'` then `openspec update`.
- **The skills live in the plugin cache, not this repo** —
  `~/.claude/plugins/cache/claude-plugins-official/mattpocock-skills/`. Editing
  them is possible but a plugin update overwrites your edits.
- **`rules:` in `openspec/config.yaml` must be a list of strings.** Write it as
  a `|` block and OpenSpec silently discards every rule. Run any `openspec`
  command and check for `must be an array of strings` warnings after editing.
- **Capability names are permanent.** They become `openspec/specs/<name>/` and
  `lib/features/<name>/`. Rename before the first archive or not at all.
- **The colour count is stated inconsistently** across `docs/DESIGN.md`, `docs/SPEC.md`,
  `docs/DECISIONS.md`, and the config. `docs/DESIGN.md` wins. Reconcile the others before
  `add-design-system` is built.

## Checking the setup is sound

```bash
openspec doctor                      # root health
openspec schema validate doku-lite   # schema and templates
openspec list                        # active changes
openspec context                     # watch for parse warnings
```

Zero warnings from `openspec context` is the signal that your rules are actually
reaching the agent rather than being dropped.
