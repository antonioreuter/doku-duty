# Delta for daily-challenge

## ADDED Requirements

### Requirement: A completed daily is announced, and pays its stamps

The system MUST signal that a **daily challenge** has been completed, carrying
the date and whether a **streak** milestone was reached, at the point the
completion is recorded — and MUST record the **stamp**s that completion earns in
the same write (D-66, D-134).

#### Scenario: A daily completes

- **WHEN** a **daily challenge** is recorded as completed
- **THEN** a completion carrying its date and any **streak** milestone is
  signalled, so that the **stamp**s and the **cabinet** can each count it
  without inventing their own trigger

#### Scenario: A daily completion pays

- **WHEN** a **daily challenge** is recorded as completed
- **THEN** 2 **stamp**s are earned for that date, and 10 more when the
  **streak** it makes is a multiple of 7

## REMOVED Requirements

### Requirement: A completed daily is announced to the rest of the app

Replaced by "A completed daily is announced, and pays its stamps". Its scenario
"Nothing is minted yet" described the time before `add-stamps` existed, and
this change is what makes it false.
