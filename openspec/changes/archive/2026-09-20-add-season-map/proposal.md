# add-season-map

## Why

`rank_picker_screen.dart` is scaffolding, and it says so in its own doc comment:
a player is meant to reach a puzzle through a node on a territory map, not a
list of six difficulty tiers. Change 12 landed the **rank** rules the map needs
and left the mark's presentation sitting on that placeholder. The map is also
the spine every later change hangs from — chests want somewhere to sit (18),
bosses want somewhere to award from (16), and the variant needs nodes to occupy
(17) — so nothing after Milestone 2 starts until it exists.

## What changes

- A **season** is 42 **node**s over six weeks: 30 puzzle, 6 variant, 4 chest,
  2 boss (D-18). Chests sit at 25/50/75/100%, bosses at the midpoint and the
  finale.
- The **trail** screen becomes the spine: a winding path of nodes, season name
  and days remaining, progress count, and bottom navigation.
- **Free play** survives alongside it (D-111). `rank_picker_screen.dart` is
  promoted from scaffolding to a real screen behind the nav rather than
  deleted, because it is the only thing keeping D-103's guarantee true: on a
  sequential trail a Legend puzzle is forty nodes away, and a trail-only route
  would re-introduce exactly the gate D-103 refused. The **rank** mark stays
  where change 12 left it and is carried onto the trail as well, since a node
  can name a **rank** above the player's.
- A node carries one of three states — completed, current, not yet reached.
  The current node is drawn larger as well as differently coloured, so state
  survives constraint 5. A chest or boss node stays identifiable as one in
  every state, so the player can see where the season's rewards fall.
- Nodes are walked in order: completing node N makes node N+1 current (D-108).
  Reaching forward is the only thing the order withholds, and it withholds it
  from a player who has not walked there yet — it is not D-103's lock, which
  refused to withhold something already earned.
- Nodes never expire, and missing days costs a season nothing (D-20).
- A boss node retries without limit and without cost (D-22).
- A season is **data**: a document under `remote-config` with season 1 compiled
  in as the fallback, so a season 2 is a publish and not a release.
- A node names a **rank**, not a puzzle id (D-110). The puzzle is resolved from
  the pack at open time, which is why the map survives a pack top-up.
- When a season's six weeks elapse with no successor defined, the current
  season holds open and playable; the countdown stops rather than the map
  closing (D-109).
- `persistence` gains season state: which season is current, which nodes are
  completed, and the boss attempt count. Lifetime statistics are untouched by
  rotation, as they already are (D-17).

## Constraints

**Capabilities:** `season-map`

**1 — non-punitive.** The load-bearing one, and the reason **free play** stays.
Node order is not a failure state:
nothing is lost, nothing expires, no attempt ends, and a boss retries forever
(D-22). The word *locked* does not appear in any string — a node not yet walked
to reads as *not yet reached*, following the phrasing discipline D-104 set for
**technique unlock**s. D-108 records why the order is not the lock D-103 refused.

**4 and 5 — colour.** Node states take their colour from the existing eight
tokens and add no ninth. Season themes may repaint the trail's surfaces and
props, never a state colour (D-55). Every node state carries a non-colour
signal: the current node is larger, completed nodes carry a check, a not-yet-
reached node carries the mockup's padlock glyph and a label.

**6 — ads.** No ad code lands here, but the map is where interstitials become
possible, so this change ships the "node completed" signal `add-ads-integration`
counts against rather than leaving it to invent one. Chest, boss, and daily
nodes are already compiled in as never-eligible (`PUBLISHING.md`).

**Offline (not one of the ten, but mandatory).** Season 1 is compiled in. A
device that has never been online plays the full 42-node season.

## Technical notes

**Grid performance:** The trail is not a grid and shares no paint path with one.
The constraint it must respect is cold start: the map is the first screen, and
the existing shell test asserts nothing reads the database on the path to the
first frame. The trail follows the **rank** picker's pattern — structure paints
immediately from the season definition, node completion state arrives after the
first frame.

**Offline, cold start, app kill:** Fully offline, as above. Node completion is
written in the same transaction as the **solve record** so a kill between the
two is impossible — a node cannot read completed over a puzzle with no record,
or the reverse. D-105 applies unchanged: whatever the trail caches about which
node is current is invalidated by the write, not left to expire.

**New dependency:** None. The season document rides the `remote-config` fetch
that already exists, and the state rides the Drift schema that already exists.

## Not doing

- **No Stamps.** A chest node completes and is recorded as completed; it grants
  no currency, because the balance is change 18 and D-66 wants exactly one
  place that can mint one. The seam is named and specified, not silent.
- **No trophies.** A boss node completes and files nothing; the cabinet is
  change 16.
- **No variant rules.** A variant node is typed as one and plays a classic
  puzzle until change 17 gives it a rule. The node's type is real so that 17
  has somewhere to land and D-19's pacing can be judged now.
- **No season pass track.** Change 27, and it is gated on purchases.
- **No daily challenge and no streak**, though the mockup's header shows both —
  that is change 14, and the trail leaves the space for it.
- **No season 2 content.** The mechanism is built and exercised by a test
  fixture; authoring a second territory is content work, not this change.
- **No characters on the trail.** Biscuit walking the path, the jailhouse tally,
  and the wanted posters are changes 20 and 22.
- **No banner ad**, though D-25 permits one on this screen. Change 24.
- **No redesign of free play.** It keeps the layout and behaviour change 12
  shipped; all that changes is that it is reached from the nav and is no longer
  described as scaffolding.
