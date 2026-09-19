# Delta for grid-input

## ADDED Requirements

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

## MODIFIED Requirements

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
