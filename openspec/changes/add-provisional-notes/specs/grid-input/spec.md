# Delta for grid-input

## ADDED Requirements

### Requirement: A glyph grows with dynamic type only until it fills its box

The system MUST scale a placed value's glyph and a candidate's glyph with the
reader's text size, MUST stop growing each one once it fills the cell or the
3×3 slot it occupies, and MUST NOT let either overflow that box at any text
size (D-92).

The grid cannot reflow: nine columns are nine columns at every text size, and
a cell is the width it is given divided by nine (D-84). Left uncapped, a
candidate passes its slot at roughly 1.2× and a value passes its cell at
roughly 1.8× — ordinary "Larger Text", not an accessibility extreme — and the
result is not large text but digits overlapping their neighbours.

#### Scenario: The default text size

- **WHEN** the grid is drawn at the reader's default text size
- **THEN** values and candidates are drawn at their own sizes, untouched by the
  cap, because both already fit

#### Scenario: Text larger than the box allows

- **WHEN** the reader's text size would make a candidate wider or taller than
  its slot
- **THEN** the candidate is drawn at the largest size that fits that slot, and
  never outside it

#### Scenario: A value at a large text size

- **WHEN** the reader's text size would make a value overflow its cell
- **THEN** the value is drawn at the largest size that fits the cell

#### Scenario: Type still does something

- **WHEN** the reader raises their text size from the default by a small amount
- **THEN** the glyphs are larger than they were, because the cap is a ceiling
  and not a fixed size

#### Scenario: A narrower grid caps sooner

- **WHEN** the same text size is used on a grid drawn at half the width
- **THEN** the glyphs cap at a smaller size, because the box is the cell rather
  than a constant

#### Scenario: Candidates keep their slots at every text size

- **WHEN** a cell holds all nine candidates at the largest text size
- **THEN** each is inside the slot its digit owns, so a grid at large type is
  read the same way as a grid at small type (D-10, constraint 3)

#### Scenario: The grid is resized

- **WHEN** the grid is drawn at one size and then at another without being
  rebuilt
- **THEN** the glyphs are measured against the new cell, not the old one
