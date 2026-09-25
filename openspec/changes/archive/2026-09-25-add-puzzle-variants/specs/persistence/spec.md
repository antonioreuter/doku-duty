# Delta for persistence

## MODIFIED Requirements

### Requirement: Puzzles are stored with their solution, grade, and seed

The system MUST store each puzzle inside a versioned pack, carrying its solution,
the **rank** its hardest required technique implies, its seed, and — for a
**killer** puzzle — its **cage**s and **cage sum**s (D-32, D-127).

#### Scenario: A puzzle is read for play

- **WHEN** a puzzle is loaded
- **THEN** its clues, its solution, its **rank**, its seed, and its **cage**s if
  it has any are all available without any network call

#### Scenario: Selecting by rank

- **WHEN** a puzzle of a given **rank** is requested
- **THEN** one is returned from local storage, or the absence of any is reported
  as a normal result rather than an error

#### Scenario: Selecting by rank and kind

- **WHEN** a classic puzzle, or a **killer** one, of a given **rank** is
  requested
- **THEN** only a puzzle of that kind is returned, never one of the other

#### Scenario: A pack is replaced by a newer version

- **WHEN** a pack with a version newer than the stored one is installed
- **THEN** progress against puzzles the player has already solved is preserved

#### Scenario: An older or repeated pack version arrives

- **WHEN** a pack is offered whose version is older than or equal to the stored
  one — a cached response, or one that arrived out of order
- **THEN** it is ignored, because a pack version is immutable: the same version
  always means the same content

#### Scenario: A puzzle in progress survives the upgrade

- **WHEN** the app is upgraded to a version whose schema carries **cage**s, with
  a classic puzzle in progress
- **THEN** the puzzle, its values, and its notes are all there on reopening, and
  it is still a classic puzzle
