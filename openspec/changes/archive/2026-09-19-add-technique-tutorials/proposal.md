# add-technique-tutorials

## Why

The **rank** ladder is a curriculum that has never taught anything. D-57 maps ten
techniques onto six **rank**s and `add-rank-progression` made a **technique
unlock** readable, but nothing has ever explained a technique to the player —
they meet a naked pair by being stuck on one. D-67 already leans on this change
by name: one free hint per puzzle exists so a new player is not walled at Marshal
"exactly where the technique tutorials are meant to carry them", and that
sentence describes something that does not exist yet.

## What changes

- A **lesson** for each of ten techniques — every one D-57 introduces except full
  house and naked single, which are not techniques so much as the game itself
  (change 33 owns a player who cannot find those).
- A **lesson** is a guided walkthrough on a small fixed grid: highlights step
  through the reasoning as the player taps onward, and the last step is the
  player making the placement. Short, and interactive where it counts.
- A **lesson** fires when a puzzle requiring that technique is *opened*, and only
  while the technique is neither seen nor a **technique unlock** already. Firing
  on encounter is what `docs/SPEC.md` §4 asks for; the unlock is what stops it
  firing again (D-104).
- **At most one per puzzle opening**, the hardest one due (D-106). A queue of
  lessons in front of a grid is the opposite of short.
- A **notes lesson**, on the same encounter rule, the first time a Sheriff-rank
  puzzle is opened — one full **rank** before Marshal, where notes stop being
  optional.
- Every **lesson** is skippable in one tap, and skipping marks it seen. The
  settings screen gains a Lessons row that replays any of them, which is where
  a skipped one is recovered.
- Which lessons have been seen is stored, survives an app kill, and outlives
  every **season**. Schema 3 → 4.

## Constraints

**Capabilities:** `technique-tutorials`

**1 — Non-punitive.** A **lesson** is never a gate. It cannot be failed, it has
no score, the puzzle behind it opens whether it is completed or skipped, and no
**rank** or puzzle is withheld from a player who has seen none of them. Skipping
costs one tap and the lesson stays recoverable from settings — a skip that
destroyed the lesson would make the skip a trap.

**2 — Latency.** A **lesson** is a separate surface shown before the grid, not
an overlay on a live board, so nothing here is in-puzzle motion and nothing
delays a tap. Which lesson is due is computed from the technique set the open
already grades (`add-rank-progression`), so no solver run is added.

**9 — Write on change.** Seen is written the moment a **lesson** is completed or
skipped, not at the end of the puzzle. A lesson skipped and then lost to a crash
would fire again, which is the small version of the same failure.

## Technical notes

**Grid performance:** none. The walkthrough grid is its own small widget and is
never on screen with a live puzzle. The existing painter is not touched — reusing
`GridPainter` was considered and rejected: it draws a 9×9 board with **note**s,
**completion tint**s, and peer highlighting, and a lesson needs none of that.

**Offline, cold start, app kill:** entirely local. Lesson content is compiled
into the app rather than fetched, so it works offline and cannot arrive late;
`add-remote-config` is deliberately not involved, because a lesson that failed to
load would block the ladder it exists to teach. Seen rows are Drift, written on
change, and survive a kill. Nothing here touches the first frame.

**New dependency:** none.

## Not doing

- **The cabinet.** Replay lives in settings for now; `add-trophy-cabinet`
  (change 16) moves the list where `docs/SPEC.md` §5.1 wants it. The list is a
  widget either way, so that is a reparent, not a rebuild.
- **Hints.** A **lesson** teaches a technique in the abstract; pointing at *this*
  board is the hint meter, which is `add-perks` (change 19) and is metered.
  Nothing here reads the player's current puzzle.
- **Teaching full house and naked single.** Change 33 owns first-run.
- **Characters.** The Sheriff's grudging approval on a technique unlock is in the
  reaction table (`docs/SPEC.md` §6) and belongs to `add-character-system`
  (change 20). No **lesson** has a speaker.
- **Localisation.** Lesson copy is written in English against the vocabulary in
  `openspec/project.md`; `add-localization` (change 32) is where it moves into
  the infrastructure.
- **Sound.** No audio package is chosen (`docs/TECH_STACK.md`), and this change
  does not pick one.
