# Delta for grid-input

## MODIFIED Requirements

### Requirement: A puzzle can be reached at any rank

The system MUST let the player open a puzzle at each of the six **rank**s, MUST
report having none left at a **rank** as an ordinary absence, and MUST mark the
**rank**s above the player's own without making any of them harder to open
(D-103).

#### Scenario: A rank is chosen

- **WHEN** the player chooses a **rank**
- **THEN** a puzzle of that **rank** that they have not solved is opened

#### Scenario: A rank with nothing left

- **WHEN** the player has solved every puzzle at a **rank**
- **THEN** that is shown as nothing left at that **rank**, and play is not
  blocked, failed, or gated (constraint 1)

#### Scenario: A rank above the player's is marked

- **WHEN** a **rank** is harder than the player's own
- **THEN** it is shown as being above their **rank**

#### Scenario: A marked rank opens exactly as any other

- **WHEN** the player chooses a **rank** above their own
- **THEN** a puzzle of that **rank** is opened, with no confirmation, no warning
  to dismiss, and no extra step (constraint 1)

#### Scenario: Solving a marked rank clears its mark

- **WHEN** the player completes a puzzle at a **rank** above their own
- **THEN** their **rank** becomes that **rank**, and that **rank** and every
  **rank** below it are no longer marked

#### Scenario: The mark is not carried by colour alone

- **WHEN** a **rank** above the player's is shown
- **THEN** the mark is readable without relying on colour to carry it
  (constraint 5)

#### Scenario: The rank list paints before progression is known

- **WHEN** the **rank** picker is opened
- **THEN** all six **rank**s are on screen on the first frame, with the marks
  applied once the player's **rank** has been read, and reading it is not on the
  path to that frame
