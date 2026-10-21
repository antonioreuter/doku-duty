---
paths:
  - "lib/**/*.dart"
---

# Dart code conventions

- `flutter analyze` clean; `dart format` is enforced in CI.
- Feature-first layout: `lib/features/<capability>/`, the capability name from
  `docs/BACKLOG.md` with kebab-case turned to snake_case.
- No business logic in widgets — controllers and services own it.
- The solver, generator, technique grader, notes logic, mistake model and
  progression rules are pure Dart with **no Flutter import**, so they stay
  unit-testable in isolation.
- Every public API is documented; comments explain *why*, never *what*.
- Code reads **design tokens**; it never writes a colour, duration, radius or
  haptic literal. Eight colour tokens, never a ninth hue (constraint 4).
- Identifiers use `docs/GLOSSARY.md` terms: `unit` not `box`, `node`/`rank` not
  `level`, `note` not `pencilMark`, `rank` not `difficulty`, `stamp` not
  `coin`/`gem`/`token`.
- Note state is written on every change, never on a timer (constraint 9). A
  plausible-looking change to notes logic can break this with no visible
  symptom — before changing anything in the puzzle engine or notes logic,
  invoke `mattpocock-skills:diagnosing-bugs` rather than editing speculatively.
- When citing a source in a comment, point at `docs/specs/<capability>.md`,
  `docs/DECISIONS.md` (`D-NN`) or `docs/BACKLOG.md` (change number) — never at a
  change folder, which is deleted when the change finishes.
