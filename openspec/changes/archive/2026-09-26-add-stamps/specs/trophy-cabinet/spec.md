# Delta for trophy-cabinet

## ADDED Requirements

### Requirement: The cabinet shows the stamp balance

The system MUST show the player's **stamp** balance in the **cabinet**, read
from the recorded **earning**s, with no network, and MUST NOT show it on the
**trail** or the grid (D-134, D-114).

#### Scenario: A player with earnings

- **WHEN** a player who has earned 17 **stamp**s opens the **cabinet**
- **THEN** it shows a balance of 17

#### Scenario: A new player

- **WHEN** a player who has earned nothing opens the **cabinet**
- **THEN** it shows a balance of 0, as a number rather than an empty space or a
  prompt to get more

#### Scenario: The trail

- **WHEN** the **trail** is shown
- **THEN** no **stamp** count appears on it or on any **node** marker
