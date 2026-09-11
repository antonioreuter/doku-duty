# grid-input

## Purpose

The board a player actually touches: nine by nine, drawn on one canvas, and the
controls that put a digit in a cell.

Everything here is shaped by one number. Input response must be under 100ms and
no animation may block the next tap (constraint 2, D-46), so the grid is a single
painter over an immutable board rather than eighty-one widgets, and a tap becomes
a cell by arithmetic on the offset rather than by hit-testing a tree. The player
mid-flow is the player having the best time, and every control is built so that
nothing they do has to wait for the thing they did before.

The second shaping force is what this capability refuses to say. A wrong digit
looks exactly like a right one, because finding it is the game (D-04) — there is
no auto-check here, no error colour, no mistake count, and no timer that can fail
anything. Overwriting a correct cell is reported as a fact and never as a fault
(D-05). Nothing is ever disabled, including a digit already placed nine times: a
disabled control is a small failure state, and this product does not have those.
Whether any of it counts against the player belongs to the mistake model, not
here.

Selection and the **peer**s it reveals are two depths of the focus token rather
than two hues, and the selected cell carries a border as well, so it stays
identifiable without colour at all (D-53, constraint 5). Givens are heavier than
placed values for the same reason.

The board is written after every change, never on a timer — the discipline D-33
sets for notes, applied to values, because nobody gets a warning before the OS
reclaims the process. Undo runs to the start of the session and no further: the
board survives an app kill, the moves that made it do not.

## Requirements

### Requirement: A puzzle is shown as a grid of givens and placed values

The system MUST draw the puzzle as nine rows and nine columns, MUST show which
cells are givens and which hold values the player placed, and MUST mark the
boundaries of every **unit**.

#### Scenario: A puzzle is opened

- **WHEN** a puzzle from the **pack** is opened
- **THEN** its givens are on the board, every other cell is empty, and the three
  kinds of **unit** are visually bounded

#### Scenario: A given and a placed value are told apart

- **WHEN** the grid holds both a given and a value the player placed
- **THEN** the two are distinguishable without relying on colour alone

#### Scenario: The grid is given less width than nine comfortable cells

- **WHEN** the grid is drawn on a narrow phone
- **THEN** it takes the width it is given and stays square and whole, rather
  than holding a minimum cell size and overflowing the screen (D-84)

#### Scenario: A part-finished puzzle is reopened

- **WHEN** a puzzle the player had already started is opened again
- **THEN** every value they had placed is on the board, in the cells they placed
  them in

### Requirement: The player selects a cell and places a digit

The system MUST let the player select one cell at a time, place a digit into the
selected cell, and erase a value they placed.

#### Scenario: A digit is placed

- **WHEN** a cell is selected and a digit is chosen
- **THEN** that digit appears in that cell

#### Scenario: A digit replaces another

- **WHEN** a digit is placed into a cell that already holds a placed value
- **THEN** the new digit replaces it, and nothing is reported against the player
  (D-05)

#### Scenario: A value is erased

- **WHEN** erase is used on a cell holding a placed value
- **THEN** the cell becomes empty

#### Scenario: A given is targeted

- **WHEN** the player tries to place a digit into, or erase, a given
- **THEN** the grid is unchanged, and nothing is reported as an error

#### Scenario: A wrong digit is placed

- **WHEN** a digit is placed that is not the puzzle's solution for that cell
- **THEN** it appears exactly as a correct one does, because finding it is the
  game (D-04, constraint 1)

### Requirement: Selecting a cell shows the cells it shares a unit with

The system MUST mark the peers of the selected cell — every other cell in its
row, its column, and its block.

#### Scenario: A cell is selected

- **WHEN** a cell is selected
- **THEN** its twenty peers are marked, and the selected cell itself remains
  distinguishable from them

#### Scenario: The selection moves

- **WHEN** another cell is selected
- **THEN** the previous cell and its peers are no longer marked, and the new
  cell's are

#### Scenario: Nothing is selected

- **WHEN** no cell is selected
- **THEN** no cell is marked as a peer

### Requirement: Input works digit-first as well as cell-first

The system MUST offer an input mode where a digit is chosen first and then
applied by tapping cells, MUST keep the cell-first mode as the default, and MUST
remember the player's choice.

#### Scenario: The default mode

- **WHEN** a player who has never changed the setting opens a puzzle
- **THEN** input is cell-first: selecting a cell and then a digit places it

#### Scenario: Digit-first input

- **WHEN** the setting is on, a digit is chosen, and a cell is tapped
- **THEN** that digit is placed in that cell, and the digit stays chosen for the
  next tap

#### Scenario: The choice outlives the session

- **WHEN** the setting is changed and the app is restarted
- **THEN** the chosen mode is still in force

### Requirement: Every placement and erase can be undone

The system MUST undo the player's actions in reverse order, back to the state
the puzzle was opened in.

#### Scenario: A placement is undone

- **WHEN** undo is used after a digit was placed
- **THEN** the cell returns to what it held before

#### Scenario: An erase is undone

- **WHEN** undo is used after a value was erased
- **THEN** the erased value is back

#### Scenario: Undo runs to the start

- **WHEN** undo is used repeatedly
- **THEN** it keeps stepping back to the board as it was when the puzzle was
  opened, and then does nothing further

#### Scenario: Nothing to undo

- **WHEN** undo is used with no action to reverse
- **THEN** the grid is unchanged and nothing is reported as an error

### Requirement: A puzzle in progress is saved as it is played

The system MUST write the board after every change, so that no placed value is
lost if the app stops.

#### Scenario: The app is killed mid-puzzle

- **WHEN** the app stops immediately after a digit is placed
- **THEN** that digit is on the board when the puzzle is next opened

#### Scenario: Saving does not delay the player

- **WHEN** a digit is placed
- **THEN** it is on screen without waiting for the write, and the next tap is
  accepted immediately (constraint 2)

#### Scenario: A puzzle is finished

- **WHEN** the last cell is filled correctly and no **unit** repeats a digit
- **THEN** the puzzle is recorded as solved

### Requirement: A puzzle can be reached at any rank

The system MUST let the player open a puzzle at each of the six **rank**s, and
MUST report having none left at a **rank** as an ordinary absence.

#### Scenario: A rank is chosen

- **WHEN** the player chooses a **rank**
- **THEN** a puzzle of that **rank** that they have not solved is opened

#### Scenario: A rank with nothing left

- **WHEN** the player has solved every puzzle at a **rank**
- **THEN** that is shown as nothing left at that **rank**, and play is not
  blocked, failed, or gated (constraint 1)

### Requirement: The stored settings can be changed by the player

The system MUST offer a screen where the settings the app stores can be read and
changed, and MUST keep every one of them off unless the player turns it on.

#### Scenario: A setting is changed

- **WHEN** a setting is turned on and the app is restarted
- **THEN** it is still on

#### Scenario: The defaults are what a new player gets

- **WHEN** a player who has changed nothing opens the settings
- **THEN** auto-check and strict mode are both off (D-04, constraint 1)

#### Scenario: A setting nothing acts on yet

- **WHEN** a setting is shown that no implemented behaviour reads
- **THEN** it is marked as not yet in effect, because a control that appears to
  work and does nothing is worse than one that is absent

### Requirement: Every pad key announces its name, never its glyph

The system MUST give each key on the number pad a spoken name — "Erase",
"Undo", "Notes", "Fill notes", or the digit — and MUST NOT include the symbol
drawn on it in that announcement. Each key MUST remain pressable by the
assistive technology that reads it.

The pad draws ⌫, ↶, ✎, and ⁙. Read aloud those are noise at best and nothing at
worst, and a key announced as "Notes ✎" buries the only word that carries
meaning. This is the same rule constraint 5 applies to the grid, one layer out:
the symbol is decoration, and the name is the state.

#### Scenario: A key drawn as a symbol

- **WHEN** a key whose face is a symbol is reached by a screen reader
- **THEN** it is announced by its name alone, with the symbol left unspoken

#### Scenario: A digit key

- **WHEN** a digit key is reached by a screen reader
- **THEN** it is announced as that digit, because there the face and the name
  are the same word

#### Scenario: A named key can still be pressed

- **WHEN** a key is announced by name
- **THEN** the assistive technology can activate it — naming a button that
  cannot be pressed is a worse failure than naming it badly

#### Scenario: A held key says so

- **WHEN** a digit is held in digit-first input, or notes mode is on
- **THEN** the key that is in force reports itself as selected, so the mode is
  readable without seeing which key is painted differently (constraint 5)

### Requirement: Asking for less motion silences all of it

The system MUST honour the reduce-effects setting and the operating system's
reduce-motion setting across the grid and its controls, and MUST keep every
control working when they are on.

#### Scenario: Motion is reduced

- **WHEN** either the in-app setting or the operating system's is on
- **THEN** the controls stop animating and the haptics fall silent — a player
  who asked for less asked for less of all of it

#### Scenario: Play is unaffected

- **WHEN** motion is reduced
- **THEN** every digit, erase, and undo still works, because reducing motion
  removes decoration and never function
