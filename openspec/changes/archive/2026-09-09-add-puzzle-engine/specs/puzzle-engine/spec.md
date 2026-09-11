# Delta for puzzle-engine

## ADDED Requirements

### Requirement: A puzzle is a grid of cells with peers and units

The system MUST represent a puzzle as 81 cells, each belonging to exactly three
**units** — a row, a column, and a block — and MUST report, for any cell, the
cells it shares a **unit** with.

#### Scenario: A cell's units

- **WHEN** the **units** containing a cell are requested
- **THEN** exactly three are returned, and each contains nine cells including
  that one

#### Scenario: A cell's peers

- **WHEN** the peers of a cell are requested
- **THEN** exactly twenty are returned, being every other cell sharing a **unit**
  with it, each listed once

#### Scenario: Candidates for an empty cell

- **WHEN** the candidates for an empty cell are requested
- **THEN** the digits one to nine remain, less every digit already placed in any
  of its peers

### Requirement: The solver reports what it deduced, not only the answer

The system MUST solve a puzzle by applying named techniques, and MUST be able to
report each deduction it made: the technique used, the cell or cells affected,
and the digits placed or eliminated.

#### Scenario: A single step is requested

- **WHEN** the next deduction is requested for a grid
- **THEN** one deduction is returned, naming the technique that produced it and
  what it changed, without solving the rest of the puzzle

#### Scenario: The easiest applicable technique is preferred

- **WHEN** more than one technique applies to a grid
- **THEN** the one earliest in the ladder is reported, so a puzzle is never
  graded harder than it needs to be

#### Scenario: No technique applies

- **WHEN** no implemented technique can make progress on an unsolved grid
- **THEN** that is reported as a normal answer, not an error, and the grid is
  returned unchanged

#### Scenario: A solved grid

- **WHEN** the next deduction is requested for a completed grid
- **THEN** the grid is reported as solved and no deduction is invented

### Requirement: Every technique in the rank ladder is implemented and named

The system MUST implement each technique named in D-57 — full house, naked
single, hidden single, naked pair, pointing pair, box-line reduction, naked
triple, hidden pair, X-wing, swordfish, XY-wing, and simple chains — and MUST
identify deductions by that name.

#### Scenario: A technique is applied

- **WHEN** a deduction is made
- **THEN** it names one of the techniques in the ladder, and never a technique
  outside it

#### Scenario: A technique is asked for on its own

- **WHEN** a single named technique is run against a grid
- **THEN** it reports only the deductions that technique justifies, so it can be
  tested in isolation from the rest of the solver

### Requirement: Uniqueness is verified independently of the techniques

The system MUST determine whether a puzzle has exactly one solution by exhaustive
search, separately from the technique solver, and MUST distinguish no solution,
one solution, and more than one (D-08).

#### Scenario: A puzzle with one solution

- **WHEN** a puzzle with exactly one solution is checked
- **THEN** it is reported as unique, and the solution is available

#### Scenario: A puzzle with several solutions

- **WHEN** a puzzle that can be completed more than one way is checked
- **THEN** it is reported as ambiguous, and is not reported as unique merely
  because the technique solver could not finish it

#### Scenario: A puzzle with no solution

- **WHEN** a grid whose clues contradict is checked
- **THEN** it is reported as unsolvable, distinctly from being ambiguous

#### Scenario: A puzzle the techniques cannot finish

- **WHEN** a puzzle has exactly one solution but no implemented technique can
  reach it
- **THEN** uniqueness still reports one solution, because the two questions are
  answered separately

### Requirement: A puzzle is graded by the hardest technique it requires

The system MUST report, for a puzzle, the hardest technique needed to solve it
without guessing and the **rank** that technique implies, and MUST NOT grade by
clue count (D-07, D-57).

#### Scenario: A puzzle needing only singles

- **WHEN** a puzzle solvable by full houses and naked singles alone is graded
- **THEN** it is Greenhorn

#### Scenario: A puzzle needing one harder technique

- **WHEN** a puzzle is solvable using techniques up to and including a single
  harder one
- **THEN** its **rank** is the one that technique belongs to, and not a higher
  one

#### Scenario: Clue count does not decide a grade

- **WHEN** two puzzles requiring the same hardest technique have different
  numbers of clues
- **THEN** they receive the same **rank**

#### Scenario: A puzzle beyond the ladder

- **WHEN** a puzzle cannot be solved by any implemented technique
- **THEN** it is reported as ungradable rather than assigned the highest **rank**

#### Scenario: Every technique a puzzle needed

- **WHEN** a puzzle is graded
- **THEN** every technique the solve used is reported alongside the hardest one,
  so a per-technique count can be kept without solving the puzzle again

### Requirement: The engine answers questions about a placement

The system MUST report whether a digit placed in a cell conflicts with a peer,
whether it disagrees with the puzzle's solution, whether it replaces a value that
was already correct, and whether a grid is complete. It MUST report these as
separate facts and MUST NOT combine them into a verdict about the player.

#### Scenario: A digit repeats in a unit

- **WHEN** a digit is placed in a cell that already has that digit among its
  peers
- **THEN** the conflict is reported, along with the cells that conflict

#### Scenario: A digit is legal but wrong

- **WHEN** a digit is placed that breaks no **unit** but differs from the
  solution
- **THEN** it is reported as disagreeing with the solution, distinctly from
  conflicting with a peer

#### Scenario: The grid is finished

- **WHEN** every cell holds a digit and no **unit** repeats one
- **THEN** the grid is reported complete

#### Scenario: A digit replaces a correct one

- **WHEN** a digit is placed in a cell that already holds the solution's digit
- **THEN** the engine reports that a correct value was overwritten, and reports
  nothing further about it — whether that counts against the player is not this
  layer's decision (D-05)

### Requirement: The engine reports; it never throws at the player

The system MUST return every outcome — including unsolvable, ambiguous, and
ungradable — as a value, and MUST NOT signal any of them by throwing.

#### Scenario: A malformed grid is supplied

- **WHEN** a grid is supplied that is the wrong length, or holds a character that
  is not a digit or a blank
- **THEN** it is rejected as invalid input with a value describing why, and
  nothing above it is asked to handle an exception

#### Scenario: An ordinary bad puzzle

- **WHEN** a puzzle is unsolvable, ambiguous, or ungradable
- **THEN** the answer is returned as a result, because those are things puzzles
  are, not faults
