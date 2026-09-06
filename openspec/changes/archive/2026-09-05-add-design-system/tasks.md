# Tasks — add-design-system

None of the load-bearing pure-logic systems named in `openspec/config.yaml` under
`rules.tasks` appears in this change. The token layer is still built test-first,
for a different reason: the tests *are* the enforcement mechanism. A token API
that merely documents "one colour, one job" has not done its job.

Work top to bottom; the app stays runnable after every task.

## 1. Reconcile the documents before writing the API

- [x] 1.1 Add `D-71` to `docs/DECISIONS.md`: the palette is eight tokens — six
      carrying state (ink, focus, candidate, provisional, error, completion) and
      two surfaces — and no ninth hue. Mark D-53 with
      `> **Amended by D-71**`; its one-hue-one-job principle stands, only the
      count is corrected. Do not delete or rewrite D-53.
- [x] 1.2 Correct constraint 4 in `openspec/config.yaml` to the D-71 wording.
- [x] 1.3 Correct the testing line in `openspec/project.md` ("golden tests for the
      six state colours") to match, and the palette summary if it drifts.
- [x] 1.4 Correct `docs/SPEC.md` §9.8, which says five reserved colours and "never
      add a sixth hue", to the D-71 wording. Leave the role table alone — it is
      already right.
- [x] 1.5 Add `design token`, `state colour`, and `reduce effects` to the glossary
      in `openspec/project.md`.
- [x] 1.6 Verify no document still states a colour count other than eight:
      `grep -rn "sixth hue\|seventh hue\|ninth hue\|five state\|six reserved" docs openspec`

## 2. Fix the contrast failures in the palette

- [x] 2.1 Write a pure-Dart contrast helper (WCAG relative luminance and ratio)
      with unit tests against known pairs — white/black is 21:1, `duskInk` on
      `bone` is 12.44:1.
- [x] 2.2 Write the failing test: every foreground/background pair the design uses
      meets 4.5:1 below 18px, 3:1 at or above. It fails on four pairs today —
      `turquoise` on `bone` (2.61), the `sunsetRed` on-colour (3.63), the
      `cactusGreen` on-colour (3.87), and `inkSoft` on `sand` (4.08).
- [x] 2.3 Darken those four values in `docs/DESIGN.md` §1 until the test passes.
      Change luminance only — hue and role assignments are fixed by D-65.
      Measured against all five cell backgrounds, not just `bone`: `turquoise`
      fails on every one of them (2.21–2.70).
- [x] 2.4 Record the new values as `D-72`, citing the measured ratios, so the
      reason outlives the diff. Record the `hairline` exemption there too — it is
      1.33:1 and deliberately left, so the next person to measure it does not
      "fix" it.

### 2a. The two note inks cannot be separated by hue — added scope

Darkening `turquoise` far enough to be legible drops its separation from
`nightIndigo` to 1.34:1 in normal vision and **1.14:1 under deuteranopia**. The
pairing failed constraint 5 before the contrast fix too (2.19:1 deutan). Resolved
as D-73: provisional notes carry an underline.

- [x] 2a.1 Record `D-73` — provisional notes are turquoise **and** underlined,
      settled notes are indigo with no rule — with the CVD measurements and why
      an underline beats a hollow glyph or italic at 11px.
- [x] 2a.2 Add the note-treatment token to the design system: which note kind
      carries a rule, its weight, and its offset below the baseline. The token
      layer decides it; change 9 draws it.
- [x] 2a.3 Test: the two note kinds differ in at least one non-colour attribute,
      asserted on the tokens rather than on a rendering.
- [x] 2a.4 Test the CVD case directly: simulate protanopia, deuteranopia, and
      tritanopia over the two note tokens and assert the pair is separable by the
      underline flag when the simulated hues are not.
- [x] 2a.5 Update `docs/DESIGN.md` §1 and §8 so the underline is documented where
      the positional note rules already are, and confirm it does not disturb the
      fixed 3×3 slots (D-10).

## 3. The colour tokens

- [x] 3.1 Write the failing test: the token set has exactly eight members with the
      documented names and hex values from `docs/DESIGN.md` §1 as corrected.
- [x] 3.2 Implement the token type. Each family carries its base and, where
      documented, its pale tint, its depth shade, and its on-colour text value.
      No public colour constructor; derived values are members, never top-level.
- [x] 3.3 Write the failing test that walks every `.dart` file under `lib/` and
      fails on a `Color(0x…)` literal or a `Colors.*` reference outside the token
      file. This is the enforcement, not a style check.
- [x] 3.4 Make it pass — including in the placeholder screen
      `setup-mobile-foundation` left behind.
- [x] 3.5 Golden test: a swatch sheet of all eight tokens plus every derived tint
      and depth shade.

## 4. The season theme structure

- [x] 4.1 Write the failing test: a season theme applied over the default changes
      the two surface tokens and leaves all six state colours identical.
- [x] 4.2 Implement the season theme type with fields for surfaces and props only,
      so a state colour has no field to sit in (D-55).
- [x] 4.3 Ship one default theme and one throwaway test theme with obviously
      different surfaces. Do not design a second real territory — that is
      change 15.
- [x] 4.4 Golden test: the same widget under both themes, differing in surface and
      identical in every state colour.

## 5. Type

- [x] 5.1 Write the selection criteria down before choosing: open licence (OFL or
      Apache), static weights covering 400/500/600, Latin Extended for
      localisation, tabular figures, and unambiguous 1/4/6/7/9.
- [x] 5.2 Shortlist three rounded faces and render the digits at 22px and at 11px
      on a real screen. Note legibility at 11px is the deciding test and a
      specimen sheet will not settle it. Record the winner and the rejects.
- [x] 5.3 Bundle the chosen family under `assets/fonts/` and declare it in
      `pubspec.yaml`. Do not add `google_fonts` — it fetches at runtime.
- [x] 5.4 Implement the six type roles at the sizes and weights in
      `docs/DESIGN.md` §2, and write the test asserting each role's size, weight,
      and family.
- [x] 5.5 Widget test: with the platform text-size setting at its largest, every
      role scales and nothing clips.

## 6. Shape, depth, and motion tokens

- [x] 6.1 Implement the four radii and four stroke weights from §3, with a test
      asserting the values.
- [x] 6.2 Implement the motion tokens from the §5 table, and the failing test
      first: any in-puzzle duration over 400ms that is not the cascade (520ms) or
      the puzzle-completion sequence (1400ms) fails the build (D-46, D-47).
- [x] 6.3 Implement the `easeOutBack` overshoot curve token at roughly 15%.
- [x] 6.4 Implement the depth tokens — 4–5px rest, 1px pressed, 8px total travel —
      and the per-family depth shade lookup.

## 7. Haptics

- [x] 7.1 Implement the fixed haptic vocabulary from §5: selection tick, light
      impact, medium impact, light double tap, success pattern. A named set, not
      a wrapper that passes anything through.
- [x] 7.2 Test: the vocabulary has exactly those five members, and requesting one
      on a device that cannot produce it is a no-op rather than an error.
- [x] 7.3 Test: no haptic is reachable from note entry (D-52). Assert it at the
      vocabulary level now, since there is no note entry yet to assert it at.

## 8. Reduce motion and reduce effects

- [x] 8.1 Implement the reduce-effects switch as a token-layer flag, defaulting
      off, read but not persisted here — storage is change 3.
- [x] 8.2 Test: with the platform reduce-motion setting on, every tokenised
      duration resolves to zero and every animation lands on its end state.
- [x] 8.3 Test: with reduce effects on and the platform setting off, the same
      holds — the two switches are independent.

## 9. Shared primitives

- [x] 9.1 Pressable surface: rest depth, 4px downward translate, 1px pressed
      depth, solid offset shadow in the family's depth shade. Never `BoxShadow`
      blur.
- [x] 9.2 Widget test: pressing translates and drops depth; releasing restores;
      the next tap is accepted while the release animation is still running.
- [x] 9.3 Card: solid offset shadow, card radius, and a tilt between 0.5° and 2°
      that is stable across rebuilds rather than re-randomised.
- [x] 9.4 Paper-grain overlay at 4% opacity, applied to surfaces and cheap enough
      to sit under everything.
- [x] 9.5 Test: no primitive applies depth or a thick border to anything the grid
      will draw. `docs/DESIGN.md` §4 calls this out as the exception and it is the
      easiest rule here to break by accident.
- [x] 9.6 Golden tests for the pressable in rest and pressed states, and for the
      card.

## 10. Wire it up

- [x] 10.1 Expose the theme through the existing Riverpod container and
      `MaterialApp`, so a capability reads tokens from context rather than
      importing the token file directly.
- [x] 10.2 Re-theme the placeholder screen through the tokens. It stays an empty
      screen — no gallery, no controls.
- [x] 10.3 Confirm nothing was added to the first-frame path: no network call, no
      runtime font fetch, no deferred asset. Cold start is unchanged.
- [x] 10.4 `flutter analyze` clean and `dart format --set-exit-if-changed` passing.

## Platform checks

Verified on an Android emulator (Pixel 10 Pro, API 37) and an iOS simulator
(iPhone 17 Pro, iOS 26.5), both running the `dev` flavour built from this change.

- [x] Verified on Android: the themed surface renders at exactly `#E4D4AE`
      (`sand`), and the paper grain at exactly `#DDCDA9` — which is `duskInk` at
      4% over `sand`, computed and confirmed pixel for pixel. Three distinct
      values across the sampled area, so the grain does not band. Speck density
      measured at 7060 in 640,000px, matching the one-per-90px² budget. The
      emulator was in airplane mode, which re-confirms the offline first frame
- [x] Verified on iOS: the same surface and the same grain value, with
      antialiased intermediates from the 3.0 device pixel ratio. Launches, no
      crash, no dialog

### What could not be verified on a device, and where it went

The placeholder screen is deliberately empty — the proposal excludes a debug
gallery route — so **there is no screen in this change that renders text, a
button, a card, or fires a haptic.** These four checks have nothing to look at,
which is the same situation D-70 described for the foundation's accessibility
check, and they move for the same reason. Recorded as D-75.

- [ ] *(moved to `add-grid-and-input`, change 6)* The bundled face in all six
      roles on a real screen, dynamic type scaling a real layout, the pressable's
      feel, and the tilt's stability across rebuilds. Change 6 is the first
      change that draws text and buttons. Covered here by widget tests and
      goldens, which is not the same as looking at it
- [ ] *(moved to `add-grid-and-input`, change 6)* Haptics on a physical iOS and a
      physical Android device — all five vocabulary members, and silence on note
      entry. Two reasons rather than one: nothing in this change fires a haptic,
      and the connected iPhone cannot be codesigned because no
      `DEVELOPMENT_TEAM` is configured. The simulator lies about haptics, so a
      simulator run would not have closed it either

### Accessibility

- [x] Every token pair meets its contrast budget — enforced by
      `palette_contrast_test.dart`, which fails the build on a value below its
      budget and was confirmed to fail on the pre-D-72 values. Four failures
      found and fixed (D-72)
- [x] The two note kinds are distinguishable without colour — `note_ink_test.dart`
      measures both inks under simulated protanopia, deuteranopia, and
      tritanopia, asserts hue alone does not separate them, and asserts the
      underline does (D-73)
- [x] Both inks stay above 4.5:1 on all five cell backgrounds under all three
      simulated deficiencies, not only in normal vision
- [x] Dynamic type at 1.0x, 1.3x, 2.0x, and 3.0x — every role grows and nothing
      clips. Above both platforms' maximum settings
- [x] OS reduce-motion and the in-app **reduce effects** switch each silence
      motion independently, and neither can override the other
- [x] No state introduced here is signalled by colour alone. The only state this
      change introduces is the note kind, and it carries the underline
