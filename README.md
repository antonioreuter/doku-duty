# Doku Duty

A funny, non-punitive sudoku game for iOS and Android. You are a frontier deputy
who files numbers for a living.

Flutter, single codebase. Spec-driven with OpenSpec.

## Documents

| File | What it is |
|---|---|
| `docs/IDEA.md` | Product description — start here |
| `docs/SPEC.md` | Full specification |
| `docs/DECISIONS.md` | 70 numbered decisions with rationale, cited as D-NN |
| `docs/DESIGN.md` | Colour, type, motion, and haptic values |
| `docs/ART-BRIEF.md` | Brief for the character illustrator |
| `docs/TECH_STACK.md` | The decided stack and why — canonical for technology choices |
| `docs/doku-duty-game-bible.md` | Mechanism, rules, objectives, and narrative in one place |
| `docs/SETUP.md` | How to set this repository up |
| `openspec/BACKLOG.md` | 34 changes, dependency-ordered |
| `openspec/project.md` | Conventions and glossary |

## Running

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

Flavours: `dev`, `staging`, `prod`. All three install side by side — each has
its own identifier and its own launcher name, so a `dev` build is recognisable
without launching it.

| Flavour | Identifier (D-69) | Shows as |
|---|---|---|
| `dev` | `com.alreuter.dokuduty.dev` | Duty DEV |
| `staging` | `com.alreuter.dokuduty.staging` | Duty STG |
| `prod` | `com.alreuter.dokuduty` | Doku Duty |

There is deliberately no `lib/main.dart`. Every entry point carries a flavour,
so no build can run without one.

Minimum OS: iOS 15, Android 8.0 (API 26).

## Releasing

```bash
FLAVOUR=prod bundle exec fastlane android build_release
FLAVOUR=prod bundle exec fastlane ios build_release
```

The lanes build and sign. They do not upload — store registration, listings, and
submission are `add-store-release-pipeline` (backlog change 34).

Both lanes run `flutter clean` first, and that is not defensive tidiness: a
changed `--dart-define` does **not** invalidate the cached Gradle release build,
so an incremental release build can silently keep the previous `SENTRY_DSN`, or
none at all.

### Secrets the lanes expect

None of these are committed. Set them in the environment locally and as
repository secrets in CI.

| Variable | Used by | What it is |
|---|---|---|
| `SENTRY_DSN` | both | Crash reporting endpoint. Empty is valid and disables the SDK outright |
| `ANDROID_KEYSTORE_PATH` | android | Path to the upload keystore |
| `ANDROID_KEYSTORE_PASSWORD` | android | Keystore password |
| `ANDROID_KEY_ALIAS` | android | Key alias inside the keystore |
| `ANDROID_KEY_PASSWORD` | android | Key password |
| `MATCH_PASSWORD` | ios | Passphrase for the `match` certificate repository |
| `APP_STORE_CONNECT_API_KEY_ID` | ios | App Store Connect API key id |
| `APP_STORE_CONNECT_API_ISSUER_ID` | ios | App Store Connect issuer id |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | ios | The `.p8` key, base64-encoded |
| `APPLE_ID` | ios | Apple account email, for `Appfile` |
| `APP_STORE_CONNECT_TEAM_ID` | ios | App Store Connect team id |
| `DEVELOPER_PORTAL_TEAM_ID` | ios | Developer portal team id |

For local Android runs you may instead write `android/key.properties` with
`storeFile`, `storePassword`, `keyAlias`, and `keyPassword`. It is git-ignored.
The environment wins where both are present.

## Working on it

```
/opsx:propose <name>
/opsx:apply
/opsx:archive
```

See `docs/SETUP.md` for the full loop and `openspec/BACKLOG.md` for what to build
next.

## Rules that are not negotiable

The ten constraints in `openspec/config.yaml`. The short version: nothing
punishes the player, nothing blocks input, notes hold nine candidates in fixed
positions, no colour does two jobs, no ad interrupts a grid, and the game works
offline. Every one has a decision behind it in `docs/DECISIONS.md`.
