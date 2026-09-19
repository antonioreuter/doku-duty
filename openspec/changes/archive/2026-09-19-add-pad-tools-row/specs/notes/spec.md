# Delta for notes

## ADDED Requirements

### Requirement: The controls that end a chain test appear only when there is one

The system MUST show the control that clears every **provisional note** and the
control that **promote**s them only while the board holds at least one
**provisional note**, MUST name both for what they do to the board, and MUST NOT
draw either as a bare tick or cross.

A tick beside a cross reads as confirm beside cancel, and confirm reads as
"check my answer" — the one thing this product does not do (D-04, constraint 1).
Both controls are also meaningless on a board with no hypothesis on it: there is
nothing to discard and nothing to keep. Showing them where they can act, named
for the act, removes the misreading and the clutter together.

Neither control is disabled at any point. When there is a test to end, both are
present and both work; when there is not, they are not on screen.

#### Scenario: A board with no provisional notes

- **WHEN** the board holds no **provisional note**
- **THEN** neither the clearing control nor the **promote** control is on screen

#### Scenario: The first provisional note is marked

- **WHEN** the player marks a **provisional note** on a board that had none
- **THEN** both controls appear

#### Scenario: The last provisional note goes

- **WHEN** the last **provisional note** leaves the board, by any route
- **THEN** both controls leave with it

#### Scenario: The controls say what they do

- **WHEN** either control is on screen
- **THEN** it is named for the change it makes to the board, not by a symbol
  that could be read as accepting or rejecting an answer

#### Scenario: Both are still one action and one undo

- **WHEN** either control is used
- **THEN** it does exactly what it did before — one action, reversed by one
  undo (D-11, D-91)
