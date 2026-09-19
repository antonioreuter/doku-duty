# add-completion-effects

## Why

Ten changes in, a placement that finishes a **unit** does nothing at all, and a
board carries no record of which **unit**s are already settled. This is the
reward beat of ordinary play and the one thing clones reliably get wrong — D-46
through D-50 and D-52 decided what it looks like and none of it is built. It
also has to land before `add-character-system`, which hangs Biscuit and Ace off
these same events.

## What changes

- A **unit** is detected as complete the moment a placement leaves it holding
  nine distinct digits — a structural fact, checkable without the solution, so
  no auto-check arrives by the back door (D-04).
- Row and column completion plays the lasso (260ms); block completion plays the
  dynamite (340ms), radial so it never reads as a row.
- Two or more **unit**s completed by one placement **chain** at 90ms offsets in
  the order row → column → block, 520ms total, never simultaneous (D-47).
- Finishing the board plays a completion sequence built as an ordered list of
  beats, with the wave and the scrap burst shipping now.
- A completed **unit** takes one flat **completion tint** that persists for the
  rest of the puzzle and never stacks (D-48), always with a corner mark (D-50).
- A freshly completed **unit** holds `goldPale` for two seconds and settles to
  `greenPale` — the celebration and the record are different states.
- Where highlights compete: selection, then **candidate highlighting**, then
  **completion tint** (D-49).
- A "hide completion tints" setting, off by default, which leaves the corner
  marks in place.
- A particle pool at the §6 caps, culled off unplaced cells, drawn behind the
  glyph.
- Every effect is skippable by tap, silenced by **reduce effects** or OS
  reduce-motion, and fires nothing on note entry (D-52).

## Constraints

**Capabilities:** `completion-effects`

- **1 — non-punitive.** Completion here asserts nine distinct digits, never
  agreement with the solution, so a **unit** that is full and internally
  consistent celebrates whether or not it matches (D-04). A full board that
  repeats a digit somewhere celebrates nothing and flags nothing; whether that
  is ever surfaced belongs to **strict mode**, not here.
- **2 — latency and 400ms.** The cascade (520ms) and the completion sequence are
  the two exceptions already recorded against `design-system`. Nothing waits on
  an effect: effects read board state and paint, and input is accepted while one
  is in flight.
- **4 — one colour, one job.** Tints and flashes come from `cactusGreen` and
  `badgeGold` through their documented derived tints. No ninth hue.
- **5 — colour is never the sole signal.** The corner mark carries completion on
  its own, which is also what keeps the state legible with tints hidden.

One conflict to name rather than work around: `docs/DESIGN.md` §5 lists a 2000ms
hold for the fresh tint, and the `design-system` build check fails any in-puzzle
motion token over 400ms that is not one of the two recorded exceptions. The hold
is a state duration, not an animation — the only motion is the short settle from
`goldPale` to `greenPale`. This change treats it as a state duration and does not
open a third exception.

## Technical notes

**Grid performance:** detection runs over the three **unit**s a placement touches,
not the board. Effects are painted in the existing grid `CustomPainter` pass from
a preallocated particle pool capped at 60 on screen, reused rather than tripled by
a **cascade**. No effect holds the input path, and none of this adds a widget per
cell.

**Offline, cold start, app kill:** **completion tint**s are derived from the board
rather than stored, so nothing new is written per placement and constraint 9 is
untouched. A reopened part-finished puzzle shows its tints and corner marks
immediately and replays no celebration — the fresh state belongs to the placement
that caused it, not to the save. The tints setting persists with the others.

**New dependency:** none. Flutter's own animation and painting, on the canvas the
grid already owns.

## Not doing

- **Sound.** The §5 table names a cue per event, but no audio package is chosen
  in `docs/TECH_STACK.md`, no D-NN picks one, and no backlog change owns audio.
  The effect events are specified so a sound layer can subscribe later without
  re-cutting them. Choosing the package needs its own decision and its own change.
- **Biscuit's stamp on the third cascade step, and completion beats 2 and 4**
  (Biscuit walking in, Ace appearing disappointed). Those are Rive characters and
  belong to `add-character-system`, which depends on this change. The sequence
  ships with named, empty slots for them.
- **Duplicate digit reactions** (D-42) — `add-digit-reactions`, change 21.
- **The interstitial after the celebration** (D-24) — `add-ads-integration`.
- **Season repaints of effects** — surfaces only, and not in this change (D-55).
- **Effects anywhere but the grid.** No map, cabinet, or node-completion motion.
