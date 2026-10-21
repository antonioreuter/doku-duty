# persistence

## Purpose

The local database. Everything a player would be upset to lose lives here: the
puzzle they are part-way through, both kinds of note on it, the packs those
puzzles come from, their statistics, and their settings.

Its defining rule is that a note is written as part of the action that changed
it, never on a timer (D-33) — a player twenty minutes into an expert grid does
not get a warning before the OS reclaims the process. That guarantee has no
visible symptom when it breaks, so it is enforced by test rather than intended.

Guests and signed-in players use this identically; an account buys sync, never
storage. Rows carry the metadata sync will need, and nothing reads it yet.

Established by `add-persistence-layer`. The store is Drift over SQLite, held on
a specific version line for a reason recorded in D-77; timestamps are ISO-8601
by D-76, and the database's location by D-78.

## Requirements

### Requirement: Note state is written on every change

The system MUST write a **settled note** or **provisional note** to storage as
part of the action that changed it, and MUST NOT defer that write to a timer, a
debounce, a batch, or application lifecycle events (D-33).

#### Scenario: A note is added

- **WHEN** a player adds a candidate to a cell
- **THEN** the change is durable before the action completes, with no interval in
  which the note is on screen but not stored

#### Scenario: The app is killed immediately after a note

- **WHEN** the app is killed at any point after a note is added, including
  straight after, with no backgrounding and no clean shutdown
- **THEN** the note is present when the puzzle is reopened

#### Scenario: A rapid sequence of notes

- **WHEN** a player marks a dense board quickly, making many note changes in a
  few seconds
- **THEN** every change is stored, none is coalesced away, and the last one is
  durable on the same terms as the first

#### Scenario: The write does not delay the player

- **WHEN** a note is entered
- **THEN** the next input is accepted without waiting for the write to be
  acknowledged

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

### Requirement: Notes carry their kind and their provenance

The system MUST store, for every candidate, whether it is a **settled note** or a
**provisional note**, and whether it was entered by the player or produced by
**auto-cleanup** or an auto-notes fill (D-15, D-11).

#### Scenario: Clearing provisional marks

- **WHEN** the player clears all provisional marks in one action
- **THEN** every **provisional note** is removed and every **settled note**
  remains

#### Scenario: Generated and manual notes are told apart

- **WHEN** notes have been both entered by hand and produced automatically in the
  same cell
- **THEN** storage distinguishes them, even though the player sees no difference

#### Scenario: Candidates keep their positions

- **WHEN** a candidate is removed from a cell and the puzzle is reloaded
- **THEN** the remaining candidates occupy the same nine fixed slots they did
  before, and none has moved to fill the gap (D-10)

### Requirement: Puzzles are stored with their solution, grade, and seed

The system MUST store each puzzle inside a versioned pack, carrying its solution,
the **rank** its hardest required technique implies, its seed, and — for a
**killer** puzzle — its **cage**s and **cage sum**s (D-32, D-127).

#### Scenario: A puzzle is read for play

- **WHEN** a puzzle is loaded
- **THEN** its clues, its solution, its **rank**, its seed, and its **cage**s if
  it has any are all available without any network call

#### Scenario: Selecting by rank

- **WHEN** a puzzle of a given **rank** is requested
- **THEN** one is returned from local storage, or the absence of any is reported
  as a normal result rather than an error

#### Scenario: Selecting by rank and kind

- **WHEN** a classic puzzle, or a **killer** one, of a given **rank** is
  requested
- **THEN** only a puzzle of that kind is returned, never one of the other

#### Scenario: A pack is replaced by a newer version

- **WHEN** a pack with a version newer than the stored one is installed
- **THEN** progress against puzzles the player has already solved is preserved

#### Scenario: An older or repeated pack version arrives

- **WHEN** a pack is offered whose version is older than or equal to the stored
  one — a cached response, or one that arrived out of order
- **THEN** it is ignored, because a pack version is immutable: the same version
  always means the same content

#### Scenario: A puzzle in progress survives the upgrade

- **WHEN** the app is upgraded to a version whose schema carries **cage**s, with
  a classic puzzle in progress
- **THEN** the puzzle, its values, and its notes are all there on reopening, and
  it is still a classic puzzle

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

### Requirement: Which lessons have been seen is recorded

The system MUST record that a **lesson** has been seen at the moment it is
completed or skipped, MUST keep that record across app kills and **season**
rotation, and MUST treat a player with no such record as having seen nothing
rather than as an error.

#### Scenario: A lesson is seen

- **WHEN** a **lesson** is completed or skipped
- **THEN** it is recorded as seen before the puzzle opens, not at the end of the
  puzzle or the session (constraint 9)

#### Scenario: The record survives an app kill

- **WHEN** the app is killed immediately after a **lesson** is skipped
- **THEN** on relaunch that **lesson** still reads as seen, and does not fire
  again

#### Scenario: A season rotates

- **WHEN** a **season** ends and its map is rotated out
- **THEN** every seen **lesson** is still seen (D-17)

#### Scenario: A player who has seen nothing

- **WHEN** no **lesson** has ever been seen
- **THEN** that reads as none seen yet, and every **lesson** remains due on its
  own terms

#### Scenario: Replaying does not change the record

- **WHEN** a **lesson** that is already seen is replayed
- **THEN** the record is unchanged, because seen is not a count

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

### Requirement: Syncable state carries the metadata sync will need

The system MUST record, for every row that will later sync, when it was last
modified and whether it is waiting to be uploaded, and MUST record which device a
save originated on.

#### Scenario: A row is modified

- **WHEN** any syncable row is written
- **THEN** its last-modified stamp is updated and it is marked as pending upload

#### Scenario: Two rows are written in the same second

- **WHEN** two syncable rows are written within the same second, as happens
  whenever a player marks a board quickly
- **THEN** their stamps still order them, so a later merge can tell which came
  second rather than resolving a real conflict arbitrarily

#### Scenario: Stamps are compared across devices

- **WHEN** a stamp written on one device is compared with one written on another
  in a different time zone
- **THEN** the comparison reflects which happened first

#### Scenario: Nothing consumes the metadata yet

- **WHEN** the app runs with no account and no network
- **THEN** the metadata is maintained and nothing attempts to send it, prompt for
  an account, or behave differently because of it

### Requirement: The database opens without network, account, or first-frame cost

The system MUST create and open its database locally, and MUST NOT place that
work on the path to the first frame.

#### Scenario: Fresh install in airplane mode

- **WHEN** the app is launched for the first time with no network and no account
- **THEN** the first frame renders, the database is created on first use, and the
  player is shown no prompt, spinner, or error

#### Scenario: Cold start is unchanged

- **WHEN** the app is cold-started
- **THEN** opening the database does not delay the first frame

#### Scenario: Where the database is kept

- **WHEN** the database is created
- **THEN** it is placed in the platform's application-support location, not in
  user-facing document storage, so it is not exposed to the player as a file to
  open, move, or delete

### Requirement: An unreadable database never blocks play

The system MUST recover from a corrupt, unreadable, or failed-migration database
by starting from an empty one, and MUST keep the app playable.

#### Scenario: The database cannot be opened

- **WHEN** the database file is corrupt or cannot be read
- **THEN** the app starts with empty storage and remains fully playable, showing
  no error dialog and no failure state (D-03)

#### Scenario: What was lost is not pretended away

- **WHEN** saved state was lost because storage had to be reset
- **THEN** the player is not shown a puzzle to resume that no longer exists

### Requirement: Schema changes are versioned and migrations are tested

The system MUST carry an explicit schema version and MUST preserve existing saved
state across an upgrade.

#### Scenario: Upgrading from the previous schema

- **WHEN** the app is upgraded and the schema version has advanced
- **THEN** the migration runs once, and puzzles in progress, notes, statistics,
  settings, and seen **lesson**s survive it

#### Scenario: A migration is added

- **WHEN** the schema changes
- **THEN** a test covering the upgrade from each earlier version exists and
  passes before the change ships

#### Scenario: A database from before lessons existed

- **WHEN** a database written before **lesson**s were recorded is opened
- **THEN** it migrates, and the player reads as having seen no **lesson** rather
  than as having seen them all

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
