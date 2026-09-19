# Delta for persistence

## ADDED Requirements

### Requirement: Which lessons have been seen is recorded

The system MUST record that a **lesson** has been seen at the moment it is
completed or skipped, MUST keep that record across app kills and **season**
rotation, and MUST treat a player with no such record as having seen nothing
rather than as an error.

#### Scenario: A lesson is seen

- **WHEN** a **lesson** is completed or skipped
- **THEN** it is recorded as seen before the puzzle opens, not at the end of the
  puzzle or the session (constraint 9)

#### Scenario: The record survives an app kill

- **WHEN** the app is killed immediately after a **lesson** is skipped
- **THEN** on relaunch that **lesson** still reads as seen, and does not fire
  again

#### Scenario: A season rotates

- **WHEN** a **season** ends and its map is rotated out
- **THEN** every seen **lesson** is still seen (D-17)

#### Scenario: A player who has seen nothing

- **WHEN** no **lesson** has ever been seen
- **THEN** that reads as none seen yet, and every **lesson** remains due on its
  own terms

#### Scenario: Replaying does not change the record

- **WHEN** a **lesson** that is already seen is replayed
- **THEN** the record is unchanged, because seen is not a count

## MODIFIED Requirements

### Requirement: Schema changes are versioned and migrations are tested

The system MUST carry an explicit schema version and MUST preserve existing saved
state across an upgrade.

#### Scenario: Upgrading from the previous schema

- **WHEN** the app is upgraded and the schema version has advanced
- **THEN** the migration runs once, and puzzles in progress, notes, statistics,
  settings, and seen **lesson**s survive it

#### Scenario: A migration is added

- **WHEN** the schema changes
- **THEN** a test covering the upgrade from each earlier version exists and
  passes before the change ships

#### Scenario: A database from before lessons existed

- **WHEN** a database written before **lesson**s were recorded is opened
- **THEN** it migrates, and the player reads as having seen no **lesson** rather
  than as having seen them all
