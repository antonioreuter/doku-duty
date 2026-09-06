# setup-mobile-foundation

## Why

There is no Flutter project yet — the repository is documentation only, and every
one of the other 33 backlog items depends on this one. Two values in it are
expensive to change later: the bundle identifiers, which are painful to move once
the app is registered with either store, and the minimum OS versions, which set
the API floor every subsequent change is written against.

## What changes

- A Flutter application at the repository root, iOS 15+ and Android 8.0 (API 26)+,
  targeting portrait with landscape allowed on tablets only.
- Three build flavours — `dev`, `staging`, `prod` — that install side by side,
  each with its own entry point (`lib/main_dev.dart` and siblings) and its own
  visible app name.
- Bundle identifiers fixed now: `com.alreuter.dokuduty` for `prod`, with `.dev`
  and `.staging` suffixes for the other two. This is `dokuduty.alreuter.com` in
  reverse-DNS form and needs recording as the next `D-NN` in `docs/DECISIONS.md`,
  since nothing in the documents decides it today.
- Riverpod as the state container and `go_router` as the router, with a single
  route rendering a themed empty screen — the placeholder the design system
  replaces in change 2.
- The feature-first directory skeleton (`lib/features/platform_shell/`) and a
  build-time flavour config object exposing flavour, app name, and identifier.
- Sentry initialised per flavour, with release health and the DSN supplied by
  environment rather than committed.
- CI on GitHub Actions running `flutter analyze` and `dart format --set-exit-if-changed`
  on every push, plus the test suite.
- Fastlane lanes for both stores that build and sign from CI, reading signing
  material from secrets. Lanes are verifiable without a live store account.

## Constraints

**Capabilities:** `platform-shell`

Constraint 2 (input latency, no effect over 400ms) — nothing here draws the grid,
but the shell decides the render path. The empty screen ships without an
intro animation or splash delay so cold start stays inside the 2-second budget
this constraint depends on.

Constraint 6 and 7 (ads) — no ad SDK is added here at all, so neither can be
violated by this change. That is deliberate: `add-ads-integration` is change 24
and `add-remote-config` (change 4) must land before it, because the D-24 caps
have to be server-tunable.

The remaining constraints are untouched: this change has no puzzle, no notes, no
save state, no currency, and no failure state to get wrong.

Offline play is mandatory and this is where it is either won or lost — see below.

## Technical notes

**Grid performance:** No grid yet. The relevant commitment is negative: the shell
adds no startup work on the first-frame path — no network call, no config fetch,
no deferred-component download — because everything added there is paid on every
cold start for the life of the app. Sentry is initialised around `runApp` rather
than blocked on before it.

**Offline, cold start, app kill:** The app must reach its first frame with the
device in airplane mode, on a fresh install, with no account and no cached state.
Sentry's initialisation must not gate the first frame, and a failed crash-report
upload must be silent. There is no persisted state in this change, so app kill
has nothing to lose yet — `add-persistence-layer` (change 3) owns that.

**New dependency:** None beyond the stack already decided in `docs/TECH_STACK.md`
§1 and §3 — Flutter, Riverpod, `go_router`, Sentry, GitHub Actions, Fastlane.
This change adopts those choices; it does not reopen them. Version numbers and
current setup steps for the Sentry Flutter SDK are verified against its
documentation at implementation time rather than asserted here, per §7.

## Not doing

- **No design tokens.** The empty screen uses whatever Flutter gives it. Colour,
  type, radii, and haptics are `add-design-system` (change 2), and the token API
  there is what makes a seventh hue impossible to add.
- **No local database.** Drift, schemas, and save state are `add-persistence-layer`
  (change 3).
- **No store registration, certificates, or first upload.** Fastlane lanes are
  wired and dry-run verifiable; creating the App Store Connect and Play Console
  entries, generating signing material, and pushing the first build are developer
  actions outside this change. Listings, screenshots, age ratings, privacy
  manifests, ATT, and Data Safety are `add-store-release-pipeline` (change 34).
- **No hardware verification.** The cold-start measurements, the device platform
  checks, the live Sentry event, and the iOS signed archive move to
  `add-store-release-pipeline` (change 34) — see D-70. Everything they verify is
  implemented and shipped here; none of it could be confirmed without a physical
  device, a Sentry account, or signing certificates.
- **No analytics, attribution, ads, purchases, or auth.** Each has its own change.
- **No routing beyond one route.** The season map, cabinet, and puzzle screens
  arrive with the changes that own them; adding empty placeholder routes now
  would be guessing at their arguments.
- **No deep links.** `go_router` is chosen partly for them (`docs/TECH_STACK.md` §1),
  but the daily challenge that needs them is change 14.
