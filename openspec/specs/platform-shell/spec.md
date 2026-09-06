# platform-shell

## Purpose

The Flutter application shell: the two platform targets, the three flavours, the
router, the state container, and crash reporting. Everything a player sees is
owned by another capability; this one is what those capabilities are built on.

Established by `setup-mobile-foundation`. The bundle identifiers and OS floors
are fixed by D-69.

## Requirements

### Requirement: Supported platforms and OS floor

The system MUST install and run on iOS 15 or later and on Android 8.0 (API 26)
or later, from a single Flutter codebase (D-31).

#### Scenario: Device below the floor

- **WHEN** the app is offered to a device running an OS older than iOS 15 or
  Android API 26
- **THEN** the store declares the device ineligible rather than the app
  installing and failing at runtime

#### Scenario: Device at the floor

- **WHEN** the app is installed on a device running exactly iOS 15 or Android
  API 26
- **THEN** it launches to the empty screen with no degraded behaviour

### Requirement: Three flavours install side by side

The system MUST build as three flavours — `dev`, `staging`, and `prod` — each
carrying a distinct bundle identifier and a distinct visible app name, so all
three can be installed on one device simultaneously.

#### Scenario: All three installed at once

- **WHEN** the `dev`, `staging`, and `prod` builds are installed on the same
  device
- **THEN** three separate icons appear, each launching its own app with its own
  data, and installing one never replaces another

#### Scenario: Identifiers are fixed

- **WHEN** any build is produced
- **THEN** its identifier is `com.alreuter.dokuduty` for `prod`,
  `com.alreuter.dokuduty.staging` for `staging`, and `com.alreuter.dokuduty.dev`
  for `dev`

#### Scenario: The running flavour is visible

- **WHEN** a player or developer looks at the home screen or the app's own
  display name
- **THEN** a `dev` or `staging` build is distinguishable from `prod` without
  launching it

### Requirement: The app reaches its first frame without network or account

The system MUST render its first frame with no network available, no account,
and no cached state, and MUST NOT place any network call, remote configuration
fetch, or downloaded component on the path to that frame.

#### Scenario: Fresh install, airplane mode

- **WHEN** the app is launched for the first time on a device in airplane mode
- **THEN** the themed empty screen appears with no error dialog, no spinner, and
  no prompt to connect

#### Scenario: No sign-in is asked for

- **WHEN** the app is launched for the first time
- **THEN** the player is a **guest** and is not shown a sign-in prompt, an
  account wall, or a paywall

#### Scenario: Cold start budget

- **WHEN** the app is cold-started on a mid-tier Android device
- **THEN** the first frame is rendered within 2 seconds

### Requirement: Single themed placeholder route

The system MUST route to exactly one screen, rendered through the app's router,
which displays an empty themed surface and no gameplay content.

#### Scenario: Launch

- **WHEN** the app finishes launching
- **THEN** the single route is shown, with no splash animation and no timed
  delay before it becomes interactive

### Requirement: Orientation

The system MUST present portrait as the primary orientation on phones, and MUST
allow landscape only on tablets.

#### Scenario: Phone rotated

- **WHEN** a phone is rotated to landscape
- **THEN** the app remains in portrait

#### Scenario: Tablet rotated

- **WHEN** a tablet is rotated to landscape
- **THEN** the app follows the rotation

### Requirement: Crash reporting never interrupts the player

The system MUST report uncaught errors and release health to the crash reporter
with the flavour recorded on each event, and MUST fail silently when it cannot
reach the network.

#### Scenario: Crash reporting is offline

- **WHEN** an error is captured while the device has no network
- **THEN** the app continues running and the player is shown nothing — no
  dialog, no banner, and no retry prompt

#### Scenario: Reporting cannot start

- **WHEN** the crash reporter fails to initialise, or its endpoint is
  unreachable
- **THEN** the app runs anyway, and the player is shown no dialog, no banner,
  and no retry prompt

#### Scenario: No reporting endpoint is configured

- **WHEN** a build carries no crash-reporting endpoint
- **THEN** the reporter never starts, and the build behaves exactly as one built
  without a crash reporter at all

#### Scenario: Events are attributable to a flavour

- **WHEN** an event is reported from a `dev`, `staging`, or `prod` build
- **THEN** it carries that flavour, so `dev` noise never contaminates `prod`
  release health
