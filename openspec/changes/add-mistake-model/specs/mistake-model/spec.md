# Delta for mistake-model

## Purpose

What the game knows about a wrong digit, and how little of it the player is
told.

A **mistake** is a placement that disagrees with the puzzle's solution. It is
recorded and then, by default, never mentioned: not flagged, not coloured, not
counted on screen, and never capped. Finding a wrong digit is the game (D-04),
and a capability that points at it has taken the game away. The count exists so
that a finished puzzle can be described afterwards — a solve with no mistakes
earns Stamps, and the cabinet's statistics need a number — not so that a puzzle
in progress can be judged.

The one failure state in this product lives here, behind **strict mode**: an
opt-in switch that flags errors as they are placed and ends the **attempt** at
the third mistake. It is one switch rather than two because flagging without a
cap and a cap without flagging are both halves of a thing nobody asked for, and
because every setting is a setting forever. Nothing turns it on but the player.

Two rules narrow what counts, and both are about telling a wrong answer from a
wrong finger. Overwriting an already-correct cell is never a mistake in either
mode (D-05) — the player did not get a logic problem wrong, they mis-tapped.
A note is never a mistake in either mode (D-14) — notes are thinking out loud,
and punishing exploration undermines the technique ladder the whole progression
rests on.

## ADDED Requirements

### Requirement: A wrong placement is recorded and nothing is shown

The system MUST record a **mistake** when the player places a digit that
disagrees with the puzzle's solution, MUST NOT flag it, colour it, correct it,
or show any count while **strict mode** is off, and MUST NOT offer any way to
turn flagging on without turning **strict mode** on (D-04).

#### Scenario: A wrong digit is placed

- **WHEN** the player places a digit that disagrees with the solution and
  **strict mode** is off
- **THEN** the cell is drawn exactly as a correct placement would be, and
  nothing on screen distinguishes the two

#### Scenario: The board is never corrected

- **WHEN** a **mistake** is recorded
- **THEN** the digit the player placed stays where they put it, because the
  board is theirs and finding the error is the game

#### Scenario: There is no limit by default

- **WHEN** the player makes any number of **mistake**s with **strict mode** off
- **THEN** play continues, the puzzle never ends itself, and nothing is taken
  away (constraint 1)

#### Scenario: The count is not on screen

- **WHEN** a puzzle is in progress with **strict mode** off
- **THEN** no running count of **mistake**s is shown anywhere, because a
  visible tally is a flag with extra steps

#### Scenario: Flagging cannot be had on its own

- **WHEN** the player looks for a way to be told about errors without the
  three-**mistake** cap
- **THEN** there is none — **strict mode** is one switch and carries both

### Requirement: A mistake is one wrong placement

The system MUST count each placement that disagrees with the solution
separately — so the same wrong digit put down twice is two **mistake**s — MUST
NOT count a press that places nothing, and MUST NOT reduce the count when the
cell is later corrected.

#### Scenario: The same wrong digit, put down twice

- **WHEN** the player places a wrong digit, replaces it, and then places that
  same wrong digit again
- **THEN** two **mistake**s are recorded, because the tally is what the player
  did and not which cells ended up wrong

#### Scenario: Pressing the digit already in the cell

- **WHEN** the player presses the digit the cell already holds
- **THEN** nothing is placed and nothing is recorded — a press that changes no
  cell is not a placement, and a tally that rose on it would be counting taps

#### Scenario: Two wrong digits in one cell

- **WHEN** the player places one wrong digit and then another in the same cell
- **THEN** two **mistake**s are recorded

#### Scenario: Correcting a cell does not undo the tally

- **WHEN** the player replaces a wrong digit with the right one
- **THEN** the **mistake** already recorded stands, and the count does not fall

#### Scenario: Erasing does not undo the tally

- **WHEN** the player erases a cell that held a wrong digit
- **THEN** the count is unchanged, because the placement happened

### Requirement: Overwriting an already-correct value is never a mistake

The system MUST NOT record a **mistake** when the player places a digit over a
cell that already held the value the solution gives it, in either mode, and MUST
NOT let such a placement end an **attempt** (D-05).

#### Scenario: A correct cell is overwritten

- **WHEN** the player places a wrong digit into a cell that already held its
  correct value
- **THEN** no **mistake** is recorded — that is a mis-tap, not a wrong answer

#### Scenario: The same rule applies in strict mode

- **WHEN** a correct cell is overwritten while **strict mode** is on
- **THEN** no **mistake** is recorded and the **attempt** does not move closer
  to its end

#### Scenario: Strict mode still shows the board as it stands

- **WHEN** a correct cell is overwritten with a wrong digit while **strict
  mode** is on
- **THEN** the cell is shown as disagreeing with the solution, because **strict
  mode** promises the board is checked — flagging states a fact, and counting is
  what D-05 restricts

### Requirement: No note action is ever a mistake

The system MUST NOT record a **mistake** for marking, removing, re-inking,
clearing, promoting, or automatically generating a note, in either mode,
whatever the solution says (D-14).

#### Scenario: A candidate that cannot be right

- **WHEN** a digit is marked as a **settled note** in a cell whose solution is
  another digit
- **THEN** no **mistake** is recorded, in either mode

#### Scenario: A hypothesis that turns out wrong

- **WHEN** a **provisional note** contradicts the solution
- **THEN** no **mistake** is recorded — writing one down is the point (D-11)

#### Scenario: The fill's own candidates

- **WHEN** **auto-notes** marks candidates that the solution rules out
- **THEN** no **mistake** is recorded, because a **generated note** states what
  is legal and not what is true

### Requirement: Strict mode is one opt-in setting, off until the player turns it on

The system MUST keep **strict mode** off on a fresh install, MUST turn it on
only when the player does so deliberately, MUST NOT let a **rank**, a **season**,
a **node**, or a server-supplied value turn it on, and MUST carry both of its
behaviours together — immediate flagging and the three-**mistake** cap (D-04).

#### Scenario: A fresh install

- **WHEN** a player who has changed nothing opens a puzzle
- **THEN** **strict mode** is off, nothing is flagged, and no **mistake** limit
  is in force (constraint 1)

#### Scenario: Nothing else can turn it on

- **WHEN** the player reaches a higher **rank**, opens a boss **node**, or the
  app reads its remote configuration
- **THEN** **strict mode** is still whatever the player last set it to

#### Scenario: Turning it off mid-puzzle

- **WHEN** the player turns **strict mode** off during a puzzle that is still in
  play
- **THEN** flagging stops and the cap no longer applies, because leaving a mode
  the player chose must be as available as entering it

#### Scenario: Turning it off after the attempt has ended

- **WHEN** the player turns **strict mode** off on a puzzle whose **attempt**
  has already ended
- **THEN** the board stays locked, because the switch governs what happens next
  and is not a way to continue a run that is over (D-95)

#### Scenario: The switch reaches a puzzle already on screen

- **WHEN** the player changes **strict mode** while a puzzle is open
- **THEN** it takes effect on that puzzle, not only on the next one opened

### Requirement: A flagged cell is readable without colour

The system MUST mark a cell that disagrees with the solution, while **strict
mode** is on, with a signal that is not its hue alone, and MUST show the
**mistake**s remaining in the **attempt** as a count rather than as a colour
(constraint 5, D-53).

#### Scenario: A cell is flagged

- **WHEN** a placement disagreeing with the solution is made in **strict mode**
- **THEN** the cell carries a mark a player who cannot separate the error hue
  from the ink can still read

#### Scenario: How much of the attempt is left

- **WHEN** an **attempt** in **strict mode** has recorded one or more
  **mistake**s
- **THEN** how many remain is stated as a number, not signalled by a colour
  changing

### Requirement: The third mistake ends the attempt

The system MUST, when a third **mistake** is recorded in **strict mode**, stop
accepting input into the grid, record the **attempt** as failed, and offer the
player the same puzzle from the start and a way back to the season map. It MUST
NOT offer any way to continue the ended **attempt**, and MUST NOT charge for,
sell, or advertise one.

#### Scenario: The third mistake

- **WHEN** a third **mistake** is recorded in **strict mode**
- **THEN** the grid accepts no further placements, notes, or erases, and the
  **attempt** is over

#### Scenario: Starting again

- **WHEN** the player chooses to start the puzzle again after a failed
  **attempt**
- **THEN** the grid is as it was when the puzzle was first opened, and the
  **mistake** count is zero

#### Scenario: Leaving instead

- **WHEN** the player chooses the map after a failed **attempt**
- **THEN** the puzzle is left unsolved and can be opened again later

#### Scenario: There is no way to buy the attempt back

- **WHEN** an **attempt** has ended
- **THEN** nothing offers a revive, an extra **mistake**, a Stamp price, or a
  video to watch — the mode's stakes are the reason the player turned it on

#### Scenario: An ended attempt cannot be un-ended

- **WHEN** the player looks for any way back into an **attempt** that has
  ended — including turning **strict mode** off
- **THEN** there is none; starting the puzzle again is the only route onward

#### Scenario: Only strict mode ends anything

- **WHEN** a third **mistake** is recorded with **strict mode** off
- **THEN** play continues exactly as before, because there is no limit outside
  the mode (constraint 1)

#### Scenario: Other puzzles are untouched

- **WHEN** an **attempt** ends
- **THEN** no other puzzle's save, statistics, or solved state changes

### Requirement: The mistake count is written when it changes

The system MUST write an **attempt**'s **mistake** count with the placement that
changed it, in the same commit, and MUST NOT defer it to a timer or to the app
being backgrounded (D-33, constraint 9).

#### Scenario: The app is killed after a wrong placement

- **WHEN** the app stops immediately after a **mistake** is recorded
- **THEN** the puzzle reopens with that **mistake** counted

#### Scenario: A resumed puzzle keeps its tally

- **WHEN** a part-solved puzzle is reopened
- **THEN** its **mistake** count is what it was, and not zero

#### Scenario: A save made before mistakes were counted

- **WHEN** a puzzle saved before this capability existed is reopened
- **THEN** its count is zero, because the placements that made it were never
  inspected, and play continues normally

#### Scenario: Writing does not delay the player

- **WHEN** a **mistake** is recorded
- **THEN** the digit is on screen without waiting for the write, and the next
  tap is accepted immediately (constraint 2)

### Requirement: Perfection is decided by the attempt, not by its caller

The system MUST derive whether a puzzle was solved without a **mistake** from
the **attempt**'s own count, and MUST NOT accept that judgement from a caller
as a separate value.

What is then *done* with it — raising a lifetime perfect-solve counter, paying
Stamps, showing it in the cabinet — belongs to the change that wires statistics
to finished puzzles. That change also needs the set of techniques a puzzle
required, which only the grader can supply, so recording a solve is not
something this capability can complete on its own.

#### Scenario: A clean run

- **WHEN** an **attempt** has no **mistake** recorded against it
- **THEN** it reports itself as perfect

#### Scenario: A run with a mistake in it

- **WHEN** an **attempt** has one or more **mistake**s recorded against it
- **THEN** it does not report itself as perfect, even if every wrong digit was
  corrected before the puzzle was finished

#### Scenario: Nothing can claim perfection on an attempt's behalf

- **WHEN** a finished puzzle is recorded
- **THEN** whether it was perfect is read from the **attempt**, so no caller can
  supply an answer the tally disagrees with
