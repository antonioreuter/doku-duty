# puzzle-engine

## Purpose

What a puzzle *is* to the rest of the app, and what can honestly be said about
one.

Three questions are answered here, and they are kept apart on purpose. Whether a
puzzle has exactly one solution is settled by exhaustive search. What a puzzle
requires is settled by applying named techniques and reporting each deduction.
What a puzzle is *worth* — its **rank** — is the hardest technique it needed and
nothing else. Conflating the first two is how constraint 8 breaks: a technique
solver that fails to finish has run out of techniques, which is not the same
claim as the puzzle being ambiguous.

Grading is the load-bearing part. A puzzle graded Marshal that only needs a
hidden single does not mislabel one puzzle — it tells the player the whole ladder
is arbitrary, and D-07's argument for technique grading is that it is honest.
Honesty here is a property of a program, so the twelve techniques of D-57 are
each runnable and testable on their own, and each is asserted to deduce *nothing*
on a position it does not apply to. An over-eager technique grades puzzles easier
than they are, which is a defect that reaches a player as "this Ranger puzzle was
trivial" and reaches nobody as a bug report.

The engine reports; it never judges and never throws. Unsolvable, ambiguous, and
ungradable are things puzzles are, not faults to raise at whoever asked — and
whether a placement counts against a player belongs to the mistake model, not
here.

The capability also owns the puzzles themselves. They are generated offline and
shipped inside the app as a **pack** (D-32), which is what makes constraint 8 a
promise rather than a property: every shipped puzzle was checked by the
exhaustive search and graded by the grader before it was written, and the
**rank** on a row is what the grader said about that grid rather than what the
generator was asked for. Nothing about content needs a network — a fresh install
in airplane mode has all six **rank**s.

## Requirements

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
