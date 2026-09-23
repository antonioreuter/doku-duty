# Delta for season-map

## MODIFIED Requirements

### Requirement: A node names a rank, not a puzzle

The system MUST resolve a puzzle-bearing **node**'s puzzle from the **pack** at
the moment the **node** is opened, using the **rank** the **node** names — a
**killer** puzzle for a **variant node** and a classic one for every other — and
MUST NOT store a puzzle identity in the **season** definition (D-110, D-127).

#### Scenario: A node is opened

- **WHEN** a puzzle **node** or **boss node** is opened
- **THEN** a classic puzzle of that **node**'s **rank** that the player has not
  solved is opened

#### Scenario: A variant node is opened

- **WHEN** a **variant node** is opened
- **THEN** a **killer** puzzle of that **node**'s **rank** that the player has
  not solved is opened

#### Scenario: A variant node with no killer puzzle left

- **WHEN** a **variant node**'s **rank** has no unsolved **killer** puzzle left
- **THEN** it is reported as an ordinary absence exactly as any other **node**'s
  would be, and a classic puzzle is not substituted in its place

#### Scenario: The pack is topped up

- **WHEN** a newer **pack** version installs
- **THEN** every **node** still resolves, and no completed **node** reverts

#### Scenario: A rank has nothing left

- **WHEN** a **node**'s **rank** has no unsolved puzzle left in the **pack**
- **THEN** that is reported as an ordinary absence, and play is not blocked,
  failed, or gated (constraint 1)
