# add-provisional-notes

## Why

Above Sheriff the game stops being about spotting candidates and starts being
about testing them — assume a value, follow the consequences, look for a
contradiction. There is no way to write a hypothesis down, so players hold the
chain in their head or reach for paper, and the **rank**s the whole technique
ladder climbs toward are the ones the notes system currently serves worst
(D-11). The pieces have been waiting since the foundation: the store has carried
`NoteKind.provisional` and a one-statement clear since `add-persistence-layer`,
and the turquoise-and-underline treatment since `add-design-system`. Nothing
writes or draws either.

## What changes

- **A second ink, on its own axis.** The notes toggle keeps meaning value
  against note; a separate control says which ink note mode writes (D-89). The
  two are independent, so long-press keeps the one meaning it already has.
- **A hypothesis is drawn as one** — `turquoise` with a 1px rule 1.5px below the
  baseline, inside the note's own third of the cell (D-73). The tokens exist;
  this is the first change to draw them.
- **Marking a digit in the other ink re-inks it rather than removing it**
  (D-90). A player who has derived candidates and then starts testing one takes
  their existing work into the hypothesis instead of re-entering it. Marking in
  the *same* ink still removes, exactly as now.
- **A digit is one ink or the other, never both.** A note set carries kind per
  digit, the way `add-note-automation` gave it origin.
- **Clear every provisional mark in one action** (D-11), leaving **settled
  note**s untouched. One undo step.
- **Promote** every provisional mark to settled in one action (D-91). A chain
  test ends one of two ways, and without this the half that *succeeds* is the
  slower half.
- **Glossary:** **promote** joins `openspec/project.md`.

## Constraints

**Capabilities:** `notes`

**Constraint 5** is the one this change exists under, not merely near. D-73
measured it: once `turquoise` is dark enough to be legible at 11px, the two inks
sit 1.33:1 apart in normal vision and **1.07:1 under deuteranopia** — the same
mark, for roughly one man in twelve. The underline is the signal; the hue is the
convenience. Any test that proves the two inks differ must prove it without
reading a colour.

**Constraint 3.** The kind mask is nine more bits on a value that already
carries presence and origin — no list, no index, nothing to compact. The
underline sits *below* the digit's baseline and inside the note's own third of
the cell, so a candidate occupies the slot its digit owns whichever ink it is in,
and re-inking moves nothing.

**Constraint 9.** Clear and promote each rewrite many rows at once. They go
through the transactional path `add-note-automation` built for the fill: one
commit with the action, nothing deferred.

**Constraint 1.** A **provisional note** is a guess by definition, and still
never a mistake (D-14). Nothing flags one, counts one, or refuses one — a
hypothesis that contradicts the solution is the *point*. Clearing is the
player's own action and one undo away.

**Constraint 4.** `turquoise` is already one of the eight and already reserved
for exactly this — "provisional notes only, nothing else, ever"
(`docs/DESIGN.md` §2). No token is added.

**Constraint 2.** One more mask read per candidate, and one `drawLine` per
provisional candidate. The painter's cached digit layouts gain a second set for
the turquoise ink, laid out once per instance like the other two.

## Technical notes

**Grid performance:** notes are already the densest thing on the canvas — up to
729 glyphs. This adds a third `TextPainter` cache and, at worst, 729 hairlines.
That is the number to measure against the repaint budget rather than assume,
because it is the one place in this change where a plausible implementation
could cost real frame time.

**Offline, cold start, app kill:** all three are local and unchanged. Clear and
promote each commit as one transaction, so a kill part-way through leaves the
board as it was rather than half re-inked.

**How it meets `add-note-automation`:** **auto-cleanup** strips a candidate
whatever ink it is in — a placement disproves a hypothesis exactly as it
disproves a derived candidate. **Candidate highlighting** lights a cell holding
the digit in either ink. **Auto-notes** still writes **settled note**s only, so
a fill never manufactures a hypothesis.

**New dependency:** none. The ink tokens, the `NoteKind` column, the
`clearProvisional` statement, and the multi-cell write all exist.

## Not doing

- **More than one hypothesis at a time.** One provisional layer, not named or
  numbered chains — that is a different feature with its own interface.
- **Noticing that a hypothesis has failed.** Nothing here detects the
  contradiction the player is hunting for; finding it is the game (D-04), and
  telling them would be the mistake model and a hint engine at once.
- **A character reacting to a cleared chain.** `docs/SPEC.md` §6 gives Biscuit a
  sympathetic shrug for it; the cast arrives in change 20.
- **Metering either control.** Provisional notes are free and unmetered, like
  **candidate highlighting** and unlike the perks in change 19.
- **A setting to turn the second ink off.** An unused control costs an unused
  control; a setting costs a setting forever.
- **Changing what auto-notes writes**, or letting a fill produce provisional
  marks.
