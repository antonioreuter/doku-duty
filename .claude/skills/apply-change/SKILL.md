---
name: apply-change
description: Implement a planned Doku Duty change by working through docs/changes/<name>/tasks.md top to bottom, ticking each task as it is done. Use when the user wants to implement, build, continue, or resume a change.
argument-hint: "[change-name]"
---

# Apply a change

1. **Find the change.** Use the name given; otherwise the single folder under
   `docs/changes/`. If there are several, ask which. Read `proposal.md`,
   `tasks.md`, and the `docs/specs/` files the proposal names. Resume from the
   first unticked task.

2. **Work top to bottom.** Tick each checkbox in `tasks.md` **the moment its
   task is done**, not in a batch — a solo project has no one else to
   reconstruct where you stopped. A task is done when its test passes on both
   platforms, not when it compiles (`.claude/rules/testing.md`).

3. **Skills, at the moments they apply:**
   - A test-first task in one of the load-bearing systems listed in
     `.claude/rules/testing.md`: invoke `mattpocock-skills:tdd` and let the
     failing test drive the shape.
   - Before changing anything in the puzzle engine or notes logic, or when
     stuck on a defect for more than one attempt: invoke
     `mattpocock-skills:diagnosing-bugs` rather than editing speculatively.
     Repeated guesses at the grid renderer or the notes model are how input
     latency and note persistence (constraint 9) regress without anyone
     noticing which edit did it.

4. **Code and spec disagree → stop and ask.** Change the spec deliberately,
   never let the code quietly become the spec. If a decision turns out wrong,
   amend `docs/DECISIONS.md` first, then `docs/specs/`, then the code.

5. **Long session.** When context is getting long, stop and tell the developer
   to run `/handoff` pointed at `docs/changes/<name>/`. You cannot invoke it.

6. When every task is ticked, say so and suggest `finish-change`. Do not
   commit unless asked.
