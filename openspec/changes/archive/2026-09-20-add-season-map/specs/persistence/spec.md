# Delta for persistence

## ADDED Requirements

### Requirement: Season progress is recorded

The system MUST record which **season** is in force, which of its **node**s are
completed, and which **node** is current, MUST keep that record across app
kills, and MUST treat a player with no such record as standing at the first
**node** rather than as an error.

#### Scenario: A node is completed

- **WHEN** a **node** is recorded as completed
- **THEN** it is written durably at that moment, not on a timer and not at the
  end of the session (constraint 9)

#### Scenario: Nothing is inserted between the change and the write

- **WHEN** any code that writes **season** progress is examined
- **THEN** it carries no timer, debounce, throttle, delay, batch, flush step, or
  lifecycle hook on the path a completion takes — the same guard the note write
  path carries, and enforced over this capability's own repository rather than
  over the persistence layer alone

#### Scenario: The record survives an app kill

- **WHEN** the app is killed immediately after a **node** completes
- **THEN** on relaunch that **node** still reads as completed and the next
  **node** is current

#### Scenario: A player who has played no season

- **WHEN** no **season** progress has ever been written
- **THEN** that reads as standing at the first **node** of the current
  **season**, not as a missing or corrupt record

### Requirement: A node completion and its solve record are one write

The system MUST write a puzzle-bearing **node**'s completion in the same
transaction as the **solve record** it comes from, so that neither can exist
without the other.

#### Scenario: The write fails part way

- **WHEN** writing a **node** completion or its **solve record** fails
- **THEN** neither is written, and the **node** still reads as the **current
  node**

#### Scenario: The same node is completed twice

- **WHEN** a **node** already recorded as completed is completed again
- **THEN** the record is unchanged, exactly as a repeated **solve record** is
  (constraint 9)

### Requirement: Season rotation keeps what is permanent

The system MUST keep lifetime counters, per-technique counters, seen **lesson**s,
and **solve record**s unchanged when a **season** is rotated out, and MUST NOT
carry that **season**'s **node** completions into its successor (D-17).

#### Scenario: A season rotates

- **WHEN** a **season** is rotated out and a later one becomes current
- **THEN** lifetime and per-technique statistics, seen **lesson**s, and solved
  puzzles are unchanged, and the new **season** starts at its first **node**

### Requirement: Season progress is carried by sync

The system MUST stamp **season** progress with the metadata sync needs, and
MUST treat it as syncable state rather than device-local state.

#### Scenario: Another device is signed in

- **WHEN** a player walks part of a **trail** on one device and opens another
- **THEN** where they stand is carried across, rather than starting again at
  the first **node**

#### Scenario: Two devices disagree

- **WHEN** both devices hold **node** completions for the same **season**
- **THEN** the completions union, because a completed **node** is a fact and
  never an absence — and the **boss node** attempt count takes the larger,
  like the lifetime counters beside it

### Requirement: Boss attempts are counted without being limited

The system MUST record how many times a **boss node** has been attempted, and
MUST NOT use that count to restrict, price, or end access to the **node**
(D-22, constraint 1).

#### Scenario: A boss is attempted repeatedly

- **WHEN** a **boss node** is attempted many times without being completed
- **THEN** each attempt is counted and the **node** remains openable on the same
  terms as the first time
