# add-trophy-cabinet

## Why

The **cabinet** is the permanent layer of D-17's three and the last one
unbuilt — seasonal and daily both ship. `docs/SPEC.md` §5.1 calls it the
retention engine: the map creates urgency, the cabinet creates sunk cost, and
without it a **season** rotating out reads as loss rather than as a fresh start.
It also closes two seams already written and tested as deliberately empty: a
**boss node** completes and files nothing (`add-season-map`), and a perfect
month files nothing (`add-daily-challenge`).

## What changes

- A **cabinet**, reached from the navigation beside **trail**, **daily**, and
  **free play**.
- A **trophy** is **minted when earned** — a row capturing what it was and which
  **season** it came from — rather than derived. **New decision, D-124.**
- A **season** declares its own **award**s in the published document, alongside
  its **node**s and its palette, with a compiled-in fallback. **New decision,
  D-125.**
- Unearned **award**s of the **season** in force show as **unfiled**, never
  hidden (D-21).
- A **trophy** earned in a **season** that has since rotated out keeps its name
  and its territory, because both were captured at the moment of minting.
- Lifetime and per-technique statistics, read from the counters that already
  exist rather than recounted.
- `LessonsScreen` is reparented into the **cabinet** and its settings row
  removed. `docs/SPEC.md` §5.1 put it here; change 13 built it self-contained
  and its own doc comment says "Reparented by change 16".
- The **boss node** and perfect-month seams are filled: both now mint.

## A framing that landed mid-planning

**D-119 … D-123 were written into `docs/DECISIONS.md` after this proposal was
drafted**, and D-119 names the **cabinet** three times: a **season** ending is
"the case *closing*, filed to the **cabinet**", rotation reads as an episode
ending, and "the **cabinet** becomes the series so far".

That does not change what this builds, and it is worth saying why rather than
leaving the next reader to work it out. `docs/NARRATIVE-PROPOSAL.md` §7 assigns
the narrative work to **change 20** (`add-character-system`, which owns the
reaction table the act dimension is added to) and **change 22**
(`add-running-gags`), and says in as many words that neither needs a new
capability. §4.4's **cabinet** — one wanted poster per closed case, in
progressively more deranged outfits — is the **deputy avatar** wall of D-63 and
D-45, which is **change 23** and needs art that does not exist
(`docs/ART-BRIEF.md`).

So the relationship is: **this change builds the record; the later ones dress
it.** A **season**-completion **trophy** *is* a case closed, under a different
name, and a **cabinet** grouped by territory *is* an episode list. What changes
here is one thing — the **season**-completion **award** is named and worded as
closing the case, and carries the territory and the date a poster will later
need — so that change 23 is a re-skin rather than a re-model.

**The words "case" and "act" are deliberately not added to the glossary by this
change.** They belong to whichever change first makes them observable, which
§7 says is 20 and 22. Using them here would put two names on one concept before
anything renders either.

## Constraints

**Capabilities:** `trophy-cabinet`

**Constraint 1 — non-punitive.** An **unfiled** **award** is the load-bearing
case. It is shown as *not yet filed*, never as failed or missed, and it carries
no countdown — D-21 wants the visible gap to invite a return, and the line
between that and a reproach is entirely in how it is drawn and worded. Nothing
in the **cabinet** can be lost: a **trophy** is never removed, and a **season**
rotating takes nothing with it (D-17).

**Constraint 4 — one colour, one job.** An earned **trophy** and an **unfiled**
one are told apart by `cactusGreen` (completion) against a `bone` surface, and
no new hue. Neither state is an error, so `sunsetRed` appears nowhere on this
screen.

**Constraint 5 — colour is never the sole signal.** Earned and **unfiled** each
carry a glyph and a word as well as a fill, and every **trophy** says its state
in its semantic label. A grid of medals is exactly the screen where colour alone
would be easiest to reach for.

**Constraint 9 — written on every change, never on a timer.** A minted
**trophy** is save state and inherits the rule. It is written in the same
transaction as the event that earned it, so a **trophy** cannot survive without
its cause or the other way round — the shape `solve record` already uses.

**Full offline play.** The **cabinet** reads only local state and the compiled-in
fallback, so it works on a fresh install in airplane mode.

## Technical notes

**Grid performance:** Not affected. No in-puzzle rendering changes.

**Offline, cold start, app kill:** Fully offline. The **cabinet** must not read
the database on the path to the first frame — the shell keeps every destination
built, so this screen defers like the **trail** and the **daily challenge** do.
The schema moves v6 → v7 for the **trophy** table, so a migration and its test
are part of this change.

**New dependency:** None.

## Not doing

- **No Stamps.** D-66 prices nothing for a **trophy** and `add-stamps` (18) owns
  minting currency. A **trophy** is its own reward.
- **No medals distinct from trophies.** `docs/SPEC.md` §5.1 says "trophy and
  medal" and never distinguishes them; this change ships one concept and leaves
  a second to whoever can say what it would mean.
- **No deputy avatar or wanted-poster wall.** `add-deputy-avatar` (23) owns the
  avatar, and the poster wall needs art that does not exist (`docs/ART-BRIEF.md`).
- **No sharing, no export, no comparison with other players.** Leaderboards and
  social are out of v1 (`openspec/BACKLOG.md`).
- **No cloud sync.** The **trophy** table is shaped so §3b's union rule works
  and listed as syncable; `add-cloud-sync` (29) implements it.
- **No retroactive minting.** A player upgrading into this version starts with
  the **trophy**s they earn from here on. Back-filling would mean inventing
  dates for events the database never recorded, and a **cabinet** that quietly
  invents its own history is worth less than an honest empty one.
