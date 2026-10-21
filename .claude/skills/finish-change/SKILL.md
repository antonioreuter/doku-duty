---
name: finish-change
description: Close out a completed Doku Duty change — verify tasks and specs against what was built, review the diff against the ten constraints, record decisions, update the backlog and CLAUDE.md status, and remove the change folder. Use when the user wants to finish, archive, close, or wrap up a change.
argument-hint: "[change-name]"
---

# Finish a change

Run these in order. Stop and report at the first one that fails — do not paper
over it.

1. **Every task is ticked** in `docs/changes/<name>/tasks.md`. If one is not,
   list it and stop. An unticked platform check is not done because the code
   compiles; if it genuinely cannot be taken (no device), it is recorded as
   **OUTSTANDING** on the backlog entry, never silently ticked.

2. **The specs describe what was built, not what was intended.** Re-read the
   `docs/specs/` sections this change touched against the code. Where they
   diverged, fix the spec now. Check any new term landed in `docs/GLOSSARY.md`.

3. **Review the diff.** Invoke `mattpocock-skills:code-review` over the
   change's commits, and check it against the ten constraints in `CLAUDE.md`
   specifically. Constraint 7 (ad removal is absolute), constraint 9 (note
   state written on every change) and constraint 2 (input latency under 100ms)
   pass review unnoticed, because none shows a symptom in a diff unless
   someone is looking for it. Check that any new hook has a production caller
   and a test that drives it through the real wiring.

4. **Record deviations.** Any deliberate departure from the proposal becomes
   the next `D-NN` in `docs/DECISIONS.md` with its rationale, so the reason
   outlives the change folder. Decisions are never edited away — a replaced one
   gains `> **Superseded by D-NN**`.

5. **Update the record.**
   - `docs/BACKLOG.md`: give the item a **Done** line (date, and the commit once
     it exists), carry any **OUTSTANDING** device verification, and update the
     Status block and milestone table.
   - `CLAUDE.md`: the *Current state* paragraph, the decision count, the
     vocabulary list if terms were added, and the hardware-debt list if a new
     integration runner was added.

6. **Remove `docs/changes/<name>/`.** Git keeps it. Then offer to commit;
   commit only if asked.
