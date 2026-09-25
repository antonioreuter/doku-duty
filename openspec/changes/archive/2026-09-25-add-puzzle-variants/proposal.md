# add-puzzle-variants

## Why

Milestone 2 has one item left. The six **variant node**s of every **season**
have been typed since `add-season-map` and play classic boards, so the rule twist
`docs/SPEC.md` §4 names as a **season**'s most under-used content lever does not
exist. D-35 promises one variant beyond classic for v1. D-34 promises a
standalone killer app at launch +6 months, which will want this engine.

## What changes

- **Killer** is the variant: a **variant node** opens a board of **cage**s, each
  with a **cage sum**, and no digit repeats in a **cage**. It is compiled in for
  every **season**. **New decision, D-127.**
- Killer is graded on the **same rank ladder**. Two techniques are added:
  **cage combination** at Greenhorn and **the 45 rule** at Sheriff. Each has a
  **lesson**. A killer solve counts toward **rank** (D-102) and **technique
  unlock**s (D-104) exactly as a classic one does. **New decision, D-128.**
- **Variant node**s only. **Free play** and the **daily challenge** stay
  classic, so neither may ever be served a killer board (D-127).
- Every **cage** is outlined in `duskInk` with a dashed stroke. Its sum sits
  at 8px top-left of the **cage**'s first cell. On a killer board every cell's
  note grid is inset below the sum band, so slot positions stay identical across
  the board. Notes on a killer board are therefore smaller than D-74's 11px:
  8.3px on the smallest phone, 10.3px at 375pt. **New decision, D-129,
  amending D-74 for killer boards only.**
- A **cage** is not a **unit**. On a killer board a cell's **cage** mates join
  its **peer**s for **auto-cleanup**, **auto-notes**, duplicates and the selection
  highlight. No **completion tint** or **cascade** fires for a **cage**.
  **New decision, D-130.**
- The shipped **pack** gains killer puzzles at all six **rank**s, because a
  published **season** may put a **variant node** at any **rank**.
- Glossary: **killer**, **cage**, **cage sum**.

## Constraints

**Capabilities:** `puzzle-engine`, `grid-input`, `notes`, `season-map`,
`persistence`, `technique-tutorials`, `design-system`

**Constraint 3 — notes never move.** This is the one this change bends closest
to. The sum label takes the corner slot 1 sits in, so the note grid is inset *on
every cell of a killer board*. Slot order is untouched and no candidate moves
when another is added or removed. **The cost is size, not order.** It was
measured before any engine work. A cell is 32.9px on the smallest phone (D-84),
where classic notes already sit at their 10.96px slot. No inset fits at 11px, so
the developer chose smaller notes on killer boards only over moving the sums out
of the grid (D-129, amending D-74 for killer boards). Classic boards are
untouched.

**Constraint 4 — no ninth hue.** Outlines and sums use `duskInk` and its
`inkSoft` tint, the tokens DESIGN.md already gives to outlines and secondary
text. The note inks, `nightIndigo` and `turquoise`, stay out of the **cage**
layer. A dashed stroke weight is a new `DokuStroke` entry, not a colour.

**Constraint 5 — colour is never the sole signal.** A **cage** is carried by its
outline and its number, never by a fill.

**Constraint 8 — one solution, logic alone.** Every killer board is verified
unique by an exhaustive check that knows cages, independently of the technique
solver. The board is also graded solvable by logic at its **rank**, and the
shipped-pack audit re-grades it the way it re-grades classic ones.

**Constraints 2 and 9.** A **cage** layer is drawn with every repaint, so the
100ms and maximum-note-density latency tests are re-run on a killer board. Note
writes are unchanged.

## Technical notes

**Grid performance:** It adds a dashed path per **cage**, which is up to about
30 paths. These are cached per puzzle rather than rebuilt per frame, and are
measured by the existing latency tests on a killer fixture.

**Offline, cold start, app kill:**
- Fully offline. Killer puzzles ship in the bundled **pack**, as **pack**
  version 2.
- The `puzzles` table gains a nullable `cages` column, moving the schema from
  v7 to v8, and save state is unchanged because it keys by puzzle id. An
  installed v1 **pack** is upgraded by the existing version check.
- A classic board has null **cage**s and renders exactly as today; the grid
  goldens prove it.

**New dependency:** None.

## Not doing

- **No second variant.** Jigsaw, thermo and sandwich stay in `docs/SPEC.md`'s
  list. The backlog's "One variant, properly. Not four."
- **No rule key in the season document.** With one variant there is nothing to
  choose. `PUBLISHING.md` gains a sentence saying so, and a key arrives with the
  second variant.
- **No killer in free play or the daily.** No toggle, no schedule field.
- **No cage completion effect.** A finished **cage** earns no tint, mark or
  haptic, because it is not a **unit**.
- **No further killer techniques.** Cage splitting, innies/outies beyond the 45
  rule, and sum-pair tables are for the standalone app (D-34).
- **No server top-up.** It does not exist for classic **pack**s either.
