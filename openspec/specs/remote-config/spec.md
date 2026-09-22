# remote-config

## Purpose

Values that can change without shipping a release, and the discipline about
which values those are.

The mechanism is small: a set of typed values with defaults compiled into the
binary, a document fetched after the first frame, and a cache so a player who
was online once stays configured offline. Nothing ever waits on it, and no
failure is ever shown to a player — until a fetch happens to succeed, the
compiled-in values are not a degraded mode but the normal one.

The restraint is the substantive part. Ad **volume** is tunable and clamped so a
config can only tighten the limits in D-24, never loosen them; loosening needs
that decision amended and a build shipped. Ad **placement** — that an
interstitial fires only after a **node** completes, after the celebration, and
after an explicit tap, and never on a chest, boss, or daily node — is compiled
in and unreachable from any config. The caps are the feature, not the default.

Established by `add-remote-config`, ahead of `add-ads-integration` so that
change consumes these values rather than deciding where they live while it is
also writing placement logic.

## Requirements

### Requirement: Every configured value always has an answer

The system MUST return a typed value for every configured setting at all times,
falling back to a value compiled into the binary when no remote config has been
fetched, and MUST NOT expose absence, staleness, or network state to callers.

#### Scenario: Fresh install with no network

- **WHEN** a value is read on a first launch with no network and no cached config
- **THEN** the compiled-in value is returned, and the caller cannot tell that no
  fetch has happened

#### Scenario: A value is read while a fetch is in flight

- **WHEN** a value is read before the current fetch completes
- **THEN** the value currently in effect is returned immediately, without waiting

#### Scenario: Reading is synchronous

- **WHEN** any configured value is read
- **THEN** it is available without awaiting, so a caller deciding what to do next
  is never made to pause on configuration

### Requirement: A config that cannot be used is ignored, not surfaced

The system MUST continue on the values already in effect when a fetch fails, times
out, returns an error, or returns content that cannot be parsed, and MUST show the
player nothing in any of those cases.

#### Scenario: The network is unavailable

- **WHEN** a fetch is attempted with no connectivity
- **THEN** the app carries on with the values in effect, and no dialog, banner,
  spinner, or retry prompt appears

#### Scenario: The response is not valid config

- **WHEN** a fetch returns malformed content, an error status, or an empty body
- **THEN** it is discarded, the previous values remain in effect, and the failure
  is reported to the crash reporter rather than to the player

#### Scenario: No endpoint is configured

- **WHEN** a build carries no address to fetch from
- **THEN** it never attempts one, and behaves exactly as a build that has simply
  never been online — which is a fully configured app

#### Scenario: A fetch never completes

- **WHEN** a fetch hangs
- **THEN** it is abandoned after a bounded time and nothing else is affected

### Requirement: Fetching never delays the player

The system MUST NOT place a config fetch, or any wait for one, on the path to the
first frame, and MUST NOT block any player interaction on a fetch.

#### Scenario: Cold start

- **WHEN** the app is launched
- **THEN** the first frame renders without any config fetch having been awaited

#### Scenario: A value changes while the app is open

- **WHEN** a fetched config replaces the values in effect
- **THEN** the change does not interrupt, reverse, or alter anything the player
  is in the middle of

### Requirement: The last usable config survives a restart

The system MUST retain the most recent usable config and use it on the next
launch, in preference to the compiled-in values.

#### Scenario: Offline after a successful fetch

- **WHEN** the app is relaunched with no network, having fetched successfully at
  some earlier point
- **THEN** the values from that fetch are in effect, not the compiled-in ones

#### Scenario: A retained config is checked again on every read

- **WHEN** a retained config is read back by a version of the app with different
  limits or different keys from the one that stored it
- **THEN** it is interpreted under the current rules, so a retained value that
  would now be out of bounds is brought back into them

#### Scenario: The retained config is unreadable

- **WHEN** the retained config cannot be read back
- **THEN** the compiled-in values are used and the app continues normally

### Requirement: An unrecognised config degrades one key at a time

The system MUST ignore keys it does not recognise, and MUST fall back to the
compiled-in value for any individual key that is absent or cannot be interpreted,
without discarding the rest of the config.

#### Scenario: The config carries a key the app does not know

- **WHEN** a fetched config contains keys this version has no concept of
- **THEN** they are ignored and every key the app does recognise still takes
  effect

#### Scenario: One key is malformed

- **WHEN** a single value in an otherwise valid config cannot be interpreted
- **THEN** that one key falls back to its compiled-in value and every other key
  in the config still takes effect

#### Scenario: A number is written in a form a hand-edited file would use

- **WHEN** a whole number arrives written with a decimal point or in quotes
- **THEN** it is accepted, because a file people edit will contain all three
  forms

#### Scenario: A number is not whole

- **WHEN** a value that must be a whole number arrives fractional
- **THEN** it falls back to its compiled-in value rather than being rounded,
  because guessing what half of it meant is worse than the default

#### Scenario: The config declares a schema version

- **WHEN** a config is fetched
- **THEN** the schema version it declares is recorded, so a later version can be
  told apart from a corrupt one

### Requirement: Ad volume limits are tunable only downward

The system MUST allow a remote config to make the ad volume limits in D-24 more
restrictive, and MUST reject any value that would make them less restrictive than
D-24 states.

#### Scenario: A config tightens a limit

- **WHEN** a config sets a session limit below the documented maximum, or a gap
  between interstitials longer than the documented minimum
- **THEN** the stricter value takes effect

#### Scenario: A config tries to loosen a limit

- **WHEN** a config sets a session limit above the documented maximum, a gap
  shorter than the documented minimum, or a **node** interval below the documented
  one
- **THEN** that value is rejected and the documented limit remains in effect

#### Scenario: The documented limits are the defaults

- **WHEN** no remote config has been applied
- **THEN** the limits in effect are exactly those in D-24 — at most one
  interstitial per three completed **nodes**, at least ninety seconds apart, at most
  six per session

### Requirement: Ad placement rules are not configurable

The system MUST NOT expose the rules governing when an ad may appear to remote
configuration.

#### Scenario: Looking for a placement switch

- **WHEN** the set of configurable values is enumerated
- **THEN** it contains no value that could permit an ad during a puzzle, before a
  celebration completes, without an explicit tap, or on a chest, boss, or daily
  **node**

#### Scenario: A config attempts to carry one

- **WHEN** a fetched config contains a key that looks like a placement rule
- **THEN** it is ignored like any other unrecognised key

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
