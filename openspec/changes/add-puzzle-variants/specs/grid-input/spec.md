# Delta for grid-input

## ADDED Requirements

### Requirement: A killer board draws its cages

The system MUST draw every **cage** of a **killer** puzzle as a dashed outline
inside its cells, and MUST show each **cage sum** at the top-left of the
**cage**'s first cell in reading order. Both MUST use only tokens that already
carry outlines and secondary text, adding no hue (constraint 4, D-129).

#### Scenario: A killer board is opened

- **WHEN** a **killer** puzzle is shown
- **THEN** every **cage** is outlined, every **cage sum** is readable, and the
  **unit** boundaries are still drawn as on a classic board

#### Scenario: A cage is told apart without colour

- **WHEN** the board is rendered without colour
- **THEN** every **cage** is still identifiable by its outline and its number,
  because neither is carried by a fill (constraint 5)

#### Scenario: A classic board is unchanged

- **WHEN** a classic puzzle is shown
- **THEN** it renders exactly as it did before **killer** existed

#### Scenario: A screen reader reads a cell

- **WHEN** a screen reader focuses a cell of a **killer** board
- **THEN** it announces the **cage sum** and the number of cells in the cell's
  **cage**, alongside what it already announces

#### Scenario: The largest text size

- **WHEN** a **killer** board is shown at the largest supported text size on the
  smallest phone the app targets (D-84)
- **THEN** no **cage sum** is clipped or truncated

### Requirement: Free play serves classic puzzles only

The system MUST NOT open a **killer** puzzle from **free play**. **Killer** is
reached only through a **variant node** (D-127).

#### Scenario: A rank is chosen in free play

- **WHEN** the player chooses a **rank** in **free play**
- **THEN** a classic puzzle of that **rank** is opened, whatever **killer**
  puzzles the **pack** holds at that **rank**

## MODIFIED Requirements

### Requirement: Selecting a cell shows the cells it shares a unit with

The system MUST mark the peers of the selected cell — every other cell in its
row, its column, and its block, and on a **killer** board every other cell of
its **cage** (D-130).

#### Scenario: A cell is selected

- **WHEN** a cell of a classic board is selected
- **THEN** its twenty peers are marked, and the selected cell itself remains
  distinguishable from them

#### Scenario: A cell of a killer board is selected

- **WHEN** a cell of a **killer** board is selected
- **THEN** its twenty peers and its **cage** mates are marked alike, because the
  same digit cannot repeat in any of them

#### Scenario: The selection moves

- **WHEN** another cell is selected
- **THEN** the previous cell and its peers are no longer marked, and the new
  cell's are

#### Scenario: Nothing is selected

- **WHEN** no cell is selected
- **THEN** no cell is marked as a peer
