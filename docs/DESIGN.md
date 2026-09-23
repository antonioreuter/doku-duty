# Design reference

Canonical values for colour, type, shape, motion, effects, and characters. When
code and this file disagree, this file is wrong — fix it in the same change.

Rationale lives in `docs/DECISIONS.md`. This file is the values. Mockups of all nine
screens are in `docs/pages/screens.html`.

---

## 1. Colour

Eight tokens. Six carry state, two are surfaces. Nothing else exists.

| Token | Hex | Reserved for |
|---|---|---|
| `bone` | `#F5EBD6` | Grid cells, cards |
| `sand` | `#E4D4AE` | Page background, ground shadows |
| `duskInk` | `#2E2438` | Outlines, primary text |
| `badgeGold` | `#F2B33D` | Selection, focus, reward, progress |
| `nightIndigo` | `#4A3F9E` | Settled candidate notes, candidate highlighting |
| `turquoise` | `#1B6661` | Provisional notes — nothing else, ever |
| `sunsetRed` | `#E05A2B` | Errors, duplicates, Ace |
| `cactusGreen` | `#4E9E62` | Completed rows, columns, blocks |

Derived tints, not independently meaningful:

| Token | Hex | Use |
|---|---|---|
| `goldPale` | `#FDEFC6` | Fresh-completion flash, header bars |
| `indigoPale` | `#E6DEFA` | Candidate highlight cell background |
| `redPale` | `#FBDDD6` | Duplicate cell background, speech bubble |
| `greenPale` | `#CFE0BE` | Settled completion tint |
| `inkSoft` | `#64596B` | Secondary text |
| `hairline` | `#DCCDA8` | Interior grid lines |

Depth shades, used only for solid offset shadows (§4):

| Base | Shadow |
|---|---|
| `badgeGold` | `#B47A15` |
| `sunsetRed` | `#A03A15` |
| `cactusGreen` | `#2F6E3F` |
| `nightIndigo` | `#2F2670` |
| `bone` / `sand` | `#C9B48C` |

**Rules (D-53, D-55):**

- No ninth hue. If a design needs one, it needs a different design.
- Territory themes repaint `bone`, `sand`, and props only. The six state tokens
  are fixed across every season, so the grid is never relearned.
- Text on colour uses the darkest shade of that family, never black or grey.
- **Every text pair is measured, not judged.** 4.5:1 below 18px, 3:1 at or above
  (and at or above 14px bold). Values here that failed were corrected in D-72
  rather than granted an exception. The interior `hairline` is the one deliberate
  exception: at 1.33:1 on `bone` it is not a contrast failure but the intent of
  §3 — the 3px outer contour and the 2.5px `duskInk` box dividers at 12.44:1
  carry the structure a solver actually reads.
- **Provisional notes carry an underline, not just turquoise ink** (D-73). The two
  note inks are 1.07:1 apart under deuteranopia once turquoise is dark enough to
  be legible, so hue alone cannot separate them and constraint 5 forbids trying.

| Background | Text |
|---|---|
| `badgeGold` | `#4A3405` |
| `sunsetRed` | `#3D0D06` |
| `cactusGreen` | `#0E2D17` |
| `nightIndigo` | `#F3EFFF` |

**State priority** where highlights compete (D-49): selection, then candidate
highlighting, then duplicate, then completion tint.

Completion tints are **one flat level and never additive** (D-48), and always
carry a corner mark so the state survives colourblindness and the tints-off
setting (D-50).

---

## 2. Type

| Role | Size | Weight |
|---|---|---|
| Grid value | 22 | 600 |
| Grid note | 11 | 400 |
| Screen title | 24 | 600 |
| Body | 15 | 400 |
| Label / meta | 12 | 500 |
| Character line | 15 | 400 |

**On a killer board** (D-129) the grid-note role does two more jobs, and neither
is a seventh role. The **cage sum** is the grid-note face at 8px, weight 600, in
`inkSoft`, capped to its band the way a note is capped to its slot. Notes are
inset below that band on every cell of the board, so they fall below 11px on
most phones — 8.3px on the smallest. That amends D-74 for **killer** boards
only; classic boards keep the 11px floor.

The face is **Nunito**, bundled at 400/500/600 (D-74). Rounded, with real weight
contrast. It is *not* condensed, which is the one deviation from the original
brief: no open-licensed face is rounded, condensed, and open-apertured at once,
and the aperture is what decides a sudoku face — the grid note at 11px is the
smallest and most-read glyph in the app.

The grid roles use tabular figures. A proportional `1` is narrower than the other
digits, so a column of values shifts sideways as the board fills.

Slab and tuscan western lettering is period-accurate and illegible at 12px — logo
only.

Sentence case everywhere. Dynamic type respected.

---

## 3. Shape and line

| Property | Value |
|---|---|
| Card radius | 20 |
| Button radius | 18 |
| Grid outer radius | 14 |
| Outer contour stroke | 3 |
| Interior detail stroke | 2 |
| Grid box divider | 2.5 |
| Grid cell hairline | 1 |
| Cage outline (dashed, 3 on / 2 off, inset 3 inside the cell) | 1.5 |

Thick outer contour with thinner interior lines is what reads as cartoon rather
than diagram. Uniform stroke weight is the most common tell of lifeless vector
art.

---

## 4. Polish

Correct values produce a correct app. These five techniques produce a game.

**Solid offset shadows, never blurred.** A 4px hard shadow in the depth shade of
the same hue. Every card, button, node, and the grid itself. Blur reads
corporate; solid offset reads toy.

**Pressable depth.** Buttons rest at 4–5px depth. Pressed, they translate down
4px and drop to 1px depth — 8px of total travel. This single technique is most
of why a casual game feels good to tap.

**Nothing perfectly aligned.** Cards and speech bubbles rotate 0.5° to 2°.
Perfect alignment reads machine-made.

**Overshoot.** `easeOutBack`, roughly 15% overshoot, on anything appearing.
Nothing fades in — things pop, drop, or slide from where they logically came
from.

**Texture.** Paper grain at about 4% opacity across surfaces. Flat fill is the
fastest way to look cheap.

**The exception:** depth treatment applies to interactive chrome only. It never
touches grid cells. Thick borders and shadows on nine columns destroy
readability.

---

## 5. Motion

Nothing exceeds 400ms except the two documented exceptions. Nothing blocks
input. Everything is skippable by tap (D-46).

| Event | Duration | Motion | Haptic | Sound |
|---|---|---|---|---|
| Value placed | 90ms | Cell scale 1.04 → 1.0 | Selection tick | Wood block |
| Key pressed | 90ms | Squash to 0.94 vertical, rebound | Selection tick | Wood block |
| Note added | 0ms | Instant, no transition | None | None |
| Row or column complete | 260ms | Lasso cinch (§6) | Light impact | Rising harmonica phrase |
| Block complete | 340ms | Dynamite detonation (§6) | Medium impact | Banjo roll into a thump |
| Duplicate placed | 400ms | Both digits react (§6) | Light double tap | Dry pencil scratch |
| Cascade | 520ms | Chained, see §6 | One per step | Pitch rises per step |
| Puzzle complete | 1400ms | Four beats, see §6 | Success pattern | Full cue, Biscuit's whinny |
| Fresh completion tint | 2000ms hold | `goldPale` settling to `greenPale` | None | None |
| Character enters strip | 220ms | Slides up with overshoot | None | None |

Notes trigger nothing — no particle, no sound, no haptic (D-52). A player
marking a dense board makes forty entries a minute, and any celebration attached
to that is noise within seconds.

Idles begin after 20 seconds and are always silent (D-44).

OS reduce-motion disables everything above except instant states. A separate
in-app reduce-effects setting does the same independently.

---

## 6. Effects

Particles are drawn from the world, not from a generic sparkle library.

### Row or column complete — the lasso

A rope snakes out along the unit from the cell just placed, cinches, and
gathers. Cells pop to 1.08 and settle, staggered 18ms so the eye reads
direction. Dust puffs rise behind the rope. Gold flash, then the persistent
cactus tint.

The lasso is an unmistakably western verb and it reads as *collected*, which is
exactly what completing a unit means.

### Block complete — dynamite

A plunger depresses and the block detonates outward from the placed cell.
Radial, not linear, so a block never reads as a row. Gold sparks and small
debris burst at the corners. A resolved thump rather than a rising figure.

Fireworks energy, not violence. Nothing is destroyed and nothing is aimed at
the player.

### Duplicate placed — the digits react

Both digits notice each other, in horror, for roughly half a second. The cells
wobble and take `redPale`; a small mark pops above each.

This replaces the conventional red flash (D-42). Same information, delivered as
character rather than reproach. It fires constantly, it converts the game's
sorest moment into its most charming one, and it costs one animation. It is the
single clearest expression of the product and should not be cut for schedule.

### Cascade

When one placement completes several units, effects chain at 90ms in the order
row, column, block — never simultaneous (D-47). Each step is brighter and a tone
higher. Biscuit stamps on the third.

Total 520ms. This is a **deliberate exception** to the 400ms rule: cascades are
rare, they are the best moment in ordinary play, and collapsing them into one
flash wastes three rewards. Record it as such rather than letting it look like
an oversight.

### Puzzle complete

1400ms in four beats:

| Beat | Time | What |
|---|---|---|
| 1 | 0–300ms | Wave crosses the grid from the final cell |
| 2 | 300–700ms | Biscuit walks in and stamps a hoof on the board |
| 3 | 700–1200ms | Wanted-poster scraps burst from the stamp point and drift |
| 4 | 1200–1400ms | Digits take a small bow in sequence; Ace appears, disappointed |

### Layering and budget

Effects draw above cells, below the character strip. Particles never cover an
unplaced cell — a puff that would land on ground the player still has to solve
is culled. Values and notes stay at full opacity; the effect goes behind the
glyph, never over it.

Caps: 8 dust puffs per row, 12 sparks per block, 40 scraps at puzzle completion.
60 particles maximum on screen, which holds 60fps on a mid-tier Android device.
Cascades reuse the pool rather than tripling it.

### Explicitly excluded

**No firearms, no gunfire, no weapons aimed at anything.** Two reasons, and the
second is the harder one.

Punishment as an aesthetic undoes the design. Fifty-five decisions removed
failure states; a gunshot on a wrong digit puts one back in tone even where it
does not exist in mechanics.

And it costs money. Weapons push the age rating from 4+ toward 9+ or 12+,
restrict which ad networks will serve the app, and forfeit the family audience —
a large share of the daily-sudoku market. That is a revenue effect, not a
squeamishness argument.

Dynamite survives this test because it is a celebration, not a threat.

---

## 7. Cast

Five characters. Each holds a distinct role so they can share a screen without
redundancy.

| Character | Role | Behaviour |
|---|---|---|
| **Ace** | Antagonist | Outlaw. Tallies mistakes on the jailhouse wall with weary satisfaction. Visibly disappointed when you solve cleanly. Never openly hostile, which is worse. |
| **The Sheriff** | Comic counterweight | Your grizzled boss. Absolutely certain, frequently wrong. His advice wastes a move, never a puzzle (D-39). |
| **Biscuit** | Ally | Your horse. **Never speaks.** Celebrates with a hoof stamp. Communicates through movement, ears, and sound. |
| **Number Four** | Wildcard | A digit with opinions and a bounty. Objects to placement, must be coaxed. Establishes that the numbers are residents of the board. |
| **Ruby** | Commerce | Runs the general store. Dry, unimpressed, has seen every deputy come and go. Owns the store, the pass offer, and chest openings. |

**Ruby exists to give monetisation a face.** A store and a pass offer with no
character reads as software; a conversation with someone who extends credit
reluctantly reads as the world. It is the same screen either way, and one
version is warmer.

**Biscuit is a horse, not a burro.** A horse reads as western at 30px in a way
a burro does not. The wordless-ally role is unchanged: zero localisation cost,
identical comic timing in every market, and the only uncomplicated warmth in a
cast otherwise made of obstacles (D-38).

### Scope cost, stated plainly

D-35 scoped version one at one character; D-37 raised it to four; this is five.
That is real additional art, and the art budget is the product budget (D-36). If
it will not stretch, cut in this order: Number Four, then the Sheriff. Ace,
Biscuit, and Ruby cover antagonist, ally, and commerce — the minimum that still
has a world in it.

### Rig economy

Expression lives in **eyes and brows only**. Everything else is fixed.

This is why the bandana exists: covering Ace's mouth means no mouth shapes,
which roughly halves his rig cost and makes lip-sync a non-question across
fifteen languages. Biscuit gets the same economy through ears, the Sheriff
through his moustache, Ruby through a pair of spectacles she looks over.

Design element and budget decision are the same decision.

### Presentation

The strip below the grid is a stage, not a container. The character slides up,
holds about 2.5 seconds, and leaves. It is empty most of the time — a
permanently occupied strip stops being noticed within a session.

Reactions never queue. If a trigger fires mid-reaction, the higher-emotion one
wins and the other is dropped. There is a floor of roughly 20 seconds between
reactions regardless of triggers.

| Where | Scale | Who |
|---|---|---|
| Territory map | Full body, idling or walking the trail | Biscuit, the Sheriff |
| Puzzle strip | Head and shoulders in a tilted bubble | Ace, the Sheriff |
| On the grid | Inline with the digits | Number Four only |
| Store and pass | Half body, behind a counter | Ruby |
| Completion | Half body, animated | Any |

Number Four living on the grid rather than in the strip is what makes the digit
reactions coherent — the numbers are residents of the board, not visitors.

The character strip sits **below** the grid and never covers it (D-40).

### Props

Six to eight per territory. Cacti, water troughs, a wagon, a jailhouse, a mine
head, a windmill. The character rig is shared across seasons; props are the
cheap seasonal variable, which is what makes nine territories a year affordable.

---

## 8. Grid layout

- **44pt is the floor for controls, not for grid cells** (D-84). The grid takes
  the width it is given and divides it by nine, so a cell is roughly 39pt on an
  iPhone SE and 48pt on a Pro Max. Nine 44pt cells need 396pt before any gutter,
  which most phones do not have. Every button, including every number-pad key,
  still holds the 44pt minimum
- Number pad is **five columns**, not nine. Nine keys in a row cannot carry the
  depth treatment and are worse for thumbs regardless.
- Notes in a fixed 3×3 arrangement: 1 top-left, 5 centre, 9 bottom-right (D-10)
- Adding or removing a candidate never moves the others
- **Settled notes** are `nightIndigo` with no rule; **provisional notes** are
  `turquoise` *and* underlined — a 1px rule 1.5px below the baseline (D-73). The
  rule sits inside the note's own third of the cell, so the digit keeps the slot
  it would occupy either way and nothing reflows
- No banner ad may occupy the same screen as a grid (D-25)

---

## 9. Screens

| Screen | Purpose |
|---|---|
| Territory map | Session spine. Trail, node states, season timer, streak |
| Puzzle | Grid, pad, notes toggle, erase, hint, character strip |
| Notes | Positional candidates, two inks, highlighting |
| Node complete | Celebration, reward, explicit continue tap, then ad if due |
| Deputy Badge | Ruby presents benefits, plans, trial |
| Cabinet | Wanted-poster wall, daily calendar, per-technique stats |
| Cast | Reference sheet |
| Effects | Lasso, dynamite, digit reactions |
| Palette | Token reference |

Mockups in `docs/pages/screens.html`. They show layout, hierarchy, state, and the decision
behind each choice — not final art. Character drawings there are placeholders
indicating silhouette, proportion, and rig economy only. `docs/ART-BRIEF.md` is what
goes to the illustrator.