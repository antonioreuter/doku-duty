# season-map

## Purpose

The seasonal layer of D-17's three, and the spine of the session. A **season**
is a six-week territory of 42 **node**s (D-18) that the player walks in order,
and it rotates out and is replaced without taking anything permanent with it.

A **node** is a puzzle, the **season**'s rule twist, a reward, or a boss, and it
names a **rank** rather than a puzzle (D-110) — the board is resolved from the
installed **pack** when the **node** is opened, so a **pack** top-up can never
strand a **node** or revert a completion.

The **trail** is walked in order, and that order is not a lock (D-108). Nothing
is earned and then withheld: a **node** further along is somewhere the player
has not been yet, and walking there is the activity. Nothing is taken away
either — no **node** expires (D-20), no **attempt** ends a **season**, a **boss
node** retries forever (D-22), and a **season** whose six weeks elapse with no
successor holds open rather than closing (D-109).

The ladder stays open beside it. **Free play** reaches any **rank** at any time
(D-111), which is what keeps D-103's guarantee true on a trail where Legend is
forty **node**s away.

## Requirements

### Requirement: A season is 42 nodes of four types

The system MUST present a **season** as exactly 42 **node**s in a fixed order,
composed of 30 puzzle **node**s, 6 **variant node**s, 4 **chest node**s, and 2
**boss node**s, with the **chest node**s at 25/50/75/100% of the trail and the
**boss node**s at its midpoint and its finale (D-18).

#### Scenario: The trail is opened

- **WHEN** the **trail** is opened
- **THEN** it presents 42 **node**s in order, each carrying its **node type**,
  every one of them reachable by scrolling

#### Scenario: Chests and bosses fall where the season says

- **WHEN** a **season** definition is loaded
- **THEN** its 4 **chest node**s stand at a quarter, a half, three quarters, and
  the end of the trail, and its 2 **boss node**s at the midpoint and the finale

#### Scenario: A season that does not compose correctly is refused

- **WHEN** a **season** definition does not hold exactly 42 **node**s in the
  composition above
- **THEN** it is not used, and the **season** already in force continues
  unchanged

### Requirement: A node names a rank, not a puzzle

The system MUST resolve a puzzle-bearing **node**'s puzzle from the **pack** at
the moment the **node** is opened, using the **rank** the **node** names — a
**killer** puzzle for a **variant node** and a classic one for every other — and
MUST NOT store a puzzle identity in the **season** definition (D-110, D-127).

#### Scenario: A node is opened

- **WHEN** a puzzle **node** or **boss node** is opened
- **THEN** a classic puzzle of that **node**'s **rank** that the player has not
  solved is opened

#### Scenario: A variant node is opened

- **WHEN** a **variant node** is opened
- **THEN** a **killer** puzzle of that **node**'s **rank** that the player has
  not solved is opened

#### Scenario: A variant node with no killer puzzle left

- **WHEN** a **variant node**'s **rank** has no unsolved **killer** puzzle left
- **THEN** it is reported as an ordinary absence exactly as any other **node**'s
  would be, and a classic puzzle is not substituted in its place

#### Scenario: The pack is topped up

- **WHEN** a newer **pack** version installs
- **THEN** every **node** still resolves, and no completed **node** reverts

#### Scenario: A rank has nothing left

- **WHEN** a **node**'s **rank** has no unsolved puzzle left in the **pack**
- **THEN** that is reported as an ordinary absence, and play is not blocked,
  failed, or gated (constraint 1)

### Requirement: The trail is walked in order

The system MUST open a **season** with its first **node** current, MUST make
**node** N+1 the **current node** when **node** N is completed, and MUST NOT
present a **node** further along than the player has reached as withheld,
failed, or lost (D-108).

#### Scenario: A node is completed

- **WHEN** the **current node** is completed
- **THEN** the next **node** on the trail becomes the **current node**

#### Scenario: A node further along is shown

- **WHEN** a **node** the player has not reached is shown
- **THEN** it reads as **not yet reached**, and no text presented to the player
  calls it locked (D-108)

#### Scenario: A completed node can be returned to

- **WHEN** the player opens a **node** they have already completed
- **THEN** it opens, and completing it again changes no progress and takes
  nothing away

### Requirement: Node state carries a signal that is not colour

The system MUST show each **node** as completed, current, or **not yet
reached**, MUST draw the **current node** larger than the others as well as
differently coloured, and MUST keep a **chest node** and a **boss node**
identifiable as such in every state.

#### Scenario: The current node is found without reading

- **WHEN** the **trail** is opened after any length of absence
- **THEN** the **current node** is the largest **node** on screen, and its state
  does not depend on colour to be read (constraint 5)

#### Scenario: Colour is removed

- **WHEN** the **trail** is rendered without colour
- **THEN** completed, current, and **not yet reached** remain distinguishable,
  and **chest node**s and **boss node**s remain identifiable (constraint 5)

#### Scenario: A season repaints the trail

- **WHEN** a **season** carries its own palette
- **THEN** it repaints the trail's surfaces and props only, and no **state
  colour** changes (constraint 4, D-55)

### Requirement: The trail is drawn as a linked path

The system MUST draw a continuous line along the **trail** joining each **node**
to the one before it, MUST draw that line behind the **node** markers so it
never obscures a marker, its glyph, or its label, and MUST NOT vary the line by
**node** state, **node type**, or **rank**.

#### Scenario: The trail is opened

- **WHEN** the **trail** is opened
- **THEN** a continuous line joins all 42 **node**s in order, following the
  alternating left-right placement of the markers

#### Scenario: The line carries no state

- **WHEN** some **node**s are completed and others are **not yet reached**
- **THEN** the line is identical along its whole length, and the stretch behind
  completed **node**s is indistinguishable from the stretch behind **node**s the
  player has not reached (D-113)

#### Scenario: The player has asked for larger text

- **WHEN** the **trail** is rendered at any text scale the OS offers
- **THEN** the line still meets every **node** marker, and a marker's label
  growing does not move the marker out from under it (D-114)

#### Scenario: The line is not a second signal for progress

- **WHEN** the **trail** is rendered without colour
- **THEN** completed, **current node**, and **not yet reached** remain
  distinguishable by the markers alone, and the line contributes nothing to
  telling them apart (constraint 5)

#### Scenario: The line introduces no new colour

- **WHEN** the line is drawn
- **THEN** it uses a token from the existing palette and no **state colour**
  takes on a second job (constraint 4, D-53)

#### Scenario: A screen reader walks the trail

- **WHEN** a screen reader traverses the **trail**
- **THEN** the line is not announced, and each **node**'s own label remains the
  only spoken account of its state

#### Scenario: The trail is opened before progress is known

- **WHEN** the **trail** paints its first frame, before progress has been read
- **THEN** the line is already drawn in full, because it depends only on the
  **season** and not on the database

#### Scenario: First launch offline

- **WHEN** the **trail** is opened with no network at any time
- **THEN** the line is drawn exactly as it is with a network, because it is
  derived from the **season** already in memory

### Requirement: A boss node retries without limit or cost

The system MUST let a **boss node** be attempted again any number of times, MUST
charge nothing for an attempt, and MUST NOT end, lock, or set back a **season**
on a failed attempt (D-22, constraint 1).

#### Scenario: A boss attempt is abandoned

- **WHEN** the player leaves a **boss node** without completing it
- **THEN** it can be opened again immediately, at no cost, with no attempt
  counter presented as a limit

#### Scenario: Strict mode ends an attempt at a boss

- **WHEN** an **attempt** at a **boss node** ends on the third **mistake** in
  **strict mode**
- **THEN** starting again is offered at once and costs nothing, and the
  **season** is unchanged

### Requirement: A chest node is opened, never failed

The system MUST let a **chest node** be opened directly, MUST record it as
completed when opened, and MUST NOT require a puzzle, a payment, or a network
call to open one.

#### Scenario: A chest is opened

- **WHEN** the player opens a **chest node**
- **THEN** it is recorded as completed and the next **node** becomes current

#### Scenario: A chest is opened offline

- **WHEN** a **chest node** is opened with no network
- **THEN** it opens and completes exactly as it does online

### Requirement: Nodes never expire

The system MUST keep every **node** in the current **season** completable for as
long as that **season** is in force, regardless of how many days pass between
sessions, and MUST NOT reduce, reset, or withdraw progress for time elapsed
(D-20, constraint 1).

#### Scenario: The player returns after a long absence

- **WHEN** the player opens the **trail** after many days away
- **THEN** every completed **node** is still completed, the **current node** is
  unchanged, and nothing has been withdrawn

### Requirement: A season with no successor holds open

The system MUST continue to present the current **season** as playable when its
six weeks have elapsed and no later **season** is defined, MUST stop presenting
a countdown rather than presenting an elapsed one, and MUST NOT close, empty, or
withdraw the trail (D-109).

#### Scenario: The season runs out with no successor

- **WHEN** a **season**'s six weeks elapse and no later **season** is defined
- **THEN** the trail stays open and every incomplete **node** stays completable,
  and no countdown is shown

#### Scenario: A successor is defined

- **WHEN** a later **season** becomes available
- **THEN** it may be rotated in, and lifetime and per-technique statistics are
  unchanged by the rotation (D-17)

### Requirement: The trail does not need a network

The system MUST present a complete, playable **season** with no network at any
point, including on a device that has never been online.

#### Scenario: First launch offline

- **WHEN** the app is opened for the first time with no network
- **THEN** a full 42-**node** **season** is on the trail and every **node** type
  behaves as specified

#### Scenario: The season document cannot be fetched

- **WHEN** the **season** document cannot be fetched or cannot be read
- **THEN** the compiled-in **season** is used, and nothing about the failure is
  put in front of the player

### Requirement: The trail paints before progress is known

The system MUST show the trail's structure on the first frame, MUST apply
completion state once it has been read, and MUST NOT read the database on the
path to that frame.

#### Scenario: The trail is the first screen

- **WHEN** the app cold starts to the **trail**
- **THEN** the **season**'s name and the **node**s at the top of the trail are
  on the first frame, with completion state applied afterwards

#### Scenario: Nothing is offered before it is known

- **WHEN** the **trail** has painted but progress has not been read
- **THEN** no **node** offers a tap, and no **node** is shown as completed or
  current — an unread trail offers nothing rather than offering the wrong
  thing

### Requirement: A completed node is announced to the rest of the app

The system MUST signal that a **node** has been completed, carrying its **node
type**, at the point the completion is recorded.

#### Scenario: A node completes

- **WHEN** any **node** is recorded as completed
- **THEN** a completion carrying that **node**'s **node type** is signalled, so
  that a later capability can count it without inventing its own trigger
