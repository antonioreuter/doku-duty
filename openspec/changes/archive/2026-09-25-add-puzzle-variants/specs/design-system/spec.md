# Delta for design-system

## MODIFIED Requirements

### Requirement: Shape and depth are tokens, and depth never touches the grid

The system MUST expose the four corner radii and five stroke weights in
`docs/DESIGN.md` §3 — the fifth being the dashed **cage** outline (D-129) — and
MUST apply the depth treatment — solid offset shadow, never a blur — to
interactive chrome only.

#### Scenario: A button is pressed

- **WHEN** a pressable surface is pressed
- **THEN** it translates down 4px and its depth drops from its rest value to 1px,
  and on release it returns

#### Scenario: A grid cell is drawn

- **WHEN** a cell of the grid is drawn
- **THEN** it carries no offset shadow and no thick border

#### Scenario: A cage is drawn

- **WHEN** a **cage** outline is drawn
- **THEN** it uses the **cage** stroke token and a colour already assigned to
  outlines, and no new colour is introduced
