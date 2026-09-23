# Delta for daily-challenge

## ADDED Requirements

### Requirement: One puzzle a day, the same board for everyone

The system MUST offer exactly one **daily challenge** per calendar day, MUST
resolve it from a published schedule that names a puzzle for each date, and MUST
roll over at midnight in the player's local time.

#### Scenario: The day's puzzle is opened

- **WHEN** a player opens the **daily challenge** on a given date
- **THEN** the board is the one the schedule names for that date, and two
  players opening the same date receive the same board

#### Scenario: Midnight passes while the app is open

- **WHEN** local midnight passes with the app running
- **THEN** the **daily challenge** becomes the new day's, and a puzzle already
  in progress is not discarded

#### Scenario: The schedule is exhausted

- **WHEN** no schedule entry covers today, because the player has been offline
  past the compiled-in run or a publish has lapsed
- **THEN** a **daily challenge** is still offered, derived from the installed
  **pack** by a seed fixed by the date, and the player is not told anything is
  missing (D-115)

#### Scenario: Two players outrun the schedule

- **WHEN** two players both fall back to the derived board with different
  **pack**s installed
- **THEN** each is offered a valid **daily challenge**, and the boards may
  differ — sameness yields to the **daily challenge** existing at all (D-115)

#### Scenario: The pack has nothing at the day's rank

- **WHEN** the derived board is wanted but the installed **pack**s hold no
  puzzle at that day's **rank**
- **THEN** the nearest **rank** that can supply one is used, easier side first,
  and a **daily challenge** is still offered — a gap in the **pack** is not
  something the player pays for (constraint 1)

#### Scenario: Nothing is installed at all

- **WHEN** no **pack** is installed at any **rank**
- **THEN** the **daily challenge** reports an absence rather than failing, and
  nothing crashes or blocks

### Requirement: The daily is never generated on the device

The system MUST take every **daily challenge** board from an installed **pack**,
and MUST NOT generate or grade a puzzle at run time.

#### Scenario: A board is resolved by either route

- **WHEN** a **daily challenge** is resolved, whether named by the schedule or
  derived by date seed
- **THEN** it is a puzzle already installed, carrying its solution and its
  **rank**, with exactly one solution and solvable by logic alone (constraint 8,
  D-32)

#### Scenario: The schedule names a puzzle that is not installed

- **WHEN** the schedule names a puzzle the installed **pack**s do not contain
- **THEN** the **daily challenge** falls back to the derived board rather than
  failing, and nothing blocks the player

### Requirement: The daily follows a weekly difficulty ramp

The system MUST publish schedules whose **rank** rises across each week, easier
early and hardest at the week's end, and MUST NOT vary a date's **rank** by who
is asking.

#### Scenario: A week of dailies

- **WHEN** a published week of the **daily challenge** is read
- **THEN** its **rank**s rise from the start of the week to its end (D-116)

#### Scenario: Two players of different rank open the same day

- **WHEN** a Greenhorn and a Legend open the same date's **daily challenge**
- **THEN** both receive the same board at the same **rank**, and neither is
  offered a different one for their own **rank** (D-116)

#### Scenario: The daily is above the player's rank

- **WHEN** the day's **rank** is harder than the player's own
- **THEN** it opens anyway, marked as above their **rank** and never withheld
  (D-103)

### Requirement: A calendar records the days completed

The system MUST record each completed day in a month-grid **calendar**, MUST
write that record at the moment of completion, and MUST keep it across app kill
and reinstall-from-cloud.

#### Scenario: A daily is completed

- **WHEN** a player completes the **daily challenge**
- **THEN** that date is marked on the **calendar**, written before the
  celebration is shown (constraint 9)

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

### Requirement: The streak is recomputed, never stored

The system MUST derive the **streak** from the **calendar** as the number of
consecutive days completed up to today, and MUST NOT persist it as an
independent number.

#### Scenario: The streak is shown

- **WHEN** the **streak** is displayed
- **THEN** it equals the run of consecutive completed days on the **calendar**,
  counting a day a **streak freeze** covered as unbroken

#### Scenario: Two devices disagree

- **WHEN** the same player's **calendar**s from two devices are combined
- **THEN** the days are unioned and the **streak** recomputed from the result,
  so no stored number can conflict (`docs/TECH_STACK.md` §3b)

### Requirement: A streak freeze applies itself

The system MUST grant one **streak freeze** every 7 days, MUST hold at most one
at a time, and MUST consume it automatically on the first missed day without
asking the player.

#### Scenario: A day is missed with a freeze held

- **WHEN** a player misses a day and holds a **streak freeze**
- **THEN** the freeze is consumed automatically, the **streak** continues
  unbroken, and the player is told after the fact rather than asked in advance
  (D-20, D-117)

#### Scenario: A day is missed with no freeze held

- **WHEN** a player misses a day holding no **streak freeze**
- **THEN** the **streak** returns to zero, nothing else is lost, and no
  **season** progress, **node**, **rank**, or trophy is affected (D-20)

#### Scenario: Freezes do not accumulate

- **WHEN** a player holding a **streak freeze** goes 7 more days without missing
  one
- **THEN** they still hold exactly one, because a second is never banked (D-117)

#### Scenario: Several days are missed at once

- **WHEN** a player misses more than one consecutive day holding one
  **streak freeze**
- **THEN** the freeze covers one day only, and the **streak** breaks

### Requirement: The daily carries no advertisement

The system MUST NOT show an interstitial before, during, or after the **daily
challenge**.

#### Scenario: A daily is completed

- **WHEN** the **daily challenge** is completed, at any point in a session and
  whatever the interstitial counters hold
- **THEN** no interstitial is shown, and the completion does not count toward
  any interstitial cadence (D-24, constraint 6)

### Requirement: The daily needs no network

The system MUST offer the **daily challenge**, record completion, and show the
**calendar** and **streak** with no network at any point.

#### Scenario: First launch offline

- **WHEN** the app is installed and opened for the first time with no network
- **THEN** the **daily challenge** is available from the compiled-in schedule
  and the installed **pack**, and nothing about it blocks the first frame

#### Scenario: A day is completed offline

- **WHEN** a **daily challenge** is completed with no network
- **THEN** the **calendar** and **streak** update immediately and locally, and
  no upload is awaited

### Requirement: A wrong clock never costs a streak

The system MUST derive dates from the stored server-time offset where one is
known and from the device clock otherwise, MUST mark days recorded without a
known offset as unverified, and MUST NOT reduce a **streak** or unmark a
**calendar** day when a clock changes.

#### Scenario: The device clock is moved forward

- **WHEN** a player advances the device clock and completes several days
- **THEN** the days recorded that way are marked unverified, and on reconnect
  those a changed clock could have manufactured are discarded

#### Scenario: The player crosses a timezone

- **WHEN** a player's timezone changes
- **THEN** the **streak** and the **calendar** survive intact, because the rule
  exists to stop fabrication and not to catch travellers
  (`docs/TECH_STACK.md` §3b)

### Requirement: A completed daily is announced to the rest of the app

The system MUST signal that a **daily challenge** has been completed, carrying
the date and whether a **streak** milestone was reached, at the point the
completion is recorded.

#### Scenario: A daily completes

- **WHEN** a **daily challenge** is recorded as completed
- **THEN** a completion carrying its date and any **streak** milestone is
  signalled, so that `add-stamps` and `add-trophy-cabinet` can each count it
  without inventing their own trigger

#### Scenario: Nothing is minted yet

- **WHEN** a **daily challenge** completes before `add-stamps` exists
- **THEN** no **stamp** is minted and no trophy is filed, and the completion is
  signalled all the same
