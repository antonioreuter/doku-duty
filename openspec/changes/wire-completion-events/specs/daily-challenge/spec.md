# Delta for daily-challenge

## MODIFIED Requirements

### Requirement: A calendar records the days completed

The system MUST record each completed day in a month-grid **calendar**, MUST
write that record at the moment of completion, and MUST keep it across app kill
and reinstall-from-cloud. A day MUST be recorded when, and only when, the player
solves a board they opened as the **daily challenge**. The day recorded MUST be
the date the board was opened for, not the date at the moment of solving
(D-132). The day MUST be written in the same transaction as the **solve
record**.

#### Scenario: A daily is completed

- **WHEN** a player completes the **daily challenge**
- **THEN** that date is marked on the **calendar**, written before the
  celebration is shown (constraint 9)

#### Scenario: The streak grows from a real solve

- **WHEN** a player opens the **daily challenge** from the daily screen and
  solves it in the running app
- **THEN** the daily screen shows the day as completed, and the **streak**
  includes it

#### Scenario: A daily is solved after midnight

- **WHEN** a player opens the **daily challenge** before midnight and solves it
  after midnight
- **THEN** the day the board was opened for is marked on the **calendar**, and
  the new day is not

#### Scenario: The same puzzle is solved away from the daily

- **WHEN** the puzzle that is today's **daily challenge** is opened from the
  **trail** or **free play** and solved there
- **THEN** no day is marked on the **calendar**

#### Scenario: A daily board completes no node

- **WHEN** a player opens a **node**, then opens the **daily challenge**, and
  solves it
- **THEN** the day is marked and no **node** is completed (D-111)

#### Scenario: The day commits with the solve

- **WHEN** the app is killed at the moment the **daily challenge** is solved
- **THEN** on reopening, either the **solve record** and the day are both
  present, or neither is

#### Scenario: The app is killed mid-puzzle

- **WHEN** the app is killed while the **daily challenge** is in progress
- **THEN** the day is not marked, the board is restored on reopening, and the
  **streak** is unaffected

#### Scenario: A new player opens the calendar

- **WHEN** a player who has never completed a **daily challenge** opens the
  **calendar**
- **THEN** no day is shown as missed, because a day before the player's first
  recorded day is not a day they failed to play (constraint 1)

#### Scenario: A past day is viewed

- **WHEN** a player opens the **calendar**
- **THEN** completed days, missed days, days a **streak freeze** covered, days
  still to come, and days before the player started are each distinguishable
  without relying on colour (constraint 5)

### Requirement: A completed daily is announced to the rest of the app

The system MUST signal that a **daily challenge** has been completed, carrying
the date and whether a **streak** milestone was reached, at the point the
completion is recorded. Whatever the completion earns MUST be written in the
same transaction as the day.

#### Scenario: A daily completes

- **WHEN** a **daily challenge** is recorded as completed
- **THEN** a completion carrying its date and any **streak** milestone is
  signalled, so that `add-stamps` and the **cabinet** can each count it
  without inventing their own trigger

#### Scenario: A daily completes a month

- **WHEN** a solved **daily challenge** records the last missing day of a
  calendar month
- **THEN** that month's **trophy** is minted in the same transaction as the day
  (D-124)

#### Scenario: Nothing is minted yet

- **WHEN** a **daily challenge** completes before `add-stamps` exists
- **THEN** no **stamp** is minted, and the completion is signalled all the same.
  A **trophy** is still filed when the day completes its month
