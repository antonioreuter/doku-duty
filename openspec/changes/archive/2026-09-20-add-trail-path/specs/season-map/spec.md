# Delta for season-map

## ADDED Requirements

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
