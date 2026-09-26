# Delta for stamps

## ADDED Requirements

### Requirement: Stamps are earned in play at D-66's values

The system MUST pay **stamp**s for exactly these events, at exactly these
values (D-66): 2 for completing a **daily challenge**, 3 for solving any puzzle
with no **mistake**, 10 on every seventh day of a **streak**, 12 for opening a
**chest node**, and 20 for completing a **boss node**. Each event is its own
**earning**, so one completion can pay more than one.

#### Scenario: A chest is opened

- **WHEN** a **chest node** is opened
- **THEN** 12 **stamp**s are earned, and a new player's balance of 0 reads 12

#### Scenario: A perfect daily

- **WHEN** the **daily challenge** is solved with no **mistake**
- **THEN** 2 **stamp**s are earned for the day and 3 for the perfect solve —
  5 in all

#### Scenario: A boss is beaten after a retry

- **WHEN** a **boss node** is completed with no **mistake** on a later attempt
- **THEN** 20 **stamp**s are earned for the **boss node** and 3 for the perfect
  solve, and the earlier attempt costs nothing (D-22)

#### Scenario: The seventh day of a streak

- **WHEN** a **daily challenge** completion makes the **streak** 7, 14, 21, or
  any multiple of 7
- **THEN** 10 **stamp**s are earned for the milestone, besides the day's 2

#### Scenario: A solve with a mistake

- **WHEN** a puzzle is solved with one or more **mistake**s
- **THEN** no perfect-solve **stamp**s are earned, and nothing is taken away —
  there is no penalty to infer (constraint 1)

### Requirement: Each event pays once

The system MUST record each **earning** against the event that earned it — a
date, a puzzle, a **streak** day, or a **node** — and MUST NOT pay the same
event twice, however many times it is completed, retried, or written (D-133).

#### Scenario: A board is completed again

- **WHEN** a solved board is erased and completed again, or a completed **boss
  node** is played again
- **THEN** no further **stamp**s are earned for it

#### Scenario: A clean replay of a board first solved with a mistake

- **WHEN** a puzzle first solved with a **mistake** is erased and completed
  again with none
- **THEN** no perfect-solve **stamp**s are earned: the perfect solve is the
  puzzle's first solve, which already happened (D-133)

#### Scenario: A streak breaks and starts again

- **WHEN** a **streak** breaks and a new one reaches its seventh day
- **THEN** that seventh day pays 10, because it is a different **streak** day
  from the first run's

#### Scenario: A write is repeated

- **WHEN** the same completion is recorded twice, as a retry after a failed
  write might
- **THEN** the balance moves once

### Requirement: An earning commits with its cause

The system MUST write an **earning** in the same transaction as the completion
that earned it, so that after an app kill both are present or neither is
(constraint 9).

#### Scenario: The app is killed mid-completion

- **WHEN** the app is killed while a completion that earns **stamp**s is being
  written
- **THEN** on relaunch either the completion and its **earning** are both
  recorded, or neither is

#### Scenario: Offline

- **WHEN** **stamp**s are earned with no network
- **THEN** they are earned and kept exactly as online, because nothing about an
  **earning** needs the network

### Requirement: The balance is the sum of what was earned

The system MUST derive the **stamp** balance from the recorded **earning**s on
every read, and MUST NOT store it as a separate number (D-133).

#### Scenario: Relaunch

- **WHEN** the app is relaunched
- **THEN** the balance equals the total of every **earning** recorded before

#### Scenario: Upgrading

- **WHEN** a player upgrades to the version that introduces **stamp**s
- **THEN** their balance starts at 0, whatever they completed before — there is
  no back-pay (D-133, as D-124 does for **trophy**s)

### Requirement: Stamps can never be bought

The system MUST NOT offer **stamp**s for money in any form — no price, no
bundle, no store surface, no conversion from a purchase or a subscription
(D-66, constraint 10).

#### Scenario: Looking for a way to buy them

- **WHEN** the player looks anywhere in the app for a way to get **stamp**s
- **THEN** the only ways are the five events that earn them in play

### Requirement: The player is told when stamps are earned

The system MUST tell the player how many **stamp**s a completion earned, in a
short notice shown once that completion's celebration has finished. The notice
MUST NOT cover a grid still in play, take input, block a tap, or offer anything
for sale (D-134, constraints 2 and 6).

#### Scenario: A perfect solve

- **WHEN** a puzzle is solved with no **mistake** and its celebration finishes
- **THEN** a notice says 3 **stamp**s were earned, and goes away by itself

#### Scenario: More than one earning at once

- **WHEN** one completion earns for more than one event, as a perfect daily on
  a seventh day does
- **THEN** one notice gives the total, rather than one notice per **earning**

#### Scenario: Nothing earned

- **WHEN** a completion earns no **stamp**s
- **THEN** no notice appears

#### Scenario: Reduce-motion

- **WHEN** motion is reduced and a completion earns **stamp**s
- **THEN** the notice appears at once, since no celebration plays, and
  appears and leaves without animating

#### Scenario: A chest is opened

- **WHEN** a **chest node** is opened for the first time
- **THEN** its message reads "Chest opened · +12 Stamps", rather than a second
  notice (D-134)
