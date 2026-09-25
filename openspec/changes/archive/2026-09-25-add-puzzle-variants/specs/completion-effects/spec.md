# Delta for completion-effects

## ADDED Requirements

### Requirement: A cage is not a unit, and completing one fires nothing

The system MUST NOT treat a **cage** as a **unit**: filling a **cage** earns no
**completion tint**, no **corner mark**, no **cascade**, and no haptic, while
rows, columns, and blocks on a **killer** board complete exactly as on a classic
one (D-130).

#### Scenario: A cage is filled

- **WHEN** the last cell of a **cage** receives a value and no row, column, or
  block completes with it
- **THEN** no completion effect of any kind plays

#### Scenario: A row completes on a killer board

- **WHEN** a row of a **killer** board holds nine distinct digits
- **THEN** it completes exactly as a row on a classic board would
