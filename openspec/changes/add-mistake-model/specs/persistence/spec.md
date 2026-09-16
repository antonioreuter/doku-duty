# Delta for persistence

## MODIFIED Requirements

### Requirement: A puzzle in progress survives an app kill

The system MUST restore an interrupted puzzle to the state it was in — placed
values, both kinds of note, elapsed time, and the **mistake**s recorded against
the **attempt** — when the app is next opened.

#### Scenario: Killed mid-puzzle

- **WHEN** the app is killed while a puzzle is part-solved and reopened
- **THEN** the same puzzle resumes with every placed value and every note as they
  were, and the player is not returned to an empty grid

#### Scenario: Elapsed time is restored, not restarted

- **WHEN** an interrupted puzzle is resumed
- **THEN** its elapsed time continues from where it stopped, and time spent with
  the app closed is not counted

#### Scenario: The mistake count is restored, not restarted

- **WHEN** an interrupted puzzle is resumed
- **THEN** the **mistake**s recorded against it are what they were, so a player
  who was two into a **strict mode** **attempt** is still two into it

#### Scenario: A save written before mistakes were stored

- **WHEN** a save made before this capability existed is resumed
- **THEN** it resumes with a count of zero rather than failing to open

#### Scenario: A puzzle is completed

- **WHEN** a puzzle is finished
- **THEN** its in-progress save is no longer offered for resume, and the notes
  that belonged to it are gone — they described unknowns the grid no longer has

### Requirement: Settings persist across launches

The system MUST store player settings, including **reduce effects**, and MUST
return the documented default for any setting never chosen.

#### Scenario: A setting is changed and the app restarts

- **WHEN** the player changes a setting and the app is restarted
- **THEN** the chosen value is in effect

#### Scenario: A setting has never been chosen

- **WHEN** a setting is read on a fresh install
- **THEN** its default is returned, and for **strict mode** that default is off
  (D-04)

#### Scenario: A setting that no longer exists

- **WHEN** a value stored under a retired setting's key is found on disk
- **THEN** it is ignored and nothing reads it, because a stored value with no
  behaviour behind it is worse than no value at all

#### Scenario: The player changes a setting before its stored value is read

- **WHEN** a player changes a setting while the app is still loading the value
  it had on disk
- **THEN** the player's choice stands and is stored, and the value read from
  disk does not replace it

### Requirement: Statistics accumulate across puzzles

The system MUST record lifetime counters and per-technique counters that outlive
any single puzzle, **season**, or pack, and MUST record whether a completed
puzzle was solved with no **mistake**.

#### Scenario: A puzzle is solved

- **WHEN** a puzzle is completed
- **THEN** the lifetime counters and the counters for the techniques it required
  are updated durably

#### Scenario: A perfect solve is counted as one

- **WHEN** a puzzle is completed with no **mistake** recorded against it
- **THEN** the perfect-solve counter rises, and it does not when a **mistake**
  was recorded

#### Scenario: A season rotates

- **WHEN** a **season** ends and its map is rotated out
- **THEN** lifetime and per-technique statistics are unchanged (D-17)
