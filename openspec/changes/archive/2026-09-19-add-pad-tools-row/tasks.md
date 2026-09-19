# Tasks — add-pad-tools-row

## 1. The tools row

- [x] 1.1 `PadTool` — the named controls as a type carrying a label, separate
      from `PadKey`'s digits and erase
- [x] 1.2 A labelled chip widget: full-width within its row, the label in words,
      built on the existing `Pressable` so depth and the pressed state are
      unchanged
- [x] 1.3 Test that every tool carries a visible label and no tool is a bare
      symbol
- [x] 1.4 Test that the label a player reads and the name a screen reader
      announces are the same word

## 2. What is shown, and when

- [x] 2.1 The always-present three — **Notes**, **Fill notes**, **Undo**
- [x] 2.2 The ink control appears only while notes mode is on; test both
      directions, and that the chosen ink survives the control leaving
- [x] 2.3 The two chain-test controls appear only while the board holds a
      **provisional note**; test that they arrive with the first and leave with
      the last, by every route that removes one (erase, undo, clear, promote)
- [x] 2.4 Test that nothing is ever disabled — every control on screen is
      pressable (constraint 1)
- [x] 2.5 Test the default: a puzzle opened by a player who has changed nothing
      shows three tools and three rows

## 3. Naming

- [x] 3.1 Replace `✕` and `✓` with names for what they do to the board
- [x] 3.2 Replace `~` and `⁙` with names; keep the digit keys and `⌫` as they are
- [x] 3.3 Test that no control's face is a tick or a cross, so the pair cannot
      read as confirm and cancel (D-04)

## 4. Layout

- [x] 4.1 Digit keys and tools drawn as two groups, five columns kept
      (`docs/DESIGN.md` §8)
- [x] 4.2 Golden test of the three states: default, notes mode, and a board with
      a chain test running
- [x] 4.3 Test that a label does not overflow its chip at any text size, and that
      every chip holds the 44pt minimum (D-84, D-93)
- [x] 4.4 Verify the pad still fits a small phone at the largest text size, which
      is the case `add-mistake-model` already found overflowing

## 5. Keeping it

- [x] 5.1 Carry the tools row into `docs/pages/screens.html` prose if the page
      and the built layout now disagree, so the two stop drifting
- [x] 5.2 Record the deviation from the mockup — erase stays a digit key at five
      columns — as a D-NN with its reasoning

## Platform checks

- [x] Verified on iOS — `integration_test/pad_tools_test.dart` on the iPhone 17
      simulator: every tool named and inside the pad at 1×, 1.3×, 2× and 3×,
      every chip over the 44pt floor. **Haptics not covered** — a simulator
      reports success for a haptic it never plays, so telling the light impact
      from the medium one is still a manual check on hardware
- [x] Verified on Android — the same test on the API 37 emulator, plus the
      three states walked by hand on a release build: the default three rows,
      the ink control arriving with notes mode, and the chain-test pair
      arriving with the first **provisional note**. Haptics uncovered, as above
- [x] Accessibility: every control announced by its visible name (one string
      serves both, so they cannot drift); the control in force carries
      `selected` as well as the gold fill; labels stay inside their chip at 1×
      through 5× and never truncate; `reduceMotion` is passed through to every
      chip so a player who asked for less still gets a working control
