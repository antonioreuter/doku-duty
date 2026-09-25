# Delta for trophy-cabinet

## MODIFIED Requirements

### Requirement: A trophy is minted when it is earned

The system MUST write a **trophy** at the moment the event that earns it is
recorded, in the same transaction, capturing what was earned and which
**season** it came from. It MUST NOT derive a **trophy** from other state at
read time. Every event that earns a **trophy** MUST reach the minting from a
real solve in the running app, not only from a test.

#### Scenario: A boss node is completed

- **WHEN** a **boss node** is recorded as completed
- **THEN** a **trophy** for it is minted in the same transaction, so it cannot
  exist without its cause or its cause without it (constraint 9, D-124)

#### Scenario: A season is completed

- **WHEN** the last **node** of a **season** is recorded as completed
- **THEN** a **trophy** for completing that **season** is minted

#### Scenario: A season completion records what closed it

- **WHEN** the **trophy** for completing a **season** is minted
- **THEN** it captures that **season**'s name and territory and the date, so
  that a later change can present it as a closed case without re-deriving
  anything (D-119, D-124)

#### Scenario: A month of dailies is completed

- **WHEN** every day of a calendar month is on the **calendar** as completed
- **THEN** a **trophy** for that month is minted (`docs/SPEC.md` §5.3)

#### Scenario: A later month is completed too

- **WHEN** a second calendar month is completed after a first already minted
- **THEN** it mints a **trophy** of its own, named for its month, and the
  **cabinet** shows each month's **trophy** in the place the **unfiled**
  **award** held

#### Scenario: A rank is reached

- **WHEN** a solve on the **trail**, in **free play**, or in the **daily
  challenge** raises the player to a **rank** that has an **award**
- **THEN** that **rank**'s **trophy** is minted in the same transaction as the
  **solve record**, along with every **rank** **award** below it not yet earned

#### Scenario: A rank held before the trophy could be minted

- **WHEN** a player who already holds a **rank** with an **award**, and has no
  **trophy** for it, completes any puzzle
- **THEN** the **trophy** is minted, dated at that solve

#### Scenario: The cabinet shows a trophy just earned

- **WHEN** a solve mints a **trophy** and the player opens the **cabinet**
- **THEN** the **trophy** is shown as earned, with no restart of the app

#### Scenario: The same trophy is earned twice

- **WHEN** an event that has already minted a **trophy** is recorded again
- **THEN** no second **trophy** appears, and the first keeps its original date

#### Scenario: The app is killed at the moment of earning

- **WHEN** the app is killed immediately after a **boss node** completes
- **THEN** either both the completion and its **trophy** are present on
  reopening, or neither is — never one alone
