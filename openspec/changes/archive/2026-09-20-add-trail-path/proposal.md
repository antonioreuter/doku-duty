# add-trail-path

## Why

`docs/pages/screens.html` Screen 01 specifies "a winding trail linking nodes",
and the **trail** does not link them — 42 markers alternate left and right with
nothing drawn between, so the eye reads a scattered list rather than a path.
`add-season-map` considered this and concluded that alternating the alignment
"is what makes it a path rather than a list", deferring the rest to artwork; the
alternation supplies the *shape* of winding but not the *linking*, and running
the built app is what showed the difference. The connector is geometry, not
artwork, so it is not `add-running-gags`' business.

## What changes

- A continuous line is drawn along the **trail**, joining each **node** to the
  one before it, following the alternating left-right rhythm already in place.
- The line runs behind the **node** markers and behind nothing else; it never
  overlaps a marker, a label, or the header.
- The line is uniform end to end. It carries no state: a walked stretch of
  **trail** looks exactly like an unwalked one.
- The line is present on the first frame, before progress has been read, because
  it depends on nothing but the **season**'s node count.
- The `season-map` spec gains the requirement, which it has never carried.

## Constraints

**Capabilities:** `season-map`

**Constraint 4 — one colour, one job.** The line takes `inkSoft`, the derived
tint of `duskInk` — so the markers are drawn in primary ink and the connector in
secondary ink, which is the relationship the drawing wants. Derived tints are
explicitly not a route around the count of eight, so this adds no hue. It is
deliberately *not* given `badgeGold` or `cactusGreen`: both have documented jobs
(progress, completion), and a progress-coloured path would be a second job for
one of them.

`hairline` was the obvious first choice and is **wrong**: it is a tint of
`sand`, the page background the trail sits on, and measures **1.07:1** against
it — invisible. It reads correctly as an interior grid line only because there
it sits on `bone`. `inkSoft` measures 4.50:1 on `sand`, against `duskInk`'s
10.05:1 for the marker contours.

**Constraint 5 — colour is never the sole signal.** Sidestepped rather than
satisfied, because the line signals nothing. A stateful path would be a fourth
encoding of walked-ness, which the marker already carries three ways — colour,
glyph, and size — under "Node state carries a signal that is not colour". Adding
a fourth would oblige this change to carry a non-colour channel too, for
information that is already unambiguous. **New decision, D-113:** the trail path
is decoration and carries no state.

**Constraint 2 — latency and effects.** The line is drawn per row in a `CustomPainter`
with no state to read and no animation. It adds one painter per row to a list
that already lays out 42 rows.

**Accessibility.** The line is decorative, so it is excluded from semantics
entirely — a screen reader must not announce it, and the existing per-node
labels stay the only route to state.

## Technical notes

**Grid performance:** Not touched. This is the **trail**, not the grid; no
in-puzzle frame is affected.

**Offline, cold start, app kill:** No change. Full offline play is mandatory
on this project, and the line derives from the **season**, which is synchronous
and compiled in — so it paints on the first frame alongside the markers and
before the database is opened. The test asserting nothing reads the database on
the path to that frame must still pass.

**New dependency:** None. `CustomPainter` is in the framework.

## Not doing

- **No props or characters.** The cactus, the wagon, the water trough and
  Biscuit that the mockup draws alongside the trail are `add-running-gags`
  (change 22) and need art that does not exist. This change draws a line.
- **No walked/unwalked distinction**, per D-113 above.
- **No change to marker appearance, size, or tap behaviour.** One caveat on
  spacing, added during implementation rather than planned: every marker is now
  laid out in a uniform 60px anchor box, so a 44px circle sits ~6px further
  from the edge than it did. The **current node** at 60px does not move at all.
  This is what lets the line meet every marker at the same inset at any text
  scale — without it the marker's width is the width of "Node 42" and the line
  drifts off the circle at 3x and beyond.
- **No scroll-position or camera work** — no auto-scroll to the **current
  node**, which is a separate question this change deliberately leaves open.
- **No season-themed path colour.** A **season** repaints surfaces and props
  (D-55); whether a future territory repaints the line is left to whichever
  change first ships a second **season**.
