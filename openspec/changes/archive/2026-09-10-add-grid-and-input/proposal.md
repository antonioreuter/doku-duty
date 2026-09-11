# add-grid-and-input

## Why

There are 305 graded puzzles in the app and no way to see one. Everything built
so far — the palette, the database, the engine, the **pack** — exists to serve a
grid nobody has drawn yet, and until it exists no constraint that matters can be
tested against reality: not the sub-100ms input budget, not the eight colour
tokens on a dense surface, not a save surviving an app kill mid-puzzle.

## What changes

- **A grid on a custom canvas** (D-31): 9×9, given digits distinguished from
  placed ones, unit boundaries heavier than cell lines, drawn for direct control
  of the render loop rather than as 81 widgets.
- **Cell selection and value entry.** Tap a cell, tap a digit. Erase clears a
  placed value. Given cells never change.
- **Number-first input as a setting** (`docs/SPEC.md` §3.4): lock a digit, then
  tap cells. Off by default, so the default is the one that needs no explanation.
- **Peer highlighting**: selecting a cell marks the cells sharing a **unit** with
  it. Always on — it is the free half of what D-13 does for notes, and it costs a
  player nothing to have.
- **Undo at full depth within a session.** Every placement and erase, back to the
  puzzle's start.
- **The grid is saved on every change**, so an app kill mid-puzzle loses nothing.
- **A temporary rank picker** on the home screen — six entries, each opening the
  next unsolved puzzle at that **rank**. It exists so all six are reachable and
  testable now, and `add-season-map` deletes it.
- **A minimal settings screen.** The three stored settings have had no UI since
  `add-persistence-layer` defined them; the input-mode toggle needs one, and
  strict mode and auto-check need somewhere to live when changes 10 and 30 arrive.

## Constraints

**Capabilities:** `grid-input`

**Constraint 2 (input latency under 100ms; no effect blocks the next tap)** is
the one this change lives or dies by, and it is a product requirement rather than
an aspiration. A tap must place a digit and repaint within budget on a mid-tier
Android device, not only on a simulator — the simulator lies about frame timing.
Nothing here animates for longer than it takes to become tappable again.

**Constraint 1 (non-punitive).** No auto-check, no error colour, no mistake
count, no timer that can fail anything. A wrong digit sits on the board looking
exactly like a right one, because finding it is the game (D-04). Erase and undo
are always available, and no input is ever refused except writing over a given.

**Constraint 4 (one colour, one job)** and **5 (colour is never the sole
signal).** Selection and peer highlighting both draw on `badgeGold`, the token
D-53 reserves for focus, at two depths of the same hue rather than two hues.
Selection also carries a border, so the selected cell is identifiable without
colour at all. Givens are distinguished from placed values by weight, not colour.

**Constraint 3 (notes are positional)** is untouched here and must stay that way:
this change draws values only, and the cell painter leaves the note grid to
`add-notes` rather than laying out something that will be rewritten.

**Constraints 6, 7, 8, 9, 10** are untouched: no ads, no generation, no note
writes, no currency.

## Technical notes

**Grid performance:** The whole change is this question. The grid is one
`CustomPainter` over an immutable board value, so a tap repaints the canvas
rather than rebuilding a widget tree; hit-testing is arithmetic on the tap
offset, not 81 gesture detectors. Selection, peer highlighting, and the placed
digits are the only things that change per tap, and none of them touches the
database on the frame path — the save is fired after the state is on screen, the
same ordering `add-remote-config` uses for its refresh.

**Offline, cold start, app kill:** No network anywhere. The home screen must stay
interactive on the first frame, so the rank picker reads the **pack** after that
frame and shows its entries as they arrive rather than holding the screen. A kill
mid-puzzle loses no placed digit, because the save is written on every change;
it does lose the undo history, which is the deliberate limit of "full depth"
here — reopening a puzzle gives you the board you left, not the moves you made.

**New dependency:** None. `CustomPainter` and `GestureDetector` are Flutter's own,
Riverpod already holds the state, and the design system already owns the colours,
the shapes, and the haptic vocabulary. Rive is for characters (D-31) and no
character is on screen yet.

## Not doing

- **No notes.** Not the toggle, not the positional candidates, not auto-cleanup,
  not candidate highlighting. Change 7, and the cell painter is written to leave
  room rather than to guess at it.
- **No mistake model.** No auto-check, no error state, no mistake count, no
  strict mode behaviour. Change 10. The setting rows exist; nothing reads them.
- **No completion effects.** Finishing a puzzle marks it solved and does nothing
  else — no wave, no confetti, no card. Change 11.
- **No timer.** D-06 makes it display-only and hideable, and `elapsedMs` is
  already in the save. Nothing advances it here.
- **No hints and no perks.** The solver can explain a step; deciding when to
  offer one is change 19.
- **No characters and no reactions.** The strip below the grid is changes 20–22.
- **No season map, no nodes, no progression.** The rank picker is scaffolding,
  and it says so.
- **No undo across an app kill.** Deliberate: persisting the stack means a schema
  migration for a history nobody has asked to keep, and `add-notes` would rewrite
  its shape immediately.
- **No redo.** Nothing in the documents asks for one, and it is another control on
  a pad that has to stay reachable one-handed.
- **No landscape or tablet layout beyond what the shell already does.** The grid
  is square and centred; `add-accessibility-settings` owns the rest.
