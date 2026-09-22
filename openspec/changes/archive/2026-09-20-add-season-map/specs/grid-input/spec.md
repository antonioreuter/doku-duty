# Delta for grid-input

## MODIFIED Requirements

### Requirement: A puzzle can be reached at any rank

The system MUST let the player open a puzzle at each of the six **rank**s, MUST
report having none left at a **rank** as an ordinary absence, and MUST mark the
**rank**s above the player's own without making any of them harder to open
(D-103). This route MUST remain available whatever the player's position on the
**trail**, because the **trail** is walked in order and a **rank** at its far
end would otherwise be unreachable — which is the gate D-103 refused (D-111).

#### Scenario: A rank is chosen

- **WHEN** the player chooses a **rank**
- **THEN** a puzzle of that **rank** that they have not solved is opened

#### Scenario: Free play is reachable from anywhere on the trail

- **WHEN** the player is at any **node** of any **season**, including the first
- **THEN** **free play** is reachable, and every one of the six **rank**s can be
  opened from it with no confirmation, no warning to dismiss, and no gate
  (constraint 1)

#### Scenario: A rank with nothing left

- **WHEN** the player has solved every puzzle at a **rank**
- **THEN** that is shown as nothing left at that **rank**, and play is not
  blocked, failed, or gated (constraint 1)

#### Scenario: A rank above the player's is marked

- **WHEN** a **rank** is harder than the player's own
- **THEN** it is shown as being above their **rank**

#### Scenario: A node naming a rank above the player's is marked the same way

- **WHEN** a **node** on the **trail** names a **rank** harder than the player's
  own
- **THEN** it carries the same mark, for the same reason, and opening it is no
  harder than opening any other **node**

#### Scenario: A marked rank opens exactly as any other

- **WHEN** the player chooses a **rank** above their own
- **THEN** a puzzle of that **rank** is opened, with no confirmation, no warning
  to dismiss, and no gate — and a **lesson** may precede it on a first
  encounter, on exactly the terms it would precede any other puzzle, skippable
  in one tap (constraint 1)

#### Scenario: A lesson is not a penalty for reaching upward

- **WHEN** a **lesson** precedes a puzzle at a **rank** above the player's own
- **THEN** it is the same **lesson**, shown for the same reason, as it would be
  at any other **rank** — triggered by a technique the player has not met, never
  by the **rank** being above theirs

#### Scenario: Solving a marked rank clears its mark

- **WHEN** the player completes a puzzle at a **rank** above their own
- **THEN** their **rank** becomes that **rank**, and that **rank** and every
  **rank** below it are no longer marked

#### Scenario: A puzzle solved in free play counts everywhere

- **WHEN** a puzzle is completed in **free play**
- **THEN** it writes a **solve record** on the same terms as one completed at a
  **node**, and it does not advance the **trail**

#### Scenario: The mark is not carried by colour alone

- **WHEN** a **rank** above the player's is shown
- **THEN** the mark is readable without relying on colour to carry it
  (constraint 5)

#### Scenario: The rank list paints before progression is known

- **WHEN** **free play** is opened
- **THEN** all six **rank**s are on screen on the first frame, with the marks
  applied once the player's **rank** has been read, and reading it is not on the
  path to that frame
