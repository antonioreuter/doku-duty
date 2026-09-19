# completion-effects

## Purpose

What the board does when a **unit** is finished, and what it keeps saying about
it afterwards. The lasso and the dynamite, the **cascade** that chains them, the
sequence the finished board plays, and the **completion tint** and **corner
mark** that outlast all of it.

Two rules shape everything here, and both are about restraint rather than
reward.

The first is that **completion is a structural fact, never a verdict**. A
**unit** is complete when it holds nine distinct digits, and nothing in this
capability can see the puzzle's solution — a **unit** filled with nine distinct
digits that disagree with the solution is celebrated exactly like a correct one
(D-99). Celebrating only correct **unit**s would be auto-check wearing a party
hat: silence where a celebration was expected says "wrong" as clearly as a red
cell does, and says it while **strict mode** is off, which is the one thing
constraint 1 exists to prevent.

The second is that **the record must stay quieter than the work**. The tint is
one flat level however many completed **unit**s a cell belongs to (D-48), it
loses to selection and to **candidate highlighting** wherever they compete
(D-49), and it is derived from the board rather than stored — so nothing is
written when a **unit** completes and nothing can be written wrongly. Every
effect is skippable by a tap and silenced entirely by **reduce effects** or the
OS setting, because the player mid-flow is the player having the best time and
interrupting them to show them how well they are doing is self-defeating (D-46).

Completion is never signalled by colour alone (D-50, constraint 5). It carries
three forms: the tint in colour, the **corner mark** in geometry, and a count
announced to a screen reader — the two visual cues together do not satisfy a
player who cannot see either.

Established by `add-completion-effects`. The 400ms ceiling and its two recorded
exceptions are D-46 and D-47; the fresh-completion hold sits outside that
category as a state duration (D-98). Biscuit's stamp on a **cascade**'s third
step and two of the four completion beats are named, empty slots waiting for
`add-character-system`; sound is specified in `docs/DESIGN.md` §5 and owned by
no change yet.

## Requirements

### Requirement: A unit is complete when it holds nine distinct digits

The system MUST treat a **unit** as complete when all nine of its cells hold
values and no digit repeats among them, MUST decide this without consulting the
puzzle's solution, and MUST NOT report anything about whether those values agree
with the solution (D-04, D-99, constraint 1).

#### Scenario: A placement fills the last cell of a row

- **WHEN** a value is placed that leaves a row holding nine distinct digits
- **THEN** that row is complete

#### Scenario: A full unit that repeats a digit

- **WHEN** all nine cells of a **unit** hold values and two of them are the same
  digit
- **THEN** the **unit** is not complete, and nothing is shown against the player

#### Scenario: A complete unit that disagrees with the solution

- **WHEN** a **unit** holds nine distinct digits but one of them differs from the
  solution
- **THEN** it is complete and is celebrated exactly as any other, because
  completion states a fact about the **unit** and never a verdict on the player

#### Scenario: A value is erased from a complete unit

- **WHEN** a value is erased from a cell in a complete **unit**
- **THEN** that **unit** is no longer complete

#### Scenario: Only the placed cell's units are considered

- **WHEN** a value is placed
- **THEN** completion is decided for the row, the column, and the block that cell
  belongs to, and the rest of the board is not re-examined

### Requirement: Completing a row or column is a different effect from completing a block

The system MUST play a distinct effect for a completed row or column and for a
completed block, MUST start each from the cell just placed, and MUST keep each
within its duration in `docs/DESIGN.md` §5.

#### Scenario: A row or column completes

- **WHEN** a placement completes a row or a column
- **THEN** an effect runs along that **unit** from the placed cell and resolves
  within 260ms

#### Scenario: A block completes

- **WHEN** a placement completes a block
- **THEN** an effect runs outward from the placed cell rather than along a line,
  so a block never reads as a row, and resolves within 340ms

#### Scenario: A unit was already complete

- **WHEN** a value is placed in a cell whose **unit**s were complete before the
  placement and remain so
- **THEN** no completion effect fires, because nothing was completed

### Requirement: Simultaneous completions chain rather than overlap

The system MUST, when one placement completes two or more **unit**s, run their
effects as a **cascade** — chained at 90ms offsets in the order row, column,
block — and MUST NOT start them together (D-47).

#### Scenario: A placement completes a row and a block

- **WHEN** one placement completes both a row and a block
- **THEN** the row effect starts first and the block effect starts 90ms later,
  each still legible as its own reward

#### Scenario: A placement completes all three units

- **WHEN** one placement completes a row, a column, and a block
- **THEN** the three run in that order at 90ms offsets and the whole **cascade**
  resolves within 520ms, the deliberate exception recorded against D-46

#### Scenario: A cascade is interrupted by the next placement

- **WHEN** the player places another value while a **cascade** is still running
- **THEN** the placement is accepted immediately and the **cascade** does not
  delay it

### Requirement: A completed unit keeps one flat tint that never stacks

The system MUST give every cell of a completed **unit** a **completion tint**,
MUST keep that tint at exactly one level however many completed **unit**s the
cell belongs to (D-48), and MUST derive it from the board rather than storing it.

#### Scenario: A cell in three completed units

- **WHEN** a cell belongs to a completed row, a completed column, and a completed
  block
- **THEN** it is tinted identically to a cell belonging to only one completed
  **unit**

#### Scenario: A nearly finished board

- **WHEN** most of the board's **unit**s are complete
- **THEN** no cell is darker than any other tinted cell, and every value and
  candidate on the board is still legible

#### Scenario: A part-finished puzzle is reopened

- **WHEN** a puzzle with completed **unit**s is opened again
- **THEN** its **completion tint**s and **corner mark**s are present from the
  first frame, and no completion effect replays

#### Scenario: A completed unit is broken

- **WHEN** a value is erased from a cell in a completed **unit**
- **THEN** the **completion tint** and **corner mark** leave every cell of that
  **unit** that is not held by another completed **unit**

### Requirement: Completion is readable without colour and the tint can be hidden

The system MUST accompany every **completion tint** with a **corner mark**
(D-50, constraint 5), and MUST offer a setting that hides **completion tint**s,
off until the player turns it on, which leaves the **corner mark**s in place.

#### Scenario: A player who cannot separate the tint from the surface

- **WHEN** a **unit** completes
- **THEN** its cells carry a mark that states the **unit** is complete without
  relying on hue

#### Scenario: Tints are hidden

- **WHEN** the player turns on the setting that hides **completion tint**s
- **THEN** no cell is tinted, the **corner mark**s remain, and which **unit**s are
  complete is still readable

#### Scenario: The default

- **WHEN** a player who has changed nothing opens the settings
- **THEN** **completion tint**s are shown, because the setting hides them rather
  than enabling them and is off by default

### Requirement: How much of the board is settled is announced to a screen reader

The system MUST report how many **unit**s are complete to assistive technology,
MUST derive that from the board rather than from what is drawn, and MUST NOT
name which **unit**s or say anything about whether the values in them are right.

A third form of the same fact. The **completion tint** carries it in colour and
the **corner mark** carries it in geometry; neither reaches a player using a
screen reader, and constraint 5 is not satisfied by two signals that both
require sight.

#### Scenario: Some of the board is complete

- **WHEN** a player using a screen reader reaches the grid
- **THEN** it reports how many of the twenty-seven **unit**s are complete

#### Scenario: Nothing is complete yet

- **WHEN** no **unit** on the board is complete
- **THEN** the grid reports itself without a count, rather than reporting zero

#### Scenario: The tints are hidden

- **WHEN** the player has turned on the setting that hides **completion tint**s
- **THEN** the count is unchanged, because hiding a tint hides a convenience
  and never a state

#### Scenario: A unit that disagrees with the solution

- **WHEN** a complete **unit** holds nine distinct digits that do not match the
  solution
- **THEN** it is counted like any other, because the announcement carries the
  same structural fact the tint does and no more (D-99, constraint 1)

### Requirement: A freshly completed unit is distinguishable from a settled one

The system MUST hold a warmer highlight on a **unit** for about two seconds after
it completes and then settle it to the **completion tint**, so that the
celebration and the record are different states. The hold is a state duration
rather than in-puzzle motion, and so is not a third exception to the 400ms
ceiling (D-98).

#### Scenario: A unit has just completed

- **WHEN** a **unit** completes
- **THEN** it holds the fresh highlight for roughly two seconds before settling to
  the persistent **completion tint**

#### Scenario: The next placement lands during the hold

- **WHEN** the player places another value while a fresh highlight is held
- **THEN** the placement is accepted immediately and the hold neither delays it
  nor is restarted by it

#### Scenario: The app is killed during the hold

- **WHEN** the app stops while a fresh highlight is held and the puzzle is
  reopened
- **THEN** the **unit** shows the settled **completion tint**, because the fresh
  state belongs to the placement and not to the save

### Requirement: The player's focus outranks the completion tint

The system MUST paint competing cell states in the order selection, then
**candidate highlighting**, then **completion tint** (D-49).

#### Scenario: The selected cell is in a completed unit

- **WHEN** the player selects a cell that carries a **completion tint**
- **THEN** the cell reads as selected, and the tint does not obscure it

#### Scenario: A highlighted candidate is in a completed unit

- **WHEN** **candidate highlighting** lights a cell that carries a **completion
  tint**
- **THEN** the cell reads as highlighted, and the tint does not obscure it

### Requirement: Finishing the board plays a completion sequence

The system MUST play a sequence when the board is complete — every cell holding a
value and no **unit** repeating a digit — MUST build it as an ordered list of
named beats so later changes can fill beats without re-cutting the sequence, and
MUST NOT require the player to wait for it.

#### Scenario: The last cell is filled

- **WHEN** the placement that completes the board is made
- **THEN** the completion sequence plays, starting from that cell

#### Scenario: The board is full but a unit repeats a digit

- **WHEN** every cell holds a value and some **unit** holds the same digit twice
- **THEN** no completion sequence plays and nothing is flagged against the player,
  because saying which cell is wrong belongs to **strict mode** (constraint 1)

#### Scenario: A beat has nothing to draw yet

- **WHEN** the sequence reaches a beat whose content a later change will supply
- **THEN** the sequence continues through the remaining beats without a visible
  stall

#### Scenario: The player leaves during the sequence

- **WHEN** the player taps away while the sequence is running
- **THEN** the sequence ends and the puzzle is recorded as solved regardless

### Requirement: No effect delays the player, and every effect is skippable

The system MUST accept input while any completion effect is in flight, MUST let a
tap end a running effect (D-46), and MUST NOT queue effects behind one another
beyond the **cascade** ordering.

#### Scenario: A tap during an effect

- **WHEN** the player taps while an effect is running
- **THEN** the effect ends, the tap is handled as the input it was, and the
  **completion tint** it would have settled into is applied

#### Scenario: Placements faster than the effects

- **WHEN** the player places several values in quick succession, each completing a
  **unit**
- **THEN** every placement is accepted within the input budget and effects do not
  accumulate as a backlog

### Requirement: Asking for less motion silences the effects

The system MUST silence every completion effect when **reduce effects** or the
operating system's reduce-motion setting is on, and MUST keep the state each
effect would have announced.

#### Scenario: Motion is reduced

- **WHEN** either setting is on and a **unit** completes
- **THEN** no motion, no particle, and no haptic occurs, and the **completion
  tint** and **corner mark** appear directly in their settled state

#### Scenario: The board is finished with motion reduced

- **WHEN** either setting is on and the board is completed
- **THEN** the sequence does not play and the puzzle is recorded as solved

#### Scenario: Nothing is lost

- **WHEN** either setting is on
- **THEN** which **unit**s are complete, and that the puzzle is finished, remain
  readable

### Requirement: Nothing fires on a note

The system MUST NOT run any motion, particle, or haptic when a **settled note** or
a **provisional note** is added, removed, promoted, or cleared (D-52).

#### Scenario: A dense board is marked

- **WHEN** the player marks many candidates in succession
- **THEN** no effect of any kind runs

#### Scenario: A note completes nothing

- **WHEN** a cell's last empty **peer** in a **unit** is given notes rather than a
  value
- **THEN** the **unit** is not complete and no effect runs, because only values
  complete a **unit**

### Requirement: Particles stay within budget and never hide the work

The system MUST cap particles on screen at the numbers in `docs/DESIGN.md` §6,
MUST reuse one pool across a **cascade** rather than allocating per effect, MUST
cull any particle that would cover a cell holding no value, and MUST draw every
effect behind the glyphs.

#### Scenario: A cascade runs

- **WHEN** a **cascade** runs all three of its steps
- **THEN** the particles on screen stay within the single-effect budget rather
  than tripling it

#### Scenario: A particle would land on unsolved ground

- **WHEN** an effect would draw a particle over a cell that holds no value
- **THEN** that particle is not drawn, because the player still has to read that
  cell

#### Scenario: An effect crosses a value or a note

- **WHEN** an effect passes over a cell holding a value or candidates
- **THEN** the glyphs stay at full opacity and the effect is drawn behind them
