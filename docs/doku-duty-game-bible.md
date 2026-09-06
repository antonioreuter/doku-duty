# Doku Duty — Game Bible

> You are a frontier deputy who files numbers for a living. Solve sudoku, rise
> from Greenhorn to Legend, and try to stop the outlaw Ace from tallying your
> mistakes on the jailhouse wall.

The mechanism, rules, objectives, and narrative in one place. Compiled from
`docs/IDEA.md`, `docs/SPEC.md`, `docs/DESIGN.md`, and `docs/DECISIONS.md`. Where those disagree,
`docs/DESIGN.md` is authoritative for colour and motion values.

A rendered version of this document lives at `docs/pages/doku-duty-game-bible.html`.

---

## 1. Narrative

The frontier. A territory of dusty towns where the law is administered through
paperwork and everyone takes numbers extremely seriously. Deadpan bureaucracy is
the **foundation**, not the joke — on its own it reads as restrained rather than
funny, so the absurdity escalates visually through a cast who react to each
other.

Sudoku puzzles are mathematically identical in every app on the store. There is
no puzzle-quality advantage available to win, and every serious competitor is
calm, minimal, and blue. Nobody owns comedy in this category. The art direction
and comedy writing *are* the product; the sudoku engine is table stakes.

### 1.1 The cast

Four characters at launch (D-58, superseding D-37). Each occupies a distinct
comic role so they can be combined without overlapping.

| Character | Role | Behaviour |
|---|---|---|
| **The Sheriff** | Your boss | Grizzled. Dispenses dry, grudging approval and very little of it. Employs you; does not admire you. |
| **Ace** | Antagonist | The outlaw. Tallies your mistakes on the jailhouse wall with weary satisfaction, and cheats at numbers. Never openly hostile, which is worse. |
| **Biscuit** | Ally | A burro. Wordless, loyal, visibly delighted by your successes. Communicates entirely through movement and sound. |
| **Number Four** | Wildcard | A digit with opinions and a bounty on its head. Occasionally objects to placement and must be coaxed. Establishes that the numbers are people. |

**Biscuit never speaks (D-59).** This is a costed decision: zero localisation
spend across fifteen-plus languages, identical comic timing in every market, and
wordless characters reliably become the most-loved in a cast. Biscuit is the only
warmth in a cast otherwise made of obstacles.

**No character gives deliberately wrong advice (D-60).** A character may be
unhelpful in tone, never in content — hints are correct or absent.

### 1.2 Reaction triggers

Reactions fire through animation and sound, with any spoken line under six words
(D-02). The character strip sits **below** the grid and never covers it — the
grid is never obscured for a joke (D-40).

| Trigger | Character | Tone |
|---|---|---|
| First mistake in a puzzle | Ace | Dry, chalking it up |
| Third mistake | Ace | Almost pleased |
| Long pause with no input | Sheriff | Says nothing, at length |
| Cell marked with 7+ candidates | Ace | Remark on your confidence |
| Provisional notes cleared | Biscuit | Sympathetic shrug |
| Row or unit completed | Biscuit | Delighted braying |
| Puzzle solved with no mistakes | Ace | Openly disappointed |
| Technique unlocked | Sheriff | Grudging approval |
| Boss defeated | Ace | Swears revenge, formally |
| Returning after days away | Sheriff | Pointed remark about attendance |

### 1.3 Running gags

These matter more than the character art, because they fire constantly and cost
little per season.

- **The jailhouse tally.** Errors accumulate as scratch marks on Ace's wall,
  visible on the map and growing across the season. Solve with no mistakes and
  Biscuit kicks the wall, knocking marks off with small ceremony. Purely
  cosmetic — it never affects difficulty, rewards, or progression (D-61).
- **Digits react to each other.** Place a 7 where an existing 7 can see it and
  both notice, in horror, for roughly half a second. This *is* the duplicate
  feedback, replacing the conventional red flash (D-42).
- **Telegrams as loading screens.** Genuine-looking notices — a stolen ledger,
  mandatory numeracy retraining, a stern reminder about hitching posts. One line
  each, rotating from a pool of several hundred (D-62).
- **The wanted-poster wall.** The cabinet is a wall of posters of the player's
  own deputy, one per season, in progressively more deranged outfits as rank
  rises.
- **Idle animations.** Left open, characters get bored. The Sheriff adjusts his
  hat, Biscuit naps, Ace recounts the tally. Begin after 20 seconds, always
  silent (D-44).
- **Ad breaks in character.** The Sheriff announces the interruption as a
  mandatory territorial sponsorship obligation, visibly resenting it.

### 1.4 The deputy avatar

The player is a deputy, and the deputy is customisable: hats, moustaches, badges,
kerchiefs, spectacles, regrettable waistcoats. Flat 2D layers on a single rig.

This is the primary cosmetics business, ahead of grid themes (D-63). Players see
their own deputy constantly — on the map, in the cabinet, in every wanted-poster
portrait — whereas a grid theme is a background they stop noticing within a week.

---

## 2. Rules

Standard 9×9. Every puzzle has exactly one solution and is solvable by logic
alone at every rank, with no guess-and-check required (D-08). Input targets are
a minimum of 44pt, input response is under 100ms, and no animation may block the
next tap.

### 2.1 A cell holds a value or notes, never both

**Values** are the player's committed answers. Placing a value clears any notes
in that cell and triggers auto-cleanup.

**Notes** are candidate digits — the working out. Up to nine per cell (D-09).

Notes are **positional**: each digit occupies a fixed slot in a 3×3 arrangement
inside the cell. Adding or removing a candidate never moves the others (D-10).
This lets players scan by position rather than by reading, which is what makes a
densely marked board usable.

```
 ┌───┬───┬───┐
 │ 1 │ 2 │ 3 │     1 is always top-left
 ├───┼───┼───┤     5 is always centre
 │ 4 │ 5 │ 6 │     9 is always bottom-right
 ├───┼───┼───┤
 │ 7 │ 8 │ 9 │
 └───┴───┴───┘
```

### 2.2 Two note inks

| Ink | Colour | Meaning |
|---|---|---|
| **Settled note** | `nightIndigo` | A candidate the player has derived |
| **Provisional note** | `turquoise` | A hypothesis under test, for chain reasoning at the top tiers |

A single control clears all provisional notes, so a failed line of reasoning can
be abandoned in one tap without disturbing settled work (D-11).

> **Note:** `docs/SPEC.md` §3.2 still describes these as "blue" and "violet", which
> predates the palette rename in D-65. `docs/DESIGN.md` and `docs/SPEC.md` §9.8 are
> correct: indigo and turquoise.

### 2.3 Note behaviours

- **Auto-cleanup, always on (D-12).** Placing a value removes that candidate
  from every cell in its row, column, and block. Without it, notes go stale
  within twenty moves and players stop trusting them.
- **Candidate highlighting (D-13).** Tapping a digit on the pad highlights every
  cell holding it as a note. This is how pointing pairs and X-wings become
  visible rather than deduced by squinting.
- **Auto-notes.** Fills every empty cell with all its legal candidates in one
  action. Free during the technique tutorials, then metered — one charge per
  rewarded video, unlimited for subscribers.
- **Notes never count as mistakes (D-14)**, even when wrong.
- **Undo** covers note actions at full depth, including auto-notes and
  auto-cleanup as single reversible operations.

### 2.4 Input model

- A persistent notes toggle, not a modifier held per entry. Players work in
  note-heavy bursts.
- Long-press a pad digit for the opposite mode, so power users never leave the
  grid.
- Number-first input (lock a digit, then tap cells) available as a setting.

### 2.5 Mistakes and the timer

Auto-check is **off by default** and there is **no mistake limit by default**
(D-04). Mistakes are recorded silently for statistics. Overwriting an
already-correct cell never counts as a mistake in any mode (D-05).

**Strict mode** is an opt-in setting: errors flag immediately, three mistakes end
the attempt. It exists for players who want stakes and is never enabled without
a deliberate choice.

The timer is display-only, hideable, and never fails a puzzle (D-06). It feeds
personal bests and tournament scoring.

---

## 3. Objectives

### 3.1 Six ranks, graded by technique

Difficulty is the hardest technique required to solve the puzzle without guessing
(D-07, named in D-57). **Clue count is not used for grading.** Progression feels
like getting smarter rather than grinding.

| Rank | Techniques required | Target solve |
|---|---|---|
| Greenhorn | Full house, naked single | 2–4 min |
| Deputy | + hidden single | 4–7 min |
| Sheriff | + naked pair, pointing pair | 7–12 min |
| Marshal | + box-line reduction, naked triple | 12–20 min |
| Ranger | + hidden pair, X-wing | 20–35 min |
| Legend | + swordfish, XY-wing, simple chains | 35 min+ |

Each tier introduces its technique with a short interactive tutorial the first
time the player meets a puzzle requiring it. Tutorials are skippable and
replayable from the cabinet.

Notes become effectively mandatory from Marshal upward, so **the notes tutorial
must land no later than Sheriff rank.**

### 3.2 Three progression layers

Three independent layers, on three different clocks (D-17). The independence is
the point: missing a week damages none of them permanently.

| Layer | Clock | Holds |
|---|---|---|
| **Permanent** — the cabinet | Never resets | Rank and technique unlocks, every trophy and medal ever earned including from expired seasons, lifetime statistics |
| **Seasonal** — the map | 6 weeks, then rotates out | 42 nodes across one territory, with its own palette, character, ambient audio, and rule variant |
| **Daily** — challenge and streak | Resets at midnight local | A fresh puzzle identical for all players, a month-grid calendar, a streak counter |

**The map creates urgency. The cabinet creates sunk cost.**

Unearned seasonal trophies are shown as *unfiled* rather than hidden (D-21).

#### Season node composition

| Type | Count | Notes |
|---|---|---|
| Puzzle | 30 | Difficulty ramps across tiers |
| Variant | 6 | The season's rule twist (killer, thermo, sandwich, jigsaw) |
| Chest | 4 | At 25 / 50 / 75 / 100% |
| Boss | 2 | Midpoint and finale; unique trophy to the cabinet |

Reward pacing is front-loaded — something meaningful roughly every other node
through node 8, stretching through the middle, tightening for the final five
(D-19). Nodes never expire within a season, and missing days does not damage
progress (D-20). Boss nodes have unlimited free retries (D-22).

Because each season introduces a **rule variant** rather than only a palette, the
map has no content wall. Variants are the most under-exploited content lever in
the category.

#### Daily streak

One streak freeze is granted free each week and applied automatically when a day
is missed (D-20). Subscribers get two additional. A full month unlocks a cabinet
trophy. **The daily challenge carries no interstitial ad, ever.**

### 3.3 Stamps and perks

The non-punitive rule removed lives, energy, timers, and failure states — and
with them every source of tension the category normally relies on. **Stamps**
restore a decision without putting anything at risk: *is this puzzle worth a
Stamp?*

Stamps are earned only through play (D-66). They cannot be purchased at any
price — no coin store, no bundles.

| Earned for | Stamps |
|---|---|
| Completing the daily challenge | 2 |
| Solving a puzzle with no mistakes | 3 |
| Reaching a 7-day streak milestone | 10 |
| Opening a chest node | 12 |
| Defeating a boss node | 20 |

**Hints are metered (D-67).** Every puzzle includes one free hint; beyond that a
hint costs Stamps or a rewarded video. Subscribers are unlimited.

| Perk | Stamps | What it does |
|---|---|---|
| Hint | 3 | Names the next logical step and the technique that produces it |
| Auto-notes charge | 4 | One auto-notes fill |
| Reveal a cell | 5 | Fills one chosen cell with its correct value |
| Scan a unit | 8 | Marks which candidates in one chosen unit are eliminable |
| Digit sweep | 12 | Reveals every remaining cell where one chosen digit belongs |
| Solve a row | 15 | Completes one chosen row |

**Running out of Stamps never blocks play.** No puzzle becomes unsolvable, no
node locks, no attempt ends. A zero-Stamp player keeps the full grid, the
complete notes system, one hint per puzzle, and rewarded video if they want more.
Scarcity in the *assists* is legitimate; scarcity in *play* is what the ten
constraints forbid.

**Digit sweep is not candidate highlighting.** Highlighting (D-13) is free and
always on, showing where a digit is already marked or placed. Digit sweep reveals
where it *belongs*. The free feature is never metered.

---

## 4. Mechanism — feel

This is where clones fail, and it is engineering rather than concept. It cannot
be added at the end.

### 4.1 Baseline

- Sub-100ms input response; no animation ever blocks the next tap (D-46)
- Notes appear instantly, with no transition
- A sound palette that stays pleasant on the four-hundredth note of a session
- Distinct haptic weight for placing a value, completing a row, completing a block

### 4.2 Motion, haptic, and sound per event

Nothing exceeds 400ms except the two documented exceptions. Everything is
skippable by tap. OS reduce-motion disables all of it automatically, and a
separate in-app reduce-effects setting does the same independently.

| Event | Duration | Motion | Haptic | Sound |
|---|---|---|---|---|
| Value placed | 90ms | Cell scale 1.04 → 1.0 | Selection tick | Wood block |
| Key pressed | 90ms | Squash to 0.94 vertical, rebound | Selection tick | Wood block |
| **Note added** | **0ms** | Instant, no transition | **None** | **None** |
| Row or column complete | 260ms | Lasso cinch | Light impact | Rising harmonica phrase |
| Block complete | 340ms | Dynamite detonation | Medium impact | Banjo roll into a thump |
| Duplicate placed | 400ms | Both digits react | Light double tap | Dry pencil scratch |
| Cascade | 520ms | Chained, never stacked | One per step | Pitch rises per step |
| Puzzle complete | 1400ms | Four beats | Success pattern | Full cue, Biscuit's whinny |
| Fresh completion tint | 2000ms hold | `goldPale` settling to `greenPale` | None | None |
| Character enters strip | 220ms | Slides up with overshoot | None | None |

**Notes trigger nothing (D-52).** No particle, no sound, no haptic. A player
marking a dense board makes forty entries a minute, and any celebration attached
to that is noise within seconds. Notes are thinking, and thinking should be quiet.

### 4.3 The effects, drawn from the world

Particles come from the frontier, not a generic sparkle library.

- **Row or column — the lasso.** A rope snakes out along the unit from the cell
  just placed, cinches, and gathers. Cells pop to 1.08 and settle, staggered 18ms
  so the eye reads direction. Dust puffs rise behind the rope.
- **Block — dynamite.** A plunger depresses and the block detonates outward from
  the placed cell. Radial, not linear, so a block never reads as a row. Fireworks
  energy, not violence.
- **Duplicate — the digits react.** Both digits notice each other, in horror, for
  roughly half a second. Cells wobble and take `redPale`. This converts the
  game's sorest moment into its most charming one and costs one animation. It is
  the single clearest expression of the product and should not be cut for
  schedule.

### 4.4 The cascade

When one placement completes two or more units at once, effects **chain** at 90ms
offsets in the order row → column → block, never simultaneously (D-47). Each step
is brighter and a tone higher. Biscuit stamps on the third.

| Step | Starts | Duration | Ends |
|---|---|---|---|
| Row | 0ms | 260ms | 260ms |
| Column | 90ms | 260ms | 350ms |
| Block | 180ms | 340ms | **520ms** |

520ms total is a **deliberate exception** to the 400ms rule. Cascades are rare,
they are the best moment in ordinary play, and collapsing them into one flash
wastes three rewards — the player sees one loud flash instead of three escalating
rewards. Record it as an exception rather than letting it look like an oversight.

### 4.5 Puzzle completion

1400ms in four beats:

| Beat | Time | What |
|---|---|---|
| 1 | 0–300ms | Wave crosses the grid from the final cell |
| 2 | 300–700ms | Biscuit walks in and stamps a hoof on the board |
| 3 | 700–1200ms | Wanted-poster scraps burst from the stamp point and drift |
| 4 | 1200–1400ms | Digits take a small bow in sequence; Ace appears, disappointed |

### 4.6 Completion tint

Completed rows, columns, and blocks take a calm tint that persists for the rest
of the puzzle.

- **One flat tint level, never additive (D-48).** A cell in a completed row *and*
  column *and* block looks identical to a cell in just one. Stacking tints turns
  a nearly finished grid into mud, which is exactly when the board most needs to
  stay readable.
- **A freshly completed unit holds a warmer highlight for about two seconds**,
  then settles. The celebration and the record are different states.
- **Priority order** where highlights compete: selected cell, then candidate
  highlighting, then completion tint (D-49). The player's current focus always
  wins.
- **A corner mark accompanies the tint (D-50)**, so completion is never signalled
  by colour alone.
- Tints can be turned off in settings.

### 4.7 Particle budget

Effects draw above cells, below the character strip. Particles never cover an
unplaced cell — a puff that would land on ground the player still has to solve is
culled. Values and notes stay at full opacity; the effect goes behind the glyph,
never over it.

Caps: 8 dust puffs per row, 12 sparks per block, 40 scraps at puzzle completion.
**60 particles maximum on screen**, which holds 60fps on a mid-tier Android
device. Cascades reuse the pool rather than tripling it.

---

## 5. Boundaries — what the game refuses to do

### 5.1 No firearms, no gunfire, no weapons aimed at anything

Two reasons, and the second is the harder one.

Punishment as an aesthetic undoes the design: sixty-five decisions removed
failure states, and a gunshot on a wrong digit puts one back in tone even where
it does not exist in mechanics.

And it costs money. Weapons push the age rating from 4+ toward 9+ or 12+,
restrict which ad networks will serve the app, and forfeit the family audience —
a large share of the daily-sudoku market. That is a revenue effect, not a
squeamishness argument.

Dynamite survives this test because it is a celebration, not a threat.

### 5.2 No ad ever interrupts a grid in progress

Interstitials fire only after a node completes, after the celebration, and after
an explicit tap. Capped at one per three nodes, six per session, ninety seconds
apart. Never on a chest, a boss, or the daily. No banner is ever visible while a
grid is on screen. Ad removal is absolute and verified by automated test on every
release — a release blocker, not a support ticket category.

### 5.3 No purchasable currency and no gacha

Everything in the core loop is free: all puzzles, all six ranks, the full season
map, the daily challenge, the complete notes system, offline play.

**Stamps** (§3.3) are earned in play and spent on assists, and money can never
reach them — there is no coin store and no bundle. D-23's argument was against a
*purchase* layer; D-66 refines it rather than reversing it. If Stamps ever become
purchasable, this boundary falls.

Monetisation is the **Deputy Badge** subscription ($4.99/month or $29.99/year
with a seven-day trial), a one-time ad removal at $9.99, and a standalone season
pass at $4.99 offered at node 5 rather than on first open. Rewarded video is
opt-in and carries the volume.

---

## 6. Scope and risk

**Version one:** one season, one variant beyond classic, all six ranks, the
complete notes system, the daily loop, the trophy cabinet, the full cast, and the
full monetisation stack.

The notes system and the technique grading must be excellent at launch, because
everything else is built on them and **neither can be retrofitted.**

**The main risk:** if the character animation and comedy writing are merely
adequate, this is a competent sudoku app with no reason to exist. Budget the art
before the engineering.
