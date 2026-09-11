# Delta for notes

## ADDED Requirements

### Requirement: A cell holds up to nine candidates in fixed positions

The system MUST let the player mark any of the digits one to nine as a **settled
note** in an empty cell, and MUST draw each candidate in the slot its digit owns
— 1 top-left, 5 centre, 9 bottom-right — whatever else the cell holds (D-09,
D-10).

#### Scenario: A candidate is marked

- **WHEN** a digit is marked as a **settled note** in an empty cell
- **THEN** it appears in that digit's slot, and no other cell changes

#### Scenario: A candidate is removed

- **WHEN** one of several candidates in a cell is removed
- **THEN** it disappears from its own slot and every remaining candidate stays
  exactly where it was

#### Scenario: A cell holding one candidate and a cell holding nine

- **WHEN** the same digit is a candidate in two cells holding different numbers
  of candidates
- **THEN** it occupies the same slot in both, because a slot is a function of the
  digit alone

#### Scenario: A candidate is told apart from a value

- **WHEN** a cell holds candidates and another holds a value
- **THEN** the candidate is drawn smaller and in the **settled note** ink, so
  the two are never confused for one another

#### Scenario: Marking a candidate that is already there

- **WHEN** a digit already marked in a cell is marked again
- **THEN** it is removed, so one control both marks and unmarks

### Requirement: Notes are a mode, not a modifier

The system MUST offer a notes mode that stays in force across many entries, MUST
start each puzzle in value mode, and MUST let a single entry be made in the other
mode without leaving that mode.

#### Scenario: The mode persists across entries

- **WHEN** notes mode is on and several digits are entered in turn
- **THEN** every one of them is a **settled note**, until the mode is turned off

#### Scenario: A puzzle is opened

- **WHEN** a puzzle is opened
- **THEN** input is in value mode, whatever mode the last puzzle ended in

#### Scenario: One entry in the other mode

- **WHEN** a pad digit is long-pressed
- **THEN** that one entry is made in the opposite mode, and the mode in force is
  unchanged afterwards

### Requirement: A cell holds either a value or notes, never both

The system MUST clear a cell's candidates when a value is placed there, and MUST
restore them if that placement is undone (`docs/SPEC.md` §3.2, D-16).

#### Scenario: A value lands on a cell with candidates

- **WHEN** a value is placed in a cell holding candidates
- **THEN** the candidates are cleared, so a finished grid has no notes left by
  construction and needs no check to say so

#### Scenario: That placement is undone

- **WHEN** the placement is undone
- **THEN** the cell is empty again and every candidate it held is back in its own
  slot — the player's working out is not lost to a change of mind

#### Scenario: A cell holding only candidates is erased

- **WHEN** erase is used on a cell that holds candidates and no value
- **THEN** the candidates are cleared, because erase empties a cell whichever of
  the two it holds — and undoing that erase brings them back

#### Scenario: A candidate is marked in a cell holding a value

- **WHEN** a digit is marked as a note in a cell that already holds a value
- **THEN** nothing is marked, because the cell cannot hold both

### Requirement: Notes can be marked digit-first

The system MUST let the player hold a digit and mark it across cells, when both
digit-first input and notes mode are in force.

#### Scenario: A digit is swept across cells

- **WHEN** a digit is held in notes mode and several empty cells are tapped
- **THEN** each one gains that candidate, and the digit stays held

#### Scenario: A digit is long-pressed while another is held

- **WHEN** a pad digit is long-pressed in digit-first input
- **THEN** it is held like any other press, because a held digit is swept many
  times and there is no single entry for the other mode to apply to

#### Scenario: Changing what a digit press writes puts down what is held

- **WHEN** the notes toggle is used while a digit is held
- **THEN** the digit is put down, so the next tap cannot write the wrong kind

#### Scenario: A cell already holding the held candidate

- **WHEN** a tapped cell already has the held digit as a candidate
- **THEN** the candidate is removed from it, so one sweep both marks and unmarks

### Requirement: Every note action can be undone

The system MUST undo note actions in reverse order alongside value actions, back
to the state the puzzle was opened in.

#### Scenario: A marked candidate is undone

- **WHEN** undo is used after a candidate was marked
- **THEN** the candidate is gone and the rest of the cell is untouched

#### Scenario: A removed candidate is undone

- **WHEN** undo is used after a candidate was removed
- **THEN** the candidate is back in its own slot

#### Scenario: Notes and values share one history

- **WHEN** notes and values have been entered in a mixed order
- **THEN** undo reverses them in exactly that order, one action at a time

### Requirement: Note state is written as it changes

The system MUST write a note the moment it is marked or removed, never on a
timer, so that nothing is lost if the app stops (D-33, constraint 9).

#### Scenario: The app is killed immediately after a note

- **WHEN** the app stops right after a candidate is marked
- **THEN** that candidate is in its slot when the puzzle is next opened

#### Scenario: A rapid sequence of notes

- **WHEN** several candidates are marked in quick succession
- **THEN** every one of them is written, and none is dropped or coalesced

#### Scenario: Writing does not delay the player

- **WHEN** a candidate is marked
- **THEN** it is on screen without waiting for the write, and the next tap is
  accepted immediately (constraint 2)

#### Scenario: A part-noted puzzle is reopened

- **WHEN** a puzzle with candidates in several cells is opened again
- **THEN** each candidate is in the cell and the slot it was left in

### Requirement: A note is never a mistake

The system MUST NOT treat a candidate as wrong, count it against the player, or
correct it, whatever the puzzle's solution says (D-14).

#### Scenario: A candidate that cannot be right

- **WHEN** a digit is marked as a candidate in a cell whose solution is another
  digit
- **THEN** it is drawn exactly as any other candidate, and nothing is recorded
  against the player

#### Scenario: A candidate that contradicts a peer

- **WHEN** a digit is marked as a candidate in a cell whose **peer** already
  holds that digit as a value
- **THEN** it is still marked, because notes are thinking out loud and this
  change flags none of it

### Requirement: Every candidate this capability writes is a settled note

The system MUST store each candidate the player marks as a **settled note** that
the player entered, and MUST NOT write a **provisional note** or a generated one
(D-11, D-15).

#### Scenario: A candidate is stored

- **WHEN** the player marks a candidate
- **THEN** it is stored as a **settled note**, entered by hand — so the
  capabilities that add generated and **provisional note**s inherit a store whose
  existing rows mean exactly one thing
