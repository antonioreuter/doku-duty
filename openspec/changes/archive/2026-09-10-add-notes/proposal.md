# add-notes

## Why

The grid can hold a value and nothing else, so the only way to play a puzzle
above Deputy is to hold five candidates in your head at once. Notes are not a
comfort feature here — the technique ladder D-07 grades against *is* candidate
work, and a naked triple or an X-wing cannot be seen without them (D-09). Every
**rank** above the singles is currently unplayable in practice.

## What changes

- **Nine candidates per cell, in fixed 3×3 positions** (D-09, D-10). 1 top-left,
  5 centre, 9 bottom-right, always. Removing a candidate never moves the others.
- **A persistent notes toggle** (`docs/SPEC.md` §3.4): a mode, not a modifier
  held per entry, because players work in note-heavy bursts. It stays on until
  turned off; a freshly opened puzzle starts in value mode.
- **Long-press a pad digit for the opposite mode**, so a single note during a run
  of values — or a single value during a run of notes — costs no trip to the
  toggle.
- **Notes in digit-first input**: hold a digit, tap cells, and each one gains or
  loses that candidate. This is the strongest scanning tool in the product and
  the combination the documents never addressed.
- **A cell holds either a value or notes, never both** (`docs/SPEC.md` §3.2).
  Placing a value clears that cell's candidates, and **undo puts them back** —
  one step, carrying what it cleared.
- **Notes are written on every change** (D-33, constraint 9), and survive an app
  kill exactly as placed values do.
- **Notes never count as mistakes**, in any mode (D-14). Nothing counts mistakes
  yet; this change must not be where that quietly begins.

## Constraints

**Capabilities:** `notes`

**Constraint 3 (nine candidates per cell, in fixed positions)** is the one this
change exists to satisfy and the one it can silently break. A candidate's slot is
a function of the digit and nothing else — not of insertion order, not of how
many candidates the cell holds. Notes that reflow when a candidate is removed are
the hidden cause of an app feeling bad, and the symptom is a player who says the
board is "hard to read" without being able to say why. The data model already
enforces it: a note is addressed by (puzzle, cell, digit), so removing one is
deleting a row and the other eight never referred to it.

**Constraint 9 (note state written on every change, never on a timer)** has no
visible symptom when it breaks. `add-persistence-layer` built the writes as
single statements for exactly this; this change is the first caller, and the
tests that prove the discipline have to live here.

**Constraint 1 (non-punitive).** Notes are thinking out loud (D-14). A wrong
candidate is not flagged, not counted, and not corrected. Nothing about note
entry can be refused except writing into a given.

**Constraint 2 (latency).** A note is one row and one repaint. The painter
already caches its digit layouts; nine candidates per cell is nine more small
glyphs, and the cost has to stay off the frame path the same way a value does.

**Constraints 4, 5** — settled notes are `nightIndigo`, the token D-53 reserves
for them. One hue, and the note's *position* carries its identity, so colour is
never the only signal.

**Constraints 6, 7, 8, 10** are untouched: no ads, no generation, no currency.

## Technical notes

**Grid performance:** Nine glyphs per empty cell is up to 729 on a blank board,
against 81 values today. They are laid out once per digit and drawn by position,
so the added cost is drawing rather than shaping. The note slot geometry derives
from the cell rect the painter already computes, and `shouldRepaint` gains the
note state — a board that changed only its values must not redraw because a note
set was rebuilt into an equal one.

**Offline, cold start, app kill:** No network. A note written and the process
killed a frame later is on the board when the puzzle reopens, which is the
guarantee `add-persistence-layer` exists for and the first change able to test it
end to end.

**New dependency:** None. The note table, both enums, and every statement this
needs were built by `add-persistence-layer`; the ink tokens and the 11px
`gridNote` type role were built by `add-design-system`. This change is the first
caller of all of it.

## Not doing

- **No auto-cleanup.** Placing a value does not remove that candidate from its
  peers. Change 8, and it is the larger half of what makes notes trustworthy —
  this change ships notes that go stale, which is a real limitation and worth
  saying plainly.
- **No candidate highlighting.** Tapping a pad digit does not light up the cells
  holding it as a note (D-13). Change 8.
- **No auto-notes fill.** Change 8.
- **No provisional notes.** One ink only. The second ink, and the single action
  that clears every provisional mark, are change 9 — the data model already
  carries `NoteKind`, and this change writes `settled` into it and never reads
  the other value.
- **No mistake model.** Notes never count as mistakes and neither does anything
  else yet. Change 10.
- **No "clear all notes in this cell" control.** Not in the backlog for this
  change, and erase already empties a cell.
- **No completion effects and no timer.** Changes 11 and later.
