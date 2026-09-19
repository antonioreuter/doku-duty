# Delta for technique-tutorials

## ADDED Requirements

### Requirement: Every technique the ladder introduces above Greenhorn has a lesson

The system MUST provide a **lesson** for each technique D-57 introduces at Deputy
**rank** and above, and MUST NOT provide one for full house or naked single.

#### Scenario: The catalogue covers the ladder

- **WHEN** the **lesson** catalogue is read
- **THEN** it holds one **lesson** for every technique whose **rank** is harder
  than Greenhorn, and none is missing

#### Scenario: The two Greenhorn techniques are not taught here

- **WHEN** full house or naked single is looked up
- **THEN** there is no **lesson**, and this is reported as the catalogue not
  covering them rather than as an error

#### Scenario: A lesson names the technique it teaches

- **WHEN** a **lesson** is shown
- **THEN** it is titled with the technique's name as the glossary writes it

### Requirement: A lesson is a guided walkthrough ending in the player's own placement

The system MUST present a **lesson** as steps on a small fixed grid, where each
step highlights what the player should be reading, and MUST make the final step
a placement the player performs.

#### Scenario: Stepping through

- **WHEN** the player advances a **lesson**
- **THEN** the next step is shown, with the cells that step is about marked

#### Scenario: The last step is the player's

- **WHEN** the player reaches the final step
- **THEN** the **lesson** asks for the placement and waits, rather than
  performing it for them

#### Scenario: The lesson grid is not the player's puzzle

- **WHEN** a **lesson** is on screen
- **THEN** it uses its own fixed grid, and nothing the player does in it changes
  any puzzle, **solve record**, statistic, or **mistake** tally

#### Scenario: A wrong placement in a lesson costs nothing

- **WHEN** the player places the wrong digit on the final step
- **THEN** the **lesson** says so and lets them try again, no **mistake** is
  recorded, and the **lesson** cannot be failed or ended by it (constraint 1)

### Requirement: A lesson fires when a puzzle that needs it is opened

The system MUST show the **lesson** for a technique when a puzzle requiring that
technique is opened, while the technique has neither been seen nor become a
**technique unlock**, and MUST show at most one **lesson** per opening — the
hardest one due (D-106).

#### Scenario: Meeting a technique for the first time

- **WHEN** the player opens a puzzle requiring a technique they have not seen a
  **lesson** for and have never solved a puzzle requiring
- **THEN** that technique's **lesson** is shown before the grid

#### Scenario: Only one, however many are due

- **WHEN** an opened puzzle requires several techniques that are all due
- **THEN** exactly one **lesson** is shown, for the hardest of them, and the
  others remain due for a later opening (D-106)

#### Scenario: A technique already solved is not taught

- **WHEN** the player opens a puzzle requiring a technique that is already a
  **technique unlock**
- **THEN** no **lesson** is shown for it, because they have demonstrated it
  (D-104)

#### Scenario: A lesson already seen does not return

- **WHEN** the player opens a second puzzle requiring a technique whose
  **lesson** they have already seen or skipped
- **THEN** no **lesson** is shown

#### Scenario: The puzzle opens either way

- **WHEN** a **lesson** is completed, or skipped
- **THEN** the puzzle the player chose opens, unchanged and with nothing
  withheld

#### Scenario: Nothing is taught for a puzzle that needs nothing new

- **WHEN** the player opens a puzzle whose techniques are all seen, all
  unlocked, or all outside the catalogue
- **THEN** the grid opens directly, with no **lesson** and no pause

### Requirement: The notes lesson lands before notes are needed

The system MUST show the **notes lesson** when the first Sheriff-rank puzzle is
opened, on the same terms as every other **lesson**.

#### Scenario: Reaching Sheriff-rank work

- **WHEN** the player opens a Sheriff-rank puzzle for the first time
- **THEN** the **notes lesson** is shown before the grid

#### Scenario: It lands before Marshal

- **WHEN** the player first opens a Marshal-rank puzzle having played through
  Sheriff
- **THEN** the **notes lesson** has already been shown, because notes are
  effectively required from Marshal upward

#### Scenario: A player who skipped past Sheriff is still taught notes

- **WHEN** the player opens a puzzle at a **rank** harder than Sheriff without
  ever having opened a Sheriff-rank one
- **THEN** the **notes lesson** is shown, because the soft **rank** gate (D-103)
  lets them arrive by that route and "the first Sheriff-rank puzzle" would
  otherwise be a door they never walk through

#### Scenario: It comes before a technique lesson due at the same time

- **WHEN** the **notes lesson** and a technique **lesson** are both due on one
  opening
- **THEN** the **notes lesson** is the one shown, being the prerequisite for
  every technique above Deputy rather than a peer of them

#### Scenario: No technique unlock can suppress it

- **WHEN** the player has demonstrated every technique in the ladder
- **THEN** the **notes lesson** is still due if unseen, because it teaches no
  technique and no counter stands for it (D-104)

#### Scenario: It does not return

- **WHEN** a second Sheriff-rank puzzle is opened after the **notes lesson** was
  shown or skipped
- **THEN** it is not shown again

### Requirement: A lesson can always be skipped, and skipping keeps it recoverable

The system MUST let the player leave any **lesson** in one action, MUST record a
skipped **lesson** as seen, and MUST keep it replayable afterwards.

#### Scenario: Skipping

- **WHEN** the player skips a **lesson**
- **THEN** it closes in one action and the puzzle opens

#### Scenario: A skipped lesson does not fire again

- **WHEN** the player opens another puzzle requiring the technique they skipped
- **THEN** no **lesson** is shown, because a lesson that returned after being
  declined would be nagging rather than teaching

#### Scenario: A skipped lesson is not lost

- **WHEN** the player looks for a **lesson** they skipped
- **THEN** it is replayable, because a skip that destroyed the lesson would make
  one tap a trap

#### Scenario: Nothing is withheld from a player who skips every lesson

- **WHEN** the player skips every **lesson** they are shown
- **THEN** no puzzle, **rank**, or feature is withheld, and no record counts the
  skipping (constraint 1)

### Requirement: Lessons can be replayed on demand

The system MUST offer a list of every **lesson**, showing which have been seen,
and MUST replay any of them whether or not it has been seen.

#### Scenario: Replaying

- **WHEN** the player chooses a **lesson** from the list
- **THEN** it plays from the first step

#### Scenario: A lesson not yet met can still be read

- **WHEN** the player chooses a **lesson** for a technique they have never met
- **THEN** it plays, and nothing is locked or withheld (constraint 1)

#### Scenario: Replaying does not disturb the ladder

- **WHEN** a **lesson** is replayed
- **THEN** no **technique unlock**, counter, **rank**, or statistic changes

#### Scenario: Seen is shown without being a score

- **WHEN** the list is read
- **THEN** each **lesson** shows whether it has been seen, phrased as not yet
  seen rather than as locked, incomplete, or missed (constraint 1)

### Requirement: Lessons are available without network

The system MUST present every **lesson** from content carried in the app.

#### Scenario: Offline

- **WHEN** the device has no network
- **THEN** every **lesson** fires, plays, and replays in full
