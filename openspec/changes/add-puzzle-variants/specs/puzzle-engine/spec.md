# Delta for puzzle-engine

## ADDED Requirements

### Requirement: A killer puzzle is a grid divided into cages

The system MUST represent a **killer** puzzle as a classic 81-cell grid whose
cells are also divided, every cell exactly once, into **cage**s. Each **cage**
MUST carry a **cage sum**, and no digit may repeat within a **cage** (D-127).

#### Scenario: Every cell is in one cage

- **WHEN** a **killer** puzzle's **cage**s are read
- **THEN** every one of the 81 cells belongs to exactly one **cage**, and every
  **cage**'s cells are orthogonally connected

#### Scenario: A solved cage

- **WHEN** a **killer** puzzle's solution is checked against its **cage**s
- **THEN** the digits of every **cage** sum to its **cage sum**, with no digit
  repeated inside it

#### Scenario: A classic puzzle has no cages

- **WHEN** a classic puzzle is read
- **THEN** it has no **cage**s, and every answer the engine gives about it is
  exactly what it gave before **killer** existed

### Requirement: A killer puzzle is graded on the same ladder

The system MUST grade a **killer** puzzle by the hardest technique it requires,
on the same six-**rank** ladder as a classic puzzle, and MUST NOT assign it a
**rank** any other way (D-07, D-128).

#### Scenario: A killer puzzle is graded

- **WHEN** a **killer** puzzle is graded
- **THEN** its **rank** is the **rank** of the hardest technique — classic or
  **killer** — the solver needed to finish it

#### Scenario: A killer puzzle the techniques cannot finish

- **WHEN** no implemented technique can finish a **killer** puzzle
- **THEN** it is reported as ungradable, never as the highest **rank**, and it
  does not ship

### Requirement: The shipped pack carries killer puzzles at every rank

The system MUST ship **killer** puzzles at all six **rank**s, each unique and
graded exactly as a classic puzzle is, because a published **season** may name
any **rank** for a **variant node**.

#### Scenario: Each rank has killer content

- **WHEN** the shipped **pack** is inspected
- **THEN** every one of the six **rank**s has at least one **killer** puzzle

#### Scenario: A shipped killer puzzle is re-checked

- **WHEN** the shipped **pack** is audited
- **THEN** every **killer** puzzle has exactly one solution under its **cage**s,
  and grading it again gives the **rank** it shipped with

## MODIFIED Requirements

### Requirement: A puzzle is a grid of cells with peers and units

The system MUST represent a puzzle as 81 cells, each belonging to exactly three
**units** — a row, a column, and a block — and MUST report, for any cell, its
peers: the cells it shares a **unit** with, and on a **killer** puzzle also the
other cells of its **cage** (D-130). A **cage** is not a **unit**.

#### Scenario: A cell's units

- **WHEN** the **units** containing a cell are requested
- **THEN** exactly three are returned, and each contains nine cells including
  that one — on a **killer** puzzle as on a classic one

#### Scenario: A cell's peers

- **WHEN** the peers of a cell in a classic puzzle are requested
- **THEN** exactly twenty are returned, being every other cell sharing a **unit**
  with it, each listed once

#### Scenario: A cell's peers on a killer puzzle

- **WHEN** the peers of a cell in a **killer** puzzle are requested
- **THEN** the twenty are returned together with every other cell of its
  **cage**, each listed once however many ways it is a peer

#### Scenario: Candidates for an empty cell

- **WHEN** the candidates for an empty cell are requested
- **THEN** the digits one to nine remain, less every digit already placed in any
  of its peers — and never less a digit merely because a **cage sum** rules it
  out, which is a deduction and not a legal-move check

### Requirement: Every technique in the rank ladder is implemented and named

The system MUST implement each technique named in D-57 — full house, naked
single, hidden single, naked pair, pointing pair, box-line reduction, naked
triple, hidden pair, X-wing, swordfish, XY-wing, and simple chains — together
with the two **killer** techniques D-128 adds, cage combination at Greenhorn and
the 45 rule at Sheriff, and MUST identify deductions by that name.

#### Scenario: A technique is applied

- **WHEN** a deduction is made
- **THEN** it names one of the techniques in the ladder, and never a technique
  outside it

#### Scenario: A technique is asked for on its own

- **WHEN** a single named technique is run against a grid
- **THEN** it reports only the deductions that technique justifies, so it can be
  tested in isolation from the rest of the solver

#### Scenario: A killer technique on a classic grid

- **WHEN** cage combination or the 45 rule is run against a classic puzzle
- **THEN** it deduces nothing, because there is no **cage** for it to reason
  about

### Requirement: Uniqueness is verified independently of the techniques

The system MUST determine whether a puzzle has exactly one solution by exhaustive
search, separately from the technique solver, MUST account for every **cage** and
**cage sum** of a **killer** puzzle in that search, and MUST distinguish no
solution, one solution, and more than one (D-08).

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

#### Scenario: A killer puzzle unique only because of its sums

- **WHEN** a **killer** puzzle's givens alone admit many completions but its
  **cage sum**s admit exactly one
- **THEN** it is reported as unique, and the same grid with a **cage sum**
  changed is reported as ambiguous or unsolvable
