# add-puzzle-engine

## Why

Everything in Milestone 1 needs a puzzle to be a thing the code understands
rather than a string of digits. The grid, the notes, the mistake model, and the
rank ladder all read from it, and the grader underneath it is what makes a rank
mean anything: a puzzle graded Marshal that only needs a hidden single does not
merely mislabel one puzzle, it tells the player the ladder is arbitrary. D-07's
whole argument for technique grading is that it is honest, and honesty here is a
property of a program that has to be provably correct.

## What changes

- **A puzzle model.** An immutable 81-cell grid with the three **unit** kinds,
  peer lookup, and the candidate set for a cell. Pure data, cheap to copy, with
  no opinion about how anything is drawn.
- **A solver** implementing the twelve techniques in D-57's table — full house
  and naked single, hidden single, naked pair and pointing pair, box-line
  reduction and naked triple, hidden pair and X-wing, swordfish, XY-wing, and
  simple chains — each one able to run on its own and report what it deduced.
- **Uniqueness verification**: a separate exhaustive search that answers whether
  a grid has exactly one solution, independently of the technique solver.
- **A technique grader** that reports the hardest technique a puzzle requires,
  and the **rank** that implies (D-07, D-57). Graded by technique, never by clue
  count.
- **Validation helpers** the grid and mistake model will need: whether a
  placement conflicts with a peer, whether a placement disagrees with the
  solution, and whether a grid is complete.
- **`Rank` and `Technique` move here** from the persistence layer, where they
  were put because persistence was the first capability that had to name them.
  The file already says this change owns them.
- **A hand-verified corpus.** Each puzzle in it is there because it provably
  requires exactly one named technique, with the reasoning recorded beside it,
  and the grader is tested against that.

## Constraints

**Capabilities:** `puzzle-engine`

**Constraint 8 (one solution, solvable by logic alone)** is the one this change
exists to make true, and the only change that can. Uniqueness is verified by
exhaustive search rather than inferred from the technique solver, because a
technique solver that fails to finish tells you it ran out of techniques, not
that the puzzle is ambiguous. The two answer different questions and both are
needed.

**Constraint 5 (full offline play)** — pure Dart, no network, no runtime model
(`docs/TECH_STACK.md` §4). Solving and grading are deterministic and verifiable,
which is the property the rank ladder rests on.

**Constraint 2 (latency)** — nothing here is on a frame path yet, but the solver
is what a hint will call later (change 19), so it is written to answer a single
technique step quickly rather than only to solve a whole grid.

**Constraint 1 (non-punitive)** — the engine reports; it never judges. An
unsolvable grid, a contradictory grid, and a grid with no unique solution are
all answers this returns, never errors it throws at a player.

**Constraints 3, 4, 6, 7, 9, 10** are untouched: no notes, no colour, no ads, no
save state, no currency.

## Technical notes

**Grid performance:** No rendering. The relevant cost is the solver's, and the
shape that keeps it cheap is bitmask candidate sets — nine bits per cell — so
elimination is a mask operation rather than a set allocation. That matters twice:
the grader runs the whole technique ladder over a puzzle, and a hint will run one
step while the player waits.

**Offline, cold start, app kill:** Nothing here touches the network, the disk, or
the first frame. It is a library: it holds no state, so there is nothing for an
app kill to lose and nothing to restore.

**New dependency:** None. This is arithmetic over a 9×9 grid, and a sudoku
package would have to be trusted on exactly the point that must be provable —
whether this puzzle needs an X-wing. `openspec/project.md` requires the solver
and grader be pure Dart with no Flutter import, which also keeps them testable by
the plain test runner.

## What this deliberately leaves blocked

**There will still be no puzzles to play.** The generator is out of scope by
choice, so the app ships with no real pack, and Milestone 1's "a player can solve
a puzzle at any of six ranks" is not reachable until a later change produces one.
This is worth stating rather than discovering: change 6 can render a grid and
change 7 can mark notes, but neither has content behind it.

The engine here is exactly what such a change would need — a generator is a loop
that proposes a grid, checks uniqueness, and grades it, all of which this
provides. **A `add-puzzle-generation` item should be added to
`openspec/BACKLOG.md` between changes 5 and 6**, so the gap is tracked rather
than remembered.

## Not doing

- **No generator and no shipped pack.** Deliberate, and the consequence is above.
- **No pack downloading or top-up.** Packs install through the persistence layer
  already; fetching them needs a bucket that does not exist, and remote config
  set the precedent for leaving that to a developer action.
- **No hints and no perks.** The solver can explain a step, which is what a hint
  needs, but choosing when to offer one and what it costs is change 19.
- **No rendering, no input, no notes.** Changes 6 and 7. This change has no
  Flutter import at all.
- **No variants.** Killer and the rest are change 17, and the model here is
  classic sudoku only. Nothing is generalised in advance for rules that have not
  been designed.
- **No difficulty beyond technique.** No clue-count heuristics, no timing data,
  no adaptive difficulty — `docs/TECH_STACK.md` §4 rejects the last one outright,
  because secretly softening puzzles makes the rank meaningless.
- **No daily challenge.** Change 14 picks the puzzle; this change only makes
  puzzles knowable.
