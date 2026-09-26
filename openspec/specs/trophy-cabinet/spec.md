# trophy-cabinet

## Purpose

The permanent layer of D-17's three. The **cabinet** keeps every **trophy** the
player has earned, the **unfiled** **award**s of the **season** in force, lifetime
and per-technique statistics, and the **lesson** list. A **season** rotating out
takes nothing from it (D-17). A **trophy** is minted at the moment it is earned
(D-124), and a **season** declares its own **award**s in its published document
(D-125).

## Requirements

### Requirement: The cabinet keeps everything permanently

The system MUST present a **cabinet** holding every **trophy** the player has
earned, the **award**s of the **season** in force that they have not, and their
lifetime and per-technique statistics. It MUST NOT remove a **trophy** or reduce
a statistic for any reason.

#### Scenario: The cabinet is opened

- **WHEN** a player opens the **cabinet**
- **THEN** it shows their earned **trophy**s, the **unfiled** **award**s of the
  **season** in force, and their lifetime and per-technique statistics

#### Scenario: A season rotates out

- **WHEN** a **season** is replaced by a successor
- **THEN** every **trophy** earned in the old one remains, keeping its name and
  its territory, and no statistic changes (D-17)

#### Scenario: A player who has earned nothing

- **WHEN** a player who has earned no **trophy** opens the **cabinet**
- **THEN** it shows the **season**'s **award**s as **unfiled** and states the
  statistics as zero, and nothing is described as missed or failed
  (constraint 1)

### Requirement: A trophy is minted when it is earned

The system MUST write a **trophy** at the moment the event that earns it is
recorded, in the same transaction, capturing what was earned and which
**season** it came from. It MUST NOT derive a **trophy** from other state at
read time. Every event that earns a **trophy** MUST reach the minting from a
real solve in the running app, not only from a test.

#### Scenario: A boss node is completed

- **WHEN** a **boss node** is recorded as completed
- **THEN** a **trophy** for it is minted in the same transaction, so it cannot
  exist without its cause or its cause without it (constraint 9, D-124)

#### Scenario: A season is completed

- **WHEN** the last **node** of a **season** is recorded as completed
- **THEN** a **trophy** for completing that **season** is minted

#### Scenario: A season completion records what closed it

- **WHEN** the **trophy** for completing a **season** is minted
- **THEN** it captures that **season**'s name and territory and the date, so
  that a later change can present it as a closed case without re-deriving
  anything (D-119, D-124)

#### Scenario: A month of dailies is completed

- **WHEN** every day of a calendar month is on the **calendar** as completed
- **THEN** a **trophy** for that month is minted (`docs/SPEC.md` §5.3)

#### Scenario: A later month is completed too

- **WHEN** a second calendar month is completed after a first already minted
- **THEN** it mints a **trophy** of its own, named for its month, and the
  **cabinet** shows each month's **trophy** in the place the **unfiled**
  **award** held

#### Scenario: A rank is reached

- **WHEN** a solve on the **trail**, in **free play**, or in the **daily
  challenge** raises the player to a **rank** that has an **award**
- **THEN** that **rank**'s **trophy** is minted in the same transaction as the
  **solve record**, along with every **rank** **award** below it not yet earned

#### Scenario: A rank held before the trophy could be minted

- **WHEN** a player who already holds a **rank** with an **award**, and has no
  **trophy** for it, completes any puzzle
- **THEN** the **trophy** is minted, dated at that solve

#### Scenario: The cabinet shows a trophy just earned

- **WHEN** a solve mints a **trophy** and the player opens the **cabinet**
- **THEN** the **trophy** is shown as earned, with no restart of the app

#### Scenario: The same trophy is earned twice

- **WHEN** an event that has already minted a **trophy** is recorded again
- **THEN** no second **trophy** appears, and the first keeps its original date

#### Scenario: The app is killed at the moment of earning

- **WHEN** the app is killed immediately after a **boss node** completes
- **THEN** either both the completion and its **trophy** are present on
  reopening, or neither is — never one alone

### Requirement: A season declares the awards it offers

The system MUST read the **award**s a **season** offers from the published
**season** document, MUST fall back to a compiled-in list when none is
published, and MUST NOT require a release to give a new **season** its own
**award**s.

#### Scenario: A season carries awards

- **WHEN** a published **season** declares its **award**s
- **THEN** the **cabinet** shows them, earned or **unfiled**, under that
  territory's name (D-125)

#### Scenario: A season declares none

- **WHEN** a **season** document carries no **award**s, or none is published at
  all
- **THEN** the compiled-in list is used and the **cabinet** is fully populated,
  because a **season** without a published document is an ordinary state and not
  a degraded one

#### Scenario: An award list is malformed

- **WHEN** a published **award** entry cannot be read
- **THEN** that entry is refused and the others are kept, and nothing about the
  **cabinet** fails

#### Scenario: A trophy outlives the season that declared it

- **WHEN** a **trophy** was minted under a **season** whose document is no
  longer available
- **THEN** it is still shown with the name and territory captured when it was
  minted, rather than as an unknown **trophy** (D-124)

#### Scenario: An award is renamed after it was earned

- **WHEN** a later publish renames an **award** the player has already earned,
  while its **season** is still in force
- **THEN** the **trophy** keeps the name it was minted with, and only players
  who have not yet earned it see the new name on the **unfiled** **award**
  (D-126)

### Requirement: An unearned award is unfiled, never hidden

The system MUST show the **award**s of the **season** in force that the player
has not earned, MUST describe them as **unfiled**, and MUST NOT present them as
missed, failed, expired, or locked.

#### Scenario: An award has not been earned

- **WHEN** the player has not earned an **award** the **season** in force offers
- **THEN** it is shown in place, marked **unfiled**, with no countdown and no
  language of failure (D-21, constraint 1)

#### Scenario: An award is earned

- **WHEN** the player earns an **award** that was **unfiled**
- **THEN** it becomes an earned **trophy** in the same place, so the gap the
  player was looking at is the thing that fills

#### Scenario: The season ends with awards unearned

- **WHEN** a **season** elapses with **award**s still **unfiled**
- **THEN** nothing is taken away and nothing is marked failed — the **season**
  simply stops being the one in force (D-20)

### Requirement: Earned and unfiled are distinguishable without colour

The system MUST carry the difference between an earned **trophy** and an
**unfiled** **award** in a glyph and in words as well as in colour, and MUST
announce which it is to a screen reader.

#### Scenario: Colour is removed

- **WHEN** the **cabinet** is rendered without colour
- **THEN** earned and **unfiled** remain distinguishable (constraint 5)

#### Scenario: A screen reader reads the cabinet

- **WHEN** a screen reader traverses the **cabinet**
- **THEN** every **trophy** says what it is and whether it is earned or
  **unfiled**, and every statistic says what it counts

### Requirement: Statistics are read, not recounted

The system MUST show lifetime and per-technique statistics from the counters
already kept, and MUST NOT maintain a second count of anything the rest of the
app already counts.

#### Scenario: Statistics are shown

- **WHEN** the **cabinet** shows puzzles solved, perfect solves, or the count
  for a technique
- **THEN** each is the value the existing counter holds, so the **cabinet** and
  the rest of the app cannot disagree

#### Scenario: A puzzle is solved while the cabinet is open

- **WHEN** a puzzle is completed and the player returns to the **cabinet**
- **THEN** the statistics reflect it without the **cabinet** having counted
  anything itself

### Requirement: Every lesson is replayable from the cabinet

The system MUST offer every **lesson** for replay from the **cabinet**, whether
or not the player has met the technique it teaches.

#### Scenario: The lesson list is opened

- **WHEN** a player opens the **lesson** list from the **cabinet**
- **THEN** every **lesson** is listed and replayable, and replaying one changes
  no progression state (D-106)

#### Scenario: The old route is gone

- **WHEN** a player looks for the **lesson** list under settings
- **THEN** it is not there, because the **cabinet** is where `docs/SPEC.md` §5.1
  places it

### Requirement: The cabinet needs no network and blocks no frame

The system MUST present the **cabinet** with no network at any point, and MUST
NOT read the database on the path to the first frame.

#### Scenario: First launch offline

- **WHEN** the app is installed and opened for the first time with no network
- **THEN** the **cabinet** is reachable and shows the compiled-in **award**s as
  **unfiled** with zeroed statistics

#### Scenario: The app starts

- **WHEN** the app builds its first frame
- **THEN** nothing the **cabinet** needs is read from the database until after
  that frame has painted

### Requirement: The cabinet shows the stamp balance

The system MUST show the player's **stamp** balance in the **cabinet**, read
from the recorded **earning**s, with no network, and MUST NOT show it on the
**trail** or the grid (D-134, D-114).

#### Scenario: A player with earnings

- **WHEN** a player who has earned 17 **stamp**s opens the **cabinet**
- **THEN** it shows a balance of 17

#### Scenario: A new player

- **WHEN** a player who has earned nothing opens the **cabinet**
- **THEN** it shows a balance of 0, as a number rather than an empty space or a
  prompt to get more

#### Scenario: The trail

- **WHEN** the **trail** is shown
- **THEN** no **stamp** count appears on it or on any **node** marker
