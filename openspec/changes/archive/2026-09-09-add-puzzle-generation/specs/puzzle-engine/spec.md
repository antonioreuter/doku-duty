# Delta for puzzle-engine

## ADDED Requirements

### Requirement: The app ships with playable puzzles

The system MUST carry a **pack** of pre-generated puzzles inside the installed
app, and MUST make it available to play without a network of any kind.

#### Scenario: A fresh install with no network

- **WHEN** the app is opened for the first time on a device that has never been
  online
- **THEN** puzzles are available to play, because the **pack** ships inside the
  app rather than being fetched

#### Scenario: Installing the pack does not delay the first frame

- **WHEN** the bundled **pack** is installed on first launch
- **THEN** the first frame is not held waiting for it

#### Scenario: The install is interrupted

- **WHEN** the app is killed part-way through installing the bundled **pack**
- **THEN** the next launch installs it again and ends with the whole **pack**
  present, because a partly written **pack** is never recorded as installed

#### Scenario: A launch after the pack is installed

- **WHEN** the app is opened again with the same **pack** version already
  installed
- **THEN** nothing is reinstalled and no puzzle the player has solved is
  forgotten

#### Scenario: The pack cannot be read

- **WHEN** the bundled **pack** is missing from the binary or cannot be parsed
- **THEN** it is reported for a developer and the player is shown nothing —
  no dialog, no error state, because this product has none (D-03)

### Requirement: Every shipped puzzle has exactly one solution

The system MUST verify, before a puzzle enters a **pack**, that it has exactly
one solution by exhaustive search, and MUST NOT ship one that is ambiguous,
unsolvable, or ungradable (D-08).

#### Scenario: A candidate puzzle is ambiguous

- **WHEN** generation produces a grid that can be completed more than one way
- **THEN** it is discarded rather than shipped, however well it would have graded

#### Scenario: A candidate puzzle is beyond the ladder

- **WHEN** generation produces a grid with one solution that no implemented
  technique can finish
- **THEN** it is discarded, because shipping it would put a guess-and-check
  puzzle in front of a player

#### Scenario: The shipped pack is audited

- **WHEN** every puzzle in the shipped **pack** is checked
- **THEN** each one reports exactly one solution, and that solution is the one
  stored beside it

### Requirement: A shipped rank is the grade the puzzle earned

The system MUST set each puzzle's **rank** from what the grader reports about
that puzzle, and MUST NOT set it from what the generator was asked to produce
(D-07, D-57).

#### Scenario: A puzzle grades differently from the request

- **WHEN** generation is asked for a Marshal puzzle and the grader reports the
  grid needs only a hidden single
- **THEN** the puzzle is either stored as Deputy or discarded, and is never
  stored as Marshal

#### Scenario: The shipped pack is audited against the grader

- **WHEN** every puzzle in the shipped **pack** is graded again
- **THEN** the grade returned matches the **rank** stored on it

### Requirement: There are puzzles at every rank, and running out is not a wall

The system MUST ship puzzles at all six **rank**s, and MUST report having none
left at a **rank** as an ordinary absence rather than an error or a locked state
(D-67 for the same principle applied to Stamps).

#### Scenario: Each rank has content

- **WHEN** the shipped **pack** is inspected
- **THEN** every one of the six **rank**s has at least one puzzle

#### Scenario: A rank is exhausted

- **WHEN** a player has solved every puzzle at a **rank**
- **THEN** that is reported as nothing left at that **rank**, and play is not
  blocked, failed, or gated behind anything

### Requirement: A shipped puzzle is a puzzle, not a nearly-finished grid

The system MUST NOT ship a puzzle carrying more than forty clues, at any
**rank**.

#### Scenario: A grid with almost every cell filled

- **WHEN** generation produces a uniquely solvable grid with more than forty
  clues
- **THEN** it is not shipped, however it grades — an eighty-clue grid is one full
  house from solved, and grades Greenhorn honestly while being no kind of puzzle

#### Scenario: The gentlest rank is still a puzzle

- **WHEN** a Greenhorn puzzle from the shipped **pack** is inspected
- **THEN** it carries no more than forty clues, and still needs nothing harder
  than a full house or a naked single

### Requirement: A pack is reproducible from its seed

The system MUST generate a **pack** deterministically, so that the same seed and
the same engine produce the same puzzles in the same order.

#### Scenario: The pack is regenerated

- **WHEN** generation is run twice with the same seed
- **THEN** the two **pack**s are identical, so a shipped **pack** can be
  re-derived and reviewed rather than trusted
