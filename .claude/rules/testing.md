---
paths:
  - "test/**"
  - "integration_test/**"
  - "lib/**/*.dart"
  - "docs/changes/**"
---

# Testing

**Test-first is required for the load-bearing pure-logic systems.** This is the
canonical list — do not copy it into another file; four partial copies once
disagreed about what was on it:

- the puzzle engine, including generation and grading
- all notes logic — settled notes, provisional notes, and auto-cleanup
- the mistake model
- rank progression

They carry no Flutter import, so there is no excuse for leaving them untested,
and a silent bug in any of them corrupts saved player progress. Use
`mattpocock-skills:tdd` and let the failing test drive the shape.

Also required:

- Widget tests for grid interaction and input modes.
- Golden tests for the eight colour tokens and their derived tints (D-71).
- An integration test asserting no ads are served under an active entitlement
  — a release blocker (constraint 7).

**Test a hook through the production wiring, not only in isolation.** A service
with passing tests and no production caller is indistinguishable from a working
one until someone plays the app (`wire-completion-events`).
`test/features/grid_input/support/production_solve.dart` drives a solve
through the real `boardSinkProvider` for exactly this.

**A task is done when its test passes on both platforms, not when it
compiles.** The simulator lies about haptics and frame timing. A native
dependency that passes on the test host can be missing from the APK or IPA;
say how it is verified on a device.

Do not report a green run you did not observe. Report what failed, with the
actual output.
