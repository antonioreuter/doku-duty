# Tasks — add-technique-tutorials

`technique-tutorials` is not on the project's test-first list, so the rule is not
imposed here. Sections 2 and 3 follow it anyway: which **lesson** is due is pure
logic over the ladder, and it is wrong in a way nobody notices — a lesson that
silently stops firing teaches nothing and reports nothing.

The bulk of this change is **content**, not mechanism. Eleven walkthroughs have
to be written and each needs a grid where the technique is genuinely the next
step. Section 4 is the long pole; sections 5 to 7 are the frame around it.

## 1. The decision and the vocabulary

- [x] 1.1 `docs/DECISIONS.md` gains **D-106**: at most one **lesson** per puzzle
      opening, the hardest one due. Rationale covers the rejected alternative —
      showing every due **lesson** — and why it loses: a queue of lessons in
      front of a grid is the opposite of the "short" the spec asks for, and the
      soft **rank** gate (D-103) means a Greenhorn can open a Legend puzzle and
      meet six at once
- [x] 1.2 Glossary entries for **lesson** and **notes lesson** in
      `openspec/project.md` *(added while writing the specs — verify against
      what was built and correct them if they drifted)*

## 2. Storage

- [x] 2.1 Failing test: a **lesson** marked seen reads as seen, and one never
      marked does not
- [x] 2.2 Schema 3 → 4 with a table of seen **lesson**s, keyed by lesson id,
      carrying the sync metadata the other tables already carry
- [x] 2.3 Migration test v3 → v4, and a data-integrity test that a database with
      saves, notes, a tally, and **solve record**s keeps all of them
- [x] 2.4 Test the upgrade case explicitly: a v3 database has no seen
      **lesson**s, so every **lesson** is still due — never all-seen, which is
      the direction that would silently suppress the whole feature
- [x] 2.5 Seen is written when a **lesson** is completed *or* skipped, before the
      puzzle opens. Test both routes, and test that a kill straight afterwards
      leaves it seen (constraint 9)

## 3. Which lesson is due, in pure Dart

- [x] 3.1 Failing test: a technique with no **lesson** in the catalogue is never
      due — full house and naked single, at any **rank**
- [x] 3.2 Failing test: a technique that is a **technique unlock** is never due,
      even if its **lesson** was never seen (D-104)
- [x] 3.3 Failing test: a technique whose **lesson** was seen is never due, even
      if it was skipped rather than completed
- [x] 3.4 Failing test: given several due, the rule picks the hardest by the
      D-57 ladder, and the others stay due (D-106)
- [x] 3.5 Failing test: nothing due returns nothing — an ordinary answer, not an
      error, and not a **lesson** picked at random to fill the gap
- [x] 3.6 `lib/features/technique_tutorials/domain/` — the rule satisfying
      3.1–3.5, pure Dart. A test asserts no Flutter import, as
      `puzzle_engine` and `rank_progression` already do
- [x] 3.7 Failing test, then the code: the **notes lesson** is due on a
      Sheriff-rank puzzle when unseen, and is not a technique, so it cannot be
      suppressed by a **technique unlock**. Test it against all six **rank**s

## 4. The eleven lessons

Each **lesson** is a fixed grid, an ordered list of steps, and one placement the
player makes. Content, so each is its own task — and each carries the same two
tests, that its final placement is the only correct one and that the technique
it teaches is genuinely available on its grid.

- [x] 4.1 A step model and a catalogue keyed by lesson id, with a test that every
      id in the catalogue resolves and every technique above Greenhorn has one
- [x] 4.2 Hidden single (Deputy)
- [x] 4.3 Naked pair (Sheriff)
- [x] 4.4 Pointing pair (Sheriff)
- [x] 4.5 Box-line reduction (Marshal)
- [x] 4.6 Naked triple (Marshal)
- [x] 4.7 Hidden pair (Ranger)
- [x] 4.8 X-wing (Ranger)
- [x] 4.9 Swordfish (Legend)
- [x] 4.10 XY-wing (Legend)
- [x] 4.11 Simple chain (Legend)
- [x] 4.12 The **notes lesson** — what a note is, the fixed positional slots, and
      that a note is never a **mistake** (D-09, D-10, D-14, constraint 3)
- [x] 4.13 A test over the whole catalogue: every **lesson**'s grid is a legal
      sudoku position, and the solver confirms the technique it teaches applies
      there. A **lesson** that taught a pattern its own grid does not contain is
      the failure that would survive every other test here

## 5. The lesson surface

- [x] 5.1 The walkthrough widget: a small grid, the current step's cells marked,
      and a control to advance. Its own painter — `GridPainter` draws **note**s,
      **completion tint**s and peer highlighting and a **lesson** needs none of
      it
- [x] 5.2 The final step asks for the placement and waits. Test that the
      **lesson** does not perform it
- [x] 5.3 A wrong placement says so and allows another try. Test that no
      **mistake** is recorded, nothing ends, and the **lesson** cannot be failed
      (constraint 1)
- [x] 5.4 Skip is one action and is present on every step. Test that it is never
      absent and never disabled
- [x] 5.5 Test that a **lesson** touches nothing outside itself: no
      **solve record**, no counter, no **rank**, no **mistake** tally, no puzzle
      save
- [x] 5.6 Golden test of three states: first step, mid-walkthrough with cells
      marked, and the final placement prompt

## 6. Firing on open

- [x] 6.1 The due **lesson** is computed from the technique set the open already
      grades, so no solver run is added. Test that opening a puzzle grades once,
      as it did before this change
- [x] 6.2 The **lesson** is shown before the grid, and the puzzle opens behind it
      whether it is completed or skipped. Test both routes through the real
      screens
- [x] 6.3 Test that a puzzle needing nothing new opens directly, with no pause
      and no empty **lesson** frame
- [x] 6.4 Test that exactly one **lesson** appears however many are due, and that
      the others are still due on the next opening (D-106)
- [x] 6.5 Test the **notes lesson** on the first Sheriff-rank puzzle, and that it
      has landed before the first Marshal-rank puzzle opens
- [x] 6.6 Test that a player who skips everything is never blocked: every
      **rank**, every puzzle, every control still reachable (constraint 1)

## 7. Replay

- [x] 7.1 A Lessons row on the settings screen opening a list of all eleven, each
      showing whether it has been seen
- [x] 7.2 Test that an unseen **lesson** is replayable — nothing is locked, and
      the list says not yet seen rather than locked or missed (constraint 1)
- [x] 7.3 Test that replaying changes no record: not seen, not a
      **technique unlock**, not a counter, not a **rank**
- [x] 7.4 Keep the list a widget the cabinet can adopt whole, and say so in a
      comment — `add-trophy-cabinet` (change 16) moves it, and
      `settings_screen.dart` is where it lives until then

## Platform checks

- [x] Verified on iOS — `integration_test/technique_tutorials_test.dart` on the
      iPhone 17 simulator: every **lesson**'s grid still holding the technique
      it teaches when the engine is asked on the device, stepping through to the
      placement with a wrong digit first (which costs nothing there too), a seen
      record surviving a close-and-reopen of a real database file, and the
      schema arriving at 4 with nothing seen
- [x] Verified on Android — the same five on the API 37 emulator. **The v3
      database is a real one**: the test writes it with the same generated v3
      schema helper the host migration test uses, closes it, and lets the real
      app open and migrate it on the device's own SQLite — the solved puzzle
      survives and `seen_lessons` arrives empty, so an upgrading player is owed
      every **lesson** rather than none
- [x] Accessibility: the marked cells carry a ring as well as a fill, asserted
      on the painter rather than the pixels (constraint 5); the step's sentence
      is announced by a screen reader, and the advance and skip controls by
      name, while the grid beside them is excluded rather than read cell by
      cell; the surface holds at 1× through 5× on a 320×568 phone with no
      overflow and no truncated step text (D-84, D-93) — and **the skip control
      stays on screen at every one of those sizes**, which is why it is pinned
      below the scroll rather than appended to it; no motion of its own, so
      nothing for **reduce effects** to silence, asserted by no frame being
      scheduled after the lesson settles
