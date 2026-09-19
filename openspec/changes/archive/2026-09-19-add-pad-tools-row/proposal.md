# add-pad-tools-row

## Why

The pad grew to six unlabelled glyph keys — `✎ ~ ⁙ ↶ ✕ ✓` — across four ragged
rows, and a player who opened the app could not tell what any of them did. Worst
of it, `✕` and `✓` sit side by side and read as cancel and confirm, so the glyph
advertises the answer-checking this product refuses to do (D-04) while actually
performing a bulk change to the board.

`docs/pages/screens.html` specified the fix before any of it was built: a
**tools row** of labelled text chips, separate from the digit keys, showing only
the controls that are relevant. The word "tools" appears nowhere in
`openspec/specs/grid-input/spec.md` or `notes/spec.md`, so nothing protected that
layout and three successive changes each appended one more glyph to the pad.

## What changes

- The pad separates into two things: the **digit keys**, and a **tools row** of
  labelled controls below them. The tools row is text, not symbols.
- The tools row adapts to what the player is doing, rather than showing every
  control at once:
  - always — **Notes**, **Fill notes**, **Undo**
  - while notes mode is on — **Test** joins them, the control that switches ink
  - while the board holds at least one **provisional note** — **Discard test**
    and **Keep test** appear on a second line
- `✕` and `✓` are gone. The two controls that end a chain test are named for
  what they do to the board.
- The default pad is three rows rather than four, and no row is ragged.
- Erase stays in the digit keys as the tenth key, which is a deliberate
  departure from the mockup — see below.

## Constraints

**Capabilities:** `grid-input`, `notes`

- **1 — non-punitive.** Nothing is disabled. A control that has no work to do is
  absent rather than greyed out, which is the treatment `add-mistake-model`
  already established when it removed the whole pad at the end of an **attempt**
  rather than leaving it live and unresponsive. Absent is not a failure state;
  a control that looks live and swallows the tap is.
- **2 — latency.** The tools row is built from the same `Pressable` the pad
  already uses and adds no work to the input path. What changes is how many
  widgets exist, and it goes down in the common case.
- **5 — colour is never the sole signal.** The active tool is currently carried
  by a gold fill alone. A label makes the state readable without it, which is
  the same rule `grid-input` already applies to the pad for screen readers —
  "the symbol is decoration, and the name is the state". That requirement
  stopped one layer short of the sighted player, and this is the other layer.

D-89 keeps the ink a separate control from the notes toggle, and D-91 keeps
**promote** beside the D-11 clear. Both are about the model, not about where a
control is drawn, and both survive this unchanged — there are still two axes and
still two ways a chain test ends.

## Technical notes

**Grid performance:** fewer widgets in the default case, not more, and nothing
new on the tap path. Whether a control is shown is derived from board state the
screen already holds — whether any **provisional note** exists is a question the
board can already answer.

**Offline, cold start, app kill:** nothing is stored. Which tools are visible is
derived from the board and from the notes mode, so a resumed puzzle shows the
right ones on the first frame without anything having been written.

**New dependency:** none.

## Not doing

- **Hint.** `screens.html` shows it in the tools row, but hints are `add-perks`
  (change 19) and there is nothing to wire it to. The row is built so it takes
  another chip without rework.
- **The node, rank, and timer bar** the mockup shows above the grid. That needs
  `add-season-map` (change 15) and D-06's timer, neither of which exists.
- **The character strip.** `add-character-system`, change 20.
- **Any change to what the controls do.** This moves and names them; the notes
  model, the two inks, **auto-notes**, and undo all behave exactly as they do
  now.
- **Onboarding.** A player still meets the game with no explanation of the rules.
  That is change 33 and a separate problem; naming the buttons does not teach
  sudoku.
