# Delta for rank-progression

## ADDED Requirements

### Requirement: The player holds a rank

The system MUST give the player a **rank**, which is the hardest **rank** at
which they have completed a puzzle, and MUST NOT lower it for any reason
(D-102).

#### Scenario: The first solve

- **WHEN** a player who has never completed a puzzle completes one at a **rank**
- **THEN** their **rank** becomes that **rank**

#### Scenario: A harder puzzle raises it

- **WHEN** the player completes a puzzle at a **rank** harder than their own
- **THEN** their **rank** becomes that **rank**

#### Scenario: An easier puzzle does not lower it

- **WHEN** the player completes a puzzle at a **rank** easier than their own
- **THEN** their **rank** is unchanged

#### Scenario: A player who has completed nothing

- **WHEN** the player has no **solve record**
- **THEN** their **rank** is Greenhorn, and this is reported as a starting
  position rather than an absence or an error

#### Scenario: Nothing takes a rank away

- **WHEN** a **season** rotates, a **mistake** is recorded, an **attempt** ends
  in **strict mode**, or a puzzle is abandoned
- **THEN** the player's **rank** is unchanged (D-17, constraint 1)

### Requirement: Completing a puzzle writes a solve record

The system MUST write a **solve record** when a puzzle is completed, durably and
at the moment of completion, and MUST write its parts together so that none can
survive without the others.

#### Scenario: A puzzle is completed

- **WHEN** the board is filled and matches the puzzle's solution
- **THEN** the puzzle is marked solved, the lifetime counters rise, the counter
  for each technique the puzzle required rises, and the **attempt**'s perfection
  is recorded

#### Scenario: The write survives an app kill

- **WHEN** the app is killed immediately after a puzzle is completed
- **THEN** on relaunch the **solve record** is present in full, and the player's
  **rank** reflects it (constraint 9)

#### Scenario: A solved puzzle is not offered again

- **WHEN** the player chooses a **rank** after completing a puzzle at it
- **THEN** a puzzle they have not solved is opened, and never the one just
  completed

#### Scenario: A puzzle completed twice counts once

- **WHEN** a puzzle that already has a **solve record** is completed again
- **THEN** the lifetime and technique counters do not rise a second time for it

#### Scenario: An abandoned puzzle records nothing

- **WHEN** the player leaves a puzzle unfinished, or an **attempt** ends in
  **strict mode** without the board being solved
- **THEN** no **solve record** is written and no counter moves

### Requirement: A solve records the techniques the puzzle required

The system MUST record the techniques a completed puzzle actually required, as
reported by the grader, and MUST NOT infer them from the puzzle's **rank**.

#### Scenario: The techniques are the grader's answer

- **WHEN** a **solve record** is written
- **THEN** the techniques counted are the ones the grader reports the puzzle's
  solution needed

#### Scenario: A rank is not a technique list

- **WHEN** a puzzle of a given **rank** required fewer techniques than that
  **rank** permits
- **THEN** only the techniques it required are counted, not every technique the
  **rank** allows (D-07, D-57)

#### Scenario: Grading never sits on the input path

- **WHEN** the player places a digit, erases, or undoes
- **THEN** no grading runs as part of that action (constraint 2)

### Requirement: A technique is unlocked by solving a puzzle that required it

The system MUST report a technique as a **technique unlock** once a completed
puzzle has required it, derived from that technique's counter rather than stored
as a second fact (D-104).

#### Scenario: A technique becomes unlocked

- **WHEN** a **solve record** counts a technique for the first time
- **THEN** that technique reads as unlocked

#### Scenario: An untouched technique

- **WHEN** no completed puzzle has required a technique
- **THEN** that technique does not read as unlocked, and this is reported as not
  yet met rather than as locked or withheld (constraint 1)

#### Scenario: Unlocks are permanent

- **WHEN** a **season** rotates out
- **THEN** every **technique unlock** is unchanged (D-17)

### Requirement: Rank and unlocks are available without network

The system MUST answer the player's **rank** and their **technique unlock**s from
local state alone.

#### Scenario: Offline

- **WHEN** the device has no network
- **THEN** the player's **rank** and **technique unlock**s are reported in full,
  and a puzzle can still be completed and recorded
