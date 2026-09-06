# Tasks — setup-mobile-foundation

None of the load-bearing pure-logic systems named in `openspec/config.yaml`
under `rules.tasks` appears in this change, so no test-first ordering is
mandated by the rules. The one piece of pure logic here — the flavour config —
is still written test-first, because everything downstream reads it.

## Hardware verification moved to change 34

Every task this change can close is closed. Five verification steps that needed
a physical device, a Sentry account, or signing certificates were moved to
`add-store-release-pipeline` (backlog change 34), which owns the release
checklist and depends on real hardware anyway. Recorded as D-70.

What moved, and what was already established before it moved:

| Moved | Already verified here |
|---|---|
| Cold start on a mid-tier Android device, and on an iOS device | Nothing usable — the same binary measured 931ms and 3189ms on an emulator depending on host load (section 8) |
| The iOS half of the orientation check | The Android half: a phone ignores rotation, an `sw800dp` tablet follows it. On iOS the built `Info.plist` declares iPhone portrait-only and iPad all four, which is the mechanism iOS enforces |
| A real Sentry event, tagged `dev` | That a broken DSN with no network produces no dialog, banner, or retry prompt, on both platforms |
| The iOS signing half of the Fastlane lane | The Android lane end to end: a signed AAB verified against a throwaway key read from environment variables, and its missing-secrets guard firing |
| The per-platform device checks | Three flavours installed side by side on an Android emulator and an iOS simulator, with the right identifiers and launcher names |

The accessibility check moved for a different reason: the screen is empty, so
there is no text to scale and no colour acting as a sole cue. It has nothing to
test until `add-design-system` (change 2) introduces the first thing it could
check.

**What this leaves unproven.** The cold-start scenario in this change's delta
spec is a real requirement and it is not evidenced. It archives into
`openspec/specs/` as intent, not as a measured fact, and change 34 is where it
becomes one.
## 1. Record the decision

- [x] 1.1 Append the bundle identifier choice to `docs/DECISIONS.md` as the next
      `D-NN`: `com.alreuter.dokuduty` for `prod`, `.staging` and `.dev` for the
      other flavours, with the rationale that it is `dokuduty.alreuter.com` in
      reverse-DNS form and that moving it after store registration is painful.

## 2. Project skeleton

- [x] 2.1 Create the Flutter project at the repository root, iOS and Android
      targets only, package name `com.alreuter.dokuduty`. Verify `flutter run`
      launches the default counter app on one device before going further.
- [x] 2.2 Set the OS floors — iOS deployment target 15.0 in the Xcode project and
      Podfile, `minSdk 26` in `android/app/build.gradle` — and confirm
      `flutter build` succeeds for both.
      *Note: Flutter 3.44 integrates plugins with Swift Package Manager here, so
      no Podfile is generated at all. The deployment target lives only in the
      Xcode project. Verified in the built app: `MinimumOSVersion = 15.0`.*
- [x] 2.3 Delete the generated counter app and replace it with an empty
      `MaterialApp` so nothing generated survives into the first commit.
- [x] 2.4 Create the feature-first skeleton `lib/features/platform_shell/` with
      the layout `openspec/project.md` describes, and a `.gitignore` covering
      build output, Pods, and local signing material.

## 3. Flavour configuration

- [x] 3.1 Write a failing unit test for the flavour config: three flavours, each
      resolving to its own identifier, display name, and Sentry environment
      string, with `prod` carrying no identifier suffix.
- [x] 3.2 Implement the flavour config as pure Dart with no Flutter import, so
      the test passes.
- [x] 3.3 Add the three entry points — `lib/main_dev.dart`, `lib/main_staging.dart`,
      `lib/main_prod.dart` — each passing its flavour into a shared bootstrap.
- [x] 3.4 Configure Android product flavours with `applicationIdSuffix` `.dev`
      and `.staging`, and per-flavour app labels.
- [x] 3.5 Configure iOS schemes and build configurations for the three flavours,
      with per-configuration bundle identifier and display name.
- [x] 3.6 Install all three flavours on one Android device and confirm three
      icons appear, each with its own name and its own data.
- [x] 3.7 Install all three flavours on one iOS device and confirm the same.

## 4. App shell

- [x] 4.1 Add Riverpod and wrap the app in a `ProviderScope`; expose the flavour
      config as a provider.
- [x] 4.2 Add `go_router` with exactly one route rendering an empty themed
      surface. No splash animation, no timed delay before it is interactive.
- [x] 4.3 Lock orientation to portrait on phones and allow landscape on tablets.
      *Verified on Android for both device classes. The iOS rotation check moved
      to change 34; the orientations are declared in the built `Info.plist`.*
- [x] 4.4 Add a widget test asserting the app builds to the single route and
      renders without a network call.

## 5. Crash reporting

- [x] 5.1 Check the Sentry Flutter SDK's current documentation for the
      initialisation API, release-health setup, and the supported version range
      before writing any of it. `docs/TECH_STACK.md` §7 asks for this; do not
      write the integration from memory.
- [x] 5.2 Initialise Sentry inside the shared bootstrap with the environment set
      from the flavour, the DSN read from a compile-time environment variable,
      and initialisation kept off the path to the first frame.
      *Note: uses Sentry's documented `appRunner` form, so startup errors are
      captured. An attempt to move initialisation off the first-frame path was
      abandoned once the measurements it was based on turned out to be invalid
      — see section 8. With no DSN the SDK is not merely skipped, it is
      tree-shaken out of the binary.*
- [x] 5.3 Verify the first frame still renders with an invalid DSN and with the
      device in airplane mode — no dialog, no banner, no retry prompt. Verified
      on both platforms. *The "within the cold-start budget" half moved to
      change 34: no emulator on this host can test a 2-second budget.*
- 5.4 → **moved to change 34.** Needs a Sentry account and a real DSN.

## 6. Continuous integration

*The workflow file is written and every command it runs was verified locally
(the format check was confirmed to fail on a deliberately misformatted file and
pass after the revert). The workflow itself has not executed on GitHub — there
is no commit and no remote yet, so its first real run is the first push.*

- [x] 6.1 Add a GitHub Actions workflow running `flutter analyze` and
      `dart format --set-exit-if-changed .` on every push, and confirm it fails
      on a deliberately misformatted file before it is fixed.
- [x] 6.2 Add the test job to the same workflow.
- [x] 6.3 Add debug build jobs for Android and iOS with Gradle and Pods caching,
      so a broken platform build is caught on the branch that broke it.

## 7. Fastlane

- [x] 7.1 Add the Android Fastlane lane that builds and signs a release bundle,
      reading the keystore and credentials from environment secrets. Verify it
      runs to a signed artefact locally with a throwaway keystore.
- [x] 7.2 Add the iOS Fastlane lane that builds and signs an archive, reading
      signing material from environment secrets rather than the local keychain.
      *Lane written and listed by `fastlane lanes`; its missing-secrets guard was
      confirmed to fire. The signing path itself could not be exercised — it
      needs a `match` certificate repository and an App Store Connect API key,
      and certificates are explicitly out of scope for this change.*
- [x] 7.3 Document in `README.md` which secrets each lane expects, so the store
      registration in change 34 is a matter of filling them in rather than
      rediscovering them.

## 8. Cold start

**Not measurable on the hardware available; no evidence that Sentry costs
anything.**

An earlier run of this session appeared to show Sentry adding ~1.6s to cold
start. That was wrong, and the way it was wrong is worth keeping:

- The Gradle release build does not reliably rebuild when its inputs change.
  A changed `--dart-define` does not invalidate it, and neither did a changed
  Dart source file. Two "Sentry variants" built to compare options turned out
  to be byte-identical to each other and to contain no DSN at all, so both
  measured an app with Sentry disabled. Every release build in this repository
  must therefore be preceded by `flutter clean`, and the Fastlane lanes do
  exactly that.
- Host load was not controlled. The same binary measured 931ms early in the
  session and 3189ms later, with a second emulator and concurrent builds
  running.

Re-measured properly — two clean builds, contents verified in `libapp.so`, one
emulator, nothing else running, interleaved A/B, first launch after install
discarded because it pays profile installation:

| Build | TotalTime (ms) | Median |
|---|---|---|
| No `SENTRY_DSN`, Sentry tree-shaken out (49.6MB) | 2824, 3132, 3168, 3183, 3195, 3235, 3401, 3889 | **3189** |
| `SENTRY_DSN` set, endpoint unreachable (53.4MB) | 2983, 3024, 3086, 3106, 3144, 3197, 3234, 3292, 3400, 3434, 3446, 3487 | **3170** |

The two are indistinguishable. Sentry is not the cost.

What this cannot tell us is whether the shell meets the 2-second budget: this
emulator measured the *same* binary at 931ms and at 3189ms depending on what
else the host was doing, so its absolute numbers are not usable for a budget
test. The budget names a mid-tier physical Android device, and that is what it
needs.

One incidental result worth keeping: because the DSN is a `const`
`String.fromEnvironment`, a build without one drops the whole Sentry branch —
the APK is 3.8MB smaller and the SDK cannot start at all.

- 8.1 → **moved to change 34.** Needs a mid-tier physical Android device.
- 8.2 → **moved to change 34.** Needs a physical iOS device.

## Platform checks

- [x] Verified on iOS — three flavours side by side on the simulator, each with
      its own identifier and launcher name; empty screen renders with a broken
      DSN; all three flavours build and carry the right `Info.plist` values
- Remaining iOS lines → **moved to change 34**: cold start, rotation on a real
  device, and a signed archive from the Fastlane lane
- [x] Verified on Android — three flavours side by side on an emulator with the
      right identifiers and labels; orientation correct for both a phone and an
      `sw800dp` tablet; empty screen renders offline with a broken DSN and shows
      no dialog, banner, or retry prompt; signed AAB produced by the Fastlane lane
- Remaining Android line → **moved to change 34**: cold start on a mid-tier
  physical device
- Accessibility → **moved to change 34** and to `add-design-system`. Nothing on
  an empty screen scales or signals by colour, so there is nothing to check yet.
