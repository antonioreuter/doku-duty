# notes

## Purpose

The player's working out: up to nine candidates in a cell, which is what the
technique ladder is actually made of.

Nothing above the singles can be solved without them. A naked triple means
holding three candidates across three cells while having eliminated from four or
five others; an X-wing means reading full candidate sets across two rows (D-09).
The **rank**s this capability serves are the ones the progression exists to
teach, and without candidates they are unplayable in practice rather than in
principle.

One property carries the whole thing: **a candidate's slot is a function of its
digit and nothing else.** 1 top-left, 5 centre, 9 bottom-right, in every cell of
every puzzle, whether the cell holds one candidate or nine and whatever order
they were marked in (D-10). That is what lets a player scan a dense board by
position instead of reading it. Notes that reflow when a candidate is removed are
the hidden reason an app feels bad — nobody reports it, because nobody can say
why the board became hard to read. The data model makes it structural: a
candidate is addressed by cell and digit, so removing one deletes a row the other
eight never referred to.

A cell holds either a value or candidates, never both, so a finished grid has no
notes by construction and needs no check to say so (D-16). Placing a value
therefore clears what was there — and undoing that placement puts every one of
them back, because changing your mind is not a reason to lose your thinking.

Candidates go stale the moment they stop being true, so **auto-cleanup** keeps
them honest: a placed digit is removed from every **peer** that carried it as a
candidate, on every placement, with no setting to stop it (D-12). Without that
the board disagrees with itself within about twenty moves and the player stops
trusting their own marks, which kills the feature the ladder rests on. The
cleanup rides on the placement that caused it, so one undo takes back both.

Two things make a densely marked board readable. **Candidate highlighting** lights
every cell holding the digit in hand — the one held in digit-first input, or the
one in the selected cell — whether it is marked there or placed there (D-13,
D-88). It is free, always on, and deliberately not the **digit sweep** perk, which
reveals where a digit *belongs* rather than where it already is. **Auto-notes**
marks every empty cell with each candidate its **peer**s do not already hold as a
value, in one action and one undo. It unions rather than replaces: hand-marked
candidates keep their slot and stay the player's, and what the fill adds is a
**generated note** (D-87). The two origins are told apart in storage and nowhere
else — on screen they are the same ink in the same slot (D-15).

Nothing here judges. A candidate that contradicts the solution, or a **peer**
holding that digit as a value, is marked exactly as any other and recorded
nowhere: notes are thinking out loud, and punishing exploration would undermine
the learning the whole ladder depends on (D-14). **Auto-cleanup** removes what a
placement has disproved and says nothing about it either. Every candidate is
written the moment it changes, never on a timer, because nobody gets a warning
before the OS reclaims the process (D-33) — and an action that changes many
candidates at once is written with that action, as one commit, so a board is
never found half filled.

## Requirements

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

### Requirement: Placing a value removes that candidate from every peer

The system MUST remove a placed digit as a candidate from all twenty **peer**s
of the cell it was placed in, MUST do so on every placement, and MUST NOT offer
any way to turn it off (D-12, **auto-cleanup**).

#### Scenario: A value lands among cells marked with that digit

- **WHEN** a value is placed in a cell whose **peer**s carry that digit as a
  candidate
- **THEN** the candidate is gone from every one of those **peer**s, and no other
  candidate in any of them moves or disappears

#### Scenario: A candidate outside the placement's units

- **WHEN** a value is placed and the same digit is a candidate in a cell that is
  not one of its **peer**s
- **THEN** that candidate is untouched, because **auto-cleanup** removes only
  what the placement disproves

#### Scenario: There is no setting for it

- **WHEN** the player looks for a way to stop **auto-cleanup**
- **THEN** there is none, in any menu or mode

#### Scenario: A cleaned candidate is not a mistake

- **WHEN** **auto-cleanup** removes a candidate the player had marked by hand
- **THEN** nothing is flagged, counted against the player, or shown as an error
  — the candidate simply goes (D-14, constraint 1)

#### Scenario: Erasing the value does not put them back

- **WHEN** the player erases a value that had triggered **auto-cleanup**
- **THEN** the **peer**s' candidates stay gone, because erase is a new action
  and not a reversal of the placement

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

### Requirement: Auto-notes fills every empty cell with its legal candidates

The system MUST, in one action, add to every cell holding no value each digit
that no **peer** of that cell already holds as a value, and MUST leave candidates
that are already marked exactly where they are (**auto-notes**).

#### Scenario: An untouched board is filled

- **WHEN** **auto-notes** runs on a board with no candidates marked
- **THEN** every empty cell carries each digit its **peer**s do not already hold
  as a value, each in the slot its digit owns

#### Scenario: A cell already carrying candidates

- **WHEN** **auto-notes** runs on a cell holding candidates the player marked
- **THEN** those candidates are still there and still count as the player's, and
  the cell gains the legal candidates it was missing

#### Scenario: A candidate the player had eliminated

- **WHEN** **auto-notes** runs on a cell from which the player had removed a
  candidate that is still legal
- **THEN** the candidate is marked again, because **auto-notes** means every
  legal candidate — and one undo takes the whole fill back

#### Scenario: Cells holding a value

- **WHEN** **auto-notes** runs
- **THEN** no cell holding a value or a given gains candidates, because a cell
  holds one or the other and never both (D-16)

#### Scenario: A wrong board is filled anyway

- **WHEN** **auto-notes** runs on a board carrying a value that contradicts the
  solution
- **THEN** the fill is computed from the values on the board as they stand, and
  nothing is flagged or corrected (D-14, constraint 1)

#### Scenario: The fill costs nothing

- **WHEN** the player runs **auto-notes**
- **THEN** it runs, with no charge, no meter, and no offer to watch anything

### Requirement: Candidate highlighting lights every cell holding a digit

The system MUST light every cell that holds the digit in question — as a
candidate or as a value — whenever a digit is held in digit-first input or the
selected cell holds one, MUST require no control of its own, and MUST NOT charge
for it (D-13, **candidate highlighting**).

#### Scenario: A digit is held

- **WHEN** a digit is held in digit-first input
- **THEN** every cell carrying it, as a candidate or as a value, is lit

#### Scenario: A cell holding a digit is selected

- **WHEN** a cell holding a value is selected in cell-first input
- **THEN** every cell carrying that digit, as a candidate or as a value, is lit

#### Scenario: An empty cell is selected

- **WHEN** a cell holding neither a value nor candidates is selected in
  cell-first input
- **THEN** nothing is lit, because there is no digit to light cells for

#### Scenario: Selection outranks highlighting

- **WHEN** a lit cell is also the selected cell or one of its **peer**s
- **THEN** the selection is what the player sees on it, because the current focus
  wins where highlights compete (D-49)

#### Scenario: A lit cell is told apart without colour

- **WHEN** a cell is lit
- **THEN** it holds the digit it is lit for, so the digit itself carries the
  state and colour is never the only signal (constraint 5)

#### Scenario: Highlighting is free

- **WHEN** the player uses **candidate highlighting**
- **THEN** nothing is spent, metered, or offered for sale — it is distinct from
  the **digit sweep** perk, which reveals where a digit *belongs*

### Requirement: Every note action can be undone

The system MUST undo note actions in reverse order alongside value actions, back
to the state the puzzle was opened in, and MUST reverse an action that changed
several cells in a single step.

#### Scenario: A marked candidate is undone

- **WHEN** undo is used after a candidate was marked
- **THEN** the candidate is gone and the rest of the cell is untouched

#### Scenario: A removed candidate is undone

- **WHEN** undo is used after a candidate was removed
- **THEN** the candidate is back in its own slot

#### Scenario: Notes and values share one history

- **WHEN** notes and values have been entered in a mixed order
- **THEN** undo reverses them in exactly that order, one action at a time

#### Scenario: A placement and its auto-cleanup are undone together

- **WHEN** undo is used after a placement that triggered **auto-cleanup**
- **THEN** one undo empties the cell, restores the candidates that cell held, and
  puts back every candidate the cleanup took from a **peer**

#### Scenario: A fill is undone in one step

- **WHEN** undo is used after **auto-notes**
- **THEN** one undo removes every candidate the fill added and leaves every
  candidate the player had marked exactly as it was

#### Scenario: A multi-cell action is one step, not many

- **WHEN** undo is used twice after **auto-notes** and one candidate marked by
  hand before it
- **THEN** the first undo reverses the whole fill and the second reverses the
  hand-marked candidate — the fill never unwinds a cell at a time

### Requirement: Note state is written as it changes

The system MUST write a note the moment it is marked or removed, never on a
timer, so that nothing is lost if the app stops (D-33, constraint 9). An action
that changes many candidates MUST be written with that action, as one commit,
and MUST NOT be deferred, buffered, or left until the app is backgrounded.

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

#### Scenario: The app is killed immediately after a fill

- **WHEN** the app stops right after **auto-notes**
- **THEN** the puzzle opens either with the whole fill or with none of it, and
  never part-way through one

#### Scenario: The app is killed immediately after auto-cleanup

- **WHEN** the app stops right after a placement that triggered **auto-cleanup**
- **THEN** the puzzle opens with the value placed and every cleaned candidate
  gone, rather than with candidates a **peer**'s value contradicts

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

The system MUST store every candidate as a **settled note**, whether the player
marked it or **auto-notes** did, and MUST NOT write a **provisional note**
(D-11, D-15).

#### Scenario: A candidate is stored

- **WHEN** the player marks a candidate
- **THEN** it is stored as a **settled note** they entered by hand

#### Scenario: A candidate the fill marks

- **WHEN** **auto-notes** marks a candidate
- **THEN** it is stored as a **settled note** whose origin is the fill — so the
  capability that adds the second ink inherits a store in which no existing row
  is provisional

### Requirement: A candidate records whether the player or the fill marked it

The system MUST store each candidate as a **generated note** when **auto-notes**
marked it and as a manual one when the player did, MUST draw the two
identically, and MUST treat a **generated note** the player changes as theirs
from then on (D-15).

#### Scenario: The fill's candidates and the player's are told apart in storage

- **WHEN** a cell holds both a candidate the player marked and one **auto-notes**
  added
- **THEN** each is stored with the origin that put it there

#### Scenario: They look the same

- **WHEN** a cell holds a **generated note** and a manual one
- **THEN** both are drawn in the **settled note** ink, in the slots their digits
  own, with nothing on screen distinguishing them

#### Scenario: The player takes one over

- **WHEN** the player removes a **generated note** and marks it again
- **THEN** it is stored as theirs, because they have now made that call
  themselves
