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
row, its column, and its block, and on a **killer** board every other cell of
its **cage** (D-130).

#### Scenario: A cell is selected

- **WHEN** a cell of a classic board is selected
- **THEN** its twenty peers are marked, and the selected cell itself remains
  distinguishable from them

#### Scenario: A cell of a killer board is selected

- **WHEN** a cell of a **killer** board is selected
- **THEN** its twenty peers and its **cage** mates are marked alike, because the
  same digit cannot repeat in any of them

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

The system MUST let the player open a puzzle at each of the six **rank**s, MUST
report having none left at a **rank** as an ordinary absence, and MUST mark the
**rank**s above the player's own without making any of them harder to open
(D-103). This route MUST remain available whatever the player's position on the
**trail**, because the **trail** is walked in order and a **rank** at its far
end would otherwise be unreachable — which is the gate D-103 refused (D-111).

#### Scenario: A rank is chosen

- **WHEN** the player chooses a **rank**
- **THEN** a puzzle of that **rank** that they have not solved is opened

#### Scenario: Free play is reachable from anywhere on the trail

- **WHEN** the player is at any **node** of any **season**, including the first
- **THEN** **free play** is reachable, and every one of the six **rank**s can be
  opened from it with no confirmation, no warning to dismiss, and no gate
  (constraint 1)

#### Scenario: A rank with nothing left

- **WHEN** the player has solved every puzzle at a **rank**
- **THEN** that is shown as nothing left at that **rank**, and play is not
  blocked, failed, or gated (constraint 1)

#### Scenario: A rank above the player's is marked

- **WHEN** a **rank** is harder than the player's own
- **THEN** it is shown as being above their **rank**

#### Scenario: A node naming a rank above the player's is marked the same way

- **WHEN** a **node** on the **trail** names a **rank** harder than the player's
  own
- **THEN** it carries the same mark, for the same reason, and opening it is no
  harder than opening any other **node**

#### Scenario: A marked rank opens exactly as any other

- **WHEN** the player chooses a **rank** above their own
- **THEN** a puzzle of that **rank** is opened, with no confirmation, no warning
  to dismiss, and no gate — and a **lesson** may precede it on a first
  encounter, on exactly the terms it would precede any other puzzle, skippable
  in one tap (constraint 1)

#### Scenario: A lesson is not a penalty for reaching upward

- **WHEN** a **lesson** precedes a puzzle at a **rank** above the player's own
- **THEN** it is the same **lesson**, shown for the same reason, as it would be
  at any other **rank** — triggered by a technique the player has not met, never
  by the **rank** being above theirs

#### Scenario: Solving a marked rank clears its mark

- **WHEN** the player completes a puzzle at a **rank** above their own
- **THEN** their **rank** becomes that **rank**, and that **rank** and every
  **rank** below it are no longer marked

#### Scenario: A puzzle solved in free play counts everywhere

- **WHEN** a puzzle is completed in **free play**
- **THEN** it writes a **solve record** on the same terms as one completed at a
  **node**, and it does not advance the **trail**

#### Scenario: The mark is not carried by colour alone

- **WHEN** a **rank** above the player's is shown
- **THEN** the mark is readable without relying on colour to carry it
  (constraint 5)

#### Scenario: The rank list paints before progression is known

- **WHEN** **free play** is opened
- **THEN** all six **rank**s are on screen on the first frame, with the marks
  applied once the player's **rank** has been read, and reading it is not on the
  path to that frame

### Requirement: The stored settings can be changed by the player

The system MUST offer a screen where the settings the app stores can be read and
changed, MUST keep every one of them off unless the player turns it on, and MUST
NOT show a setting the app no longer acts on.

#### Scenario: A setting is changed

- **WHEN** a setting is turned on and the app is restarted
- **THEN** it is still on

#### Scenario: The defaults are what a new player gets

- **WHEN** a player who has changed nothing opens the settings
- **THEN** **strict mode** is off, and with it both immediate flagging and the
  three-**mistake** cap (D-04, constraint 1)

#### Scenario: Strict mode is one row, not two

- **WHEN** the player looks for a way to flag errors without the
  three-**mistake** cap
- **THEN** there is no such setting, because the two behaviours are one switch

#### Scenario: A setting nothing acts on yet

- **WHEN** a setting is shown that no implemented behaviour reads
- **THEN** it is marked as not yet in effect, because a control that appears to
  work and does nothing is worse than one that is absent

#### Scenario: Turning strict mode on says what it does

- **WHEN** the player reads the **strict mode** row
- **THEN** it states both of its effects before it is turned on, because the
  only failure state in the product should never be a surprise

### Requirement: Every pad key announces its name, never its glyph

The system MUST give each key on the number pad a spoken name — "Erase",
"Undo", "Notes", "Fill notes", or the digit — and MUST NOT include the symbol
drawn on it in that announcement. Each key MUST remain pressable by the
assistive technology that reads it. Where a control carries a visible name, the
spoken name MUST be that same word, so that a player reading the screen and a
player hearing it are told the same thing.

The digit keys and **Erase** are drawn as symbols; the tools carry their names in
words. Read aloud a symbol is noise at best and nothing at worst, and a key
announced as "Notes ✎" buries the only word that carries meaning. This is the
same rule constraint 5 applies to the grid, one layer out: the symbol is
decoration, and the name is the state.

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

#### Scenario: A control the player can read and hear

- **WHEN** a control carries a visible name
- **THEN** a screen reader announces that same name, rather than a second
  wording for the same control

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

### Requirement: A glyph grows with dynamic type only until it fills its box

The system MUST scale a placed value's glyph and a candidate's glyph with the
reader's text size, MUST stop growing each one once it fills the cell or the
3×3 slot it occupies, and MUST NOT let either overflow that box at any text
size (D-92).

The grid cannot reflow: nine columns are nine columns at every text size, and
a cell is the width it is given divided by nine (D-84). Left uncapped, a
candidate passes its slot at roughly 1.2× and a value passes its cell at
roughly 1.8× — ordinary "Larger Text", not an accessibility extreme — and the
result is not large text but digits overlapping their neighbours.

#### Scenario: The default text size

- **WHEN** the grid is drawn at the reader's default text size
- **THEN** values and candidates are drawn at their own sizes, untouched by the
  cap, because both already fit

#### Scenario: Text larger than the box allows

- **WHEN** the reader's text size would make a candidate wider or taller than
  its slot
- **THEN** the candidate is drawn at the largest size that fits that slot, and
  never outside it

#### Scenario: A value at a large text size

- **WHEN** the reader's text size would make a value overflow its cell
- **THEN** the value is drawn at the largest size that fits the cell

#### Scenario: Type still does something

- **WHEN** the reader raises their text size from the default by a small amount
- **THEN** the glyphs are larger than they were, because the cap is a ceiling
  and not a fixed size

#### Scenario: A narrower grid caps sooner

- **WHEN** the same text size is used on a grid drawn at half the width
- **THEN** the glyphs cap at a smaller size, because the box is the cell rather
  than a constant

#### Scenario: Candidates keep their slots at every text size

- **WHEN** a cell holds all nine candidates at the largest text size
- **THEN** each is inside the slot its digit owns, so a grid at large type is
  read the same way as a grid at small type (D-10, constraint 3)

#### Scenario: The grid is resized

- **WHEN** the grid is drawn at one size and then at another without being
  rebuilt
- **THEN** the glyphs are measured against the new cell, not the old one

### Requirement: A pad key grows with dynamic type only until its row is full

The system MUST scale a number-pad key with the reader's text size, MUST stop
growing it once its row fills the width the pad was given, MUST NOT draw any key
below the 44pt minimum tap target, and MUST scale a key's glyph with the key
rather than with the text size (D-93, D-84).

The pad is five columns wide and cannot reflow. Left uncapped, five keys need
480pt at 2× — an ordinary "Larger Text" setting — against a 393pt phone, and the
row runs off the screen.

#### Scenario: The default text size

- **WHEN** the pad is drawn at the reader's default text size
- **THEN** every key is the 44pt minimum and its glyph is drawn at its own size,
  because both already fit

#### Scenario: Text larger than the row allows

- **WHEN** the reader's text size would make a row of five keys wider than the
  pad
- **THEN** each key is drawn at the largest size that fits that row, and no key
  is drawn outside the pad

#### Scenario: Type still does something

- **WHEN** the reader raises their text size from the default by a small amount
- **THEN** the keys are larger than they were, because the cap is a ceiling and
  not a fixed size

#### Scenario: A narrower pad caps sooner

- **WHEN** the same text size is used on a pad drawn at half the width
- **THEN** the keys cap at a smaller size, because the bound is the width the
  pad was given rather than a constant

#### Scenario: A pad too narrow for five keys

- **WHEN** the pad is given less width than five keys at the 44pt minimum need
- **THEN** the keys are still 44pt, because a key that cannot be hit is worse
  than a row that has to be cut

#### Scenario: The glyph does not outgrow its key

- **WHEN** a key is capped
- **THEN** its glyph is scaled by the size the key reached, so the key keeps the
  proportions it has at the default text size

### Requirement: The pad separates digits from tools

The system MUST draw the digit keys and the controls that are not digits as two
distinct groups, MUST give every control that is not a digit a visible name in
words, and MUST NOT rely on a symbol alone to say what a control does (D-100).

A symbol on a control the player meets once is a guess. `~` for the ink a note is
written in, and `⁙` for filling every empty cell with its candidates, are not
guessable by anyone who has not read the source. This is the rule this capability
already applies for a screen reader — the symbol is decoration and the name is
the state — applied to the player who can see the screen.

#### Scenario: A control that is not a digit

- **WHEN** the pad is drawn
- **THEN** every control that is not a digit carries its name in words

#### Scenario: Telling the two groups apart

- **WHEN** the player looks at the pad
- **THEN** the digit keys and the tools read as two groups rather than as one
  field of similar keys

#### Scenario: A digit key

- **WHEN** a digit key is drawn
- **THEN** it shows the digit and nothing else, because there the face and the
  name are the same

### Requirement: The tools row shows only the controls that have work to do

The system MUST show **Notes**, **Fill notes**, and **Undo** at all times, MUST
show the control that switches note ink only while notes mode is on, and MUST NOT
disable any control it shows.

Absent is not the same as disabled. A control that has nothing to act on is
removed, the way the pad itself is removed when an **attempt** ends — a control
that looks live and swallows the tap is the failure state, not an empty space
(constraint 1).

#### Scenario: A player who has not turned notes on

- **WHEN** the puzzle is opened and notes mode is off
- **THEN** the tools are **Notes**, **Fill notes**, and **Undo**, and the ink
  control is not on screen

#### Scenario: Notes mode is turned on

- **WHEN** the player turns notes mode on
- **THEN** the control that switches ink appears beside the others

#### Scenario: Notes mode is turned off again

- **WHEN** the player turns notes mode off
- **THEN** the ink control leaves, and the ink it was set to is remembered for
  the next time notes mode is on

#### Scenario: Nothing is ever greyed out

- **WHEN** any control is on screen
- **THEN** it is pressable, because this product has no disabled controls

#### Scenario: Which tool is in force

- **WHEN** notes mode is on, or a digit is held in digit-first input
- **THEN** the control that is in force is distinguishable by more than its
  colour (constraint 5)

### Requirement: A killer board draws its cages

The system MUST draw every **cage** of a **killer** puzzle as a dashed outline
inside its cells, and MUST show each **cage sum** at the top-left of the
**cage**'s first cell in reading order. Both MUST use only tokens that already
carry outlines and secondary text, adding no hue (constraint 4, D-129).

#### Scenario: A killer board is opened

- **WHEN** a **killer** puzzle is shown
- **THEN** every **cage** is outlined, every **cage sum** is readable, and the
  **unit** boundaries are still drawn as on a classic board

#### Scenario: A cage is told apart without colour

- **WHEN** the board is rendered without colour
- **THEN** every **cage** is still identifiable by its outline and its number,
  because neither is carried by a fill (constraint 5)

#### Scenario: A classic board is unchanged

- **WHEN** a classic puzzle is shown
- **THEN** it renders exactly as it did before **killer** existed

#### Scenario: The largest text size

- **WHEN** a **killer** board is shown at the largest supported text size on the
  smallest phone the app targets (D-84)
- **THEN** no **cage sum** is clipped or truncated

### Requirement: Free play serves classic puzzles only

The system MUST NOT open a **killer** puzzle from **free play**. **Killer** is
reached only through a **variant node** (D-127).

#### Scenario: A rank is chosen in free play

- **WHEN** the player chooses a **rank** in **free play**
- **THEN** a classic puzzle of that **rank** is opened, whatever **killer**
  puzzles the **pack** holds at that **rank**
