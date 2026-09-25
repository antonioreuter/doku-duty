# Delta for notes

## ADDED Requirements

### Requirement: On a killer board, notes keep their slots below the cage sum

The system MUST draw the candidates of every cell on a **killer** board in the
same fixed slots as on a classic board — 1 top-left, 5 centre, 9 bottom-right —
inset uniformly across the whole board so that no slot sits under a **cage sum**
(constraint 3, D-129).

#### Scenario: A cage's first cell holds candidates

- **WHEN** the first cell of a **cage** holds a candidate 1
- **THEN** the candidate and the **cage sum** are both fully readable, and
  neither overlaps the other

#### Scenario: The same digit in two cells of a killer board

- **WHEN** the same digit is a candidate in a **cage**'s first cell and in any
  other cell of the board
- **THEN** it occupies the same slot in both, because the inset is the same for
  every cell of the board

#### Scenario: A candidate is removed on a killer board

- **WHEN** one of several candidates is removed from a cell of a **killer** board
- **THEN** every remaining candidate stays exactly where it was

### Requirement: Auto-notes on a killer board does not do the arithmetic

The system MUST fill a **killer** board's empty cells with every digit their
**peer**s — **cage** mates included — do not already hold as a value, and MUST
NOT remove a candidate because a **cage sum** rules it out.

#### Scenario: A cage mate holds a value

- **WHEN** **auto-notes** runs on a cell whose **cage** mate holds a 7
- **THEN** 7 is not added to that cell

#### Scenario: A sum rules a digit out

- **WHEN** **auto-notes** runs on a two-cell **cage** whose **cage sum** is 3
- **THEN** its cells still receive every digit their **peer**s do not hold, not
  only 1 and 2 — the arithmetic is the player's, or a technique's, to do

## MODIFIED Requirements

### Requirement: Placing a value removes that candidate from every peer

The system MUST remove a placed digit as a candidate from every **peer** of the
cell it was placed in — the twenty on a classic board, and on a **killer** board
those twenty and its **cage** mates — whichever ink that candidate carries, MUST
do so on every placement, and MUST NOT offer any way to turn it off (D-12, D-130,
**auto-cleanup**).

#### Scenario: A value lands among cells marked with that digit

- **WHEN** a value is placed in a cell whose **peer**s carry that digit as a
  candidate
- **THEN** the candidate is gone from every one of those **peer**s, and no other
  candidate in any of them moves or disappears

#### Scenario: A value lands in a cage

- **WHEN** a value is placed on a **killer** board and a **cage** mate outside
  its row, column, and block carries that digit as a candidate
- **THEN** the candidate is gone from the **cage** mate too

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

#### Scenario: A hypothesis is cleaned like any other candidate

- **WHEN** a value is placed and a **peer** carries that digit as a **provisional
  note**
- **THEN** it is removed exactly as a **settled note** would be, because a
  placement disproves a hypothesis as surely as it disproves a derived candidate

#### Scenario: Undoing that placement restores the ink too

- **WHEN** undo is used after a placement that cleaned candidates in both inks
- **THEN** each one is back in its own slot *and* its own ink
