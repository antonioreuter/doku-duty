# Delta for grid-input

## MODIFIED Requirements

### Requirement: The stored settings can be changed by the player

The system MUST offer a screen where the settings the app stores can be read and
changed, MUST keep every one of them off unless the player turns it on, and MUST
NOT show a setting the app no longer acts on.

#### Scenario: A setting is changed

- **WHEN** a setting is turned on and the app is restarted
- **THEN** it is still on

#### Scenario: The defaults are what a new player gets

- **WHEN** a player who has changed nothing opens the settings
- **THEN** **strict mode** is off, and with it both immediate flagging and the
  three-**mistake** cap (D-04, constraint 1)

#### Scenario: Strict mode is one row, not two

- **WHEN** the player looks for a way to flag errors without the
  three-**mistake** cap
- **THEN** there is no such setting, because the two behaviours are one switch

#### Scenario: A setting nothing acts on yet

- **WHEN** a setting is shown that no implemented behaviour reads
- **THEN** it is marked as not yet in effect, because a control that appears to
  work and does nothing is worse than one that is absent

#### Scenario: Turning strict mode on says what it does

- **WHEN** the player reads the **strict mode** row
- **THEN** it states both of its effects before it is turned on, because the
  only failure state in the product should never be a surprise
