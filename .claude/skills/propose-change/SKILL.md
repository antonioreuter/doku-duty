---
name: propose-change
description: Plan a Doku Duty backlog change — write its proposal and tasks under docs/changes/<name>/ and edit the affected specs in docs/specs/. Use when the user wants to start, plan, or propose the next change, or names a change from docs/BACKLOG.md.
argument-hint: "<change-name>"
---

# Propose a change

Planning only. Do not edit `lib/` or tests in this skill. When the artifacts are
written, stop and let the developer review; implementation is `apply-change`.

## 1. Pick and check

- Take the change from `docs/BACKLOG.md`: the name given, or else the
  lowest-numbered item whose dependencies are done. Read its entry in full —
  **Capabilities**, **Depends on**, and above all **Watch for**, which names
  how that change usually goes wrong. Read it before planning, not after.
- Open every `D-NN` it cites in `docs/DECISIONS.md`. Read
  `docs/doku-duty-game-bible.md` before proposing anything that touches play,
  progression or effects, and the current `docs/specs/<capability>.md` for each
  capability it touches.
- **Open decisions stop the proposal.** If the idea still has decisions that
  would change scope, do not guess them in. Invoke `mattpocock-skills:grilling`
  and settle them with the developer, then record each durable one as the next
  `D-NN` in `docs/DECISIONS.md` with a rationale paragraph.
- If the session would produce a new glossary term or a hard-to-reverse,
  surprising trade-off, recommend the developer run `/grill-with-docs` **as its
  own session, before this change exists**, and stop. You cannot invoke it
  (it is `disable-model-invocation`). Nested inside another workflow it
  interviews but silently writes nothing. Its output must land in
  `docs/GLOSSARY.md` and `docs/DECISIONS.md`, never the `CONTEXT.md` and
  `docs/adr/` it defaults to.

## 2. Write `docs/changes/<name>/proposal.md`

Use [templates/proposal.md](templates/proposal.md). **One screen**, not a
document. In order: why now (two or three sentences), what changes (a list,
behaviour not implementation), which of the ten constraints in `CLAUDE.md` it
touches and how it stays within them, technical notes, and **Not doing** —
always present, because scope creep is the delivery risk.

Cite `D-NN` ids; never re-argue a settled decision.

Technical notes answer only the template's three questions, only where they
apply:

- **External API facts.** The stack leans on Rive, Drift, RevenueCat, AppLovin
  MAX with AdMob, AWS (Cognito, DynamoDB, S3 behind CloudFront) and Sentry.
  `docs/TECH_STACK.md` is canonical and §7 names the entries most likely to have
  moved. Never assert what one of them does from memory — invoke
  `mattpocock-skills:research` and cite what it finds. Version numbers too:
  confirm them at implementation time; the newest Drift once produced an
  Android app that could not open its database (D-77).
- **New dependency.** Before answering anything but "none", invoke
  `mattpocock-skills:codebase-design` and argue why an existing dependency will
  not do.
- **Native code.** The test host links the machine's own libraries, so a
  library missing from the APK or IPA is invisible to every unit test. When a
  change adds or moves one, say how it will be verified on a device, and put
  that check in the tasks.

## 3. Edit the specs in place

For every observable behaviour, edit `docs/specs/<capability>.md` directly
(new capability → new file, named from the backlog). The rules in
`.claude/rules/specs.md` apply. If nothing a player or another capability can
observe changes — refactor, dependency bump, CI — write no spec and say so in
the proposal under **Capabilities**.

New vocabulary goes into `docs/GLOSSARY.md` in the same pass.

## 4. Write `docs/changes/<name>/tasks.md`

Use [templates/tasks.md](templates/tasks.md).

- Atomic and independently verifiable: one file or one coherent unit of
  behaviour each, ordered so the app stays runnable after every task.
- Tests interleaved, not appended. For the test-first systems listed in
  `.claude/rules/testing.md` (read the list there, not from memory), the
  failing-test task comes before the task that satisfies it — invoke
  `mattpocock-skills:tdd` to shape that ordering.
- An explicit iOS check and Android check for anything touching platform
  behaviour; an accessibility task wherever colour, motion or haptics are
  involved; a task that drives any new hook through the production wiring.
- Keep tasks in `tasks.md`. Do not produce a parallel ticket list
  (`/to-tickets`) unless the developer asks.

## 5. Stop

Summarise what was written and any decision recorded, and wait.
