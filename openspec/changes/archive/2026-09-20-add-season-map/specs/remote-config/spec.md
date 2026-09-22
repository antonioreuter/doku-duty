# Delta for remote-config

## ADDED Requirements

### Requirement: A season is defined by configuration

The system MUST read the current **season** — its name, its start, its length,
and its 42 **node**s with their **node type** and **rank** — from the remote
configuration document, and MUST fall back to a compiled-in **season** when no
usable one is published.

#### Scenario: A season is published

- **WHEN** a valid **season** is published
- **THEN** it is carried by the configuration from the next fetch onward, and
  becomes the **season** in force at the next launch

#### Scenario: A season arrives while the player is on the trail

- **WHEN** a refresh lands a different **season** mid-session
- **THEN** the **trail** the player is looking at does not change under them,
  and where they stand on it is unaffected — the published **season** takes
  effect at the next launch, which is the next moment nobody is mid-**node**

#### Scenario: No season is published

- **WHEN** the configuration document carries no **season**
- **THEN** the compiled-in **season** is used, exactly as every other key falls
  back to its compiled-in value

#### Scenario: A published season cannot be read

- **WHEN** a published **season** is malformed, or does not hold exactly 42
  **node**s in the composition the **season** requires
- **THEN** it is ignored, the previous **season** stands, and the player is told
  nothing — degrading one key at a time as the existing requirement demands

#### Scenario: The player is offline

- **WHEN** no configuration has ever been fetched
- **THEN** the compiled-in **season** is in force and the full trail is playable

### Requirement: A season may repaint the surfaces it is drawn on

The system MUST let a **season** definition carry a palette for the two surface
tokens, MUST use the default surfaces when it carries none or carries one that
cannot be read, and MUST NOT allow a **season** to change any **state colour**
(D-55, constraint 4).

#### Scenario: A season carries a palette

- **WHEN** a **season** is published carrying a palette
- **THEN** the surfaces it names are repainted wherever they are drawn

#### Scenario: A season names a state colour

- **WHEN** a published palette names one of the six **state colour**s
- **THEN** that **state colour** is unchanged, and the rest of the palette still
  applies

#### Scenario: A season carries no palette, or an unreadable one

- **WHEN** a **season** carries no palette, or one missing a surface, or one
  whose value is not a colour
- **THEN** the default surfaces are used and the **season** itself still
  applies — a territory is worth having with the wrong sand colour and is not
  worth losing over one
