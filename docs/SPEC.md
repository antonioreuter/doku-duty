# Doku Duty — product specification

Version 0.1 · draft for review

Companion documents: `docs/DECISIONS.md` (every decision and its rationale, numbered D-01 onward), `docs/pages/screens.html` (visual mockups of the six core screens).

---

## 1. Summary

A free-to-play sudoku game for iOS and Android, set on a comedic frontier where the law is administered through paperwork. Players rise through six frontier ranks, each defined by a real solving technique (D-56, D-57). A seasonal map rotates every six weeks; a permanent trophy cabinet holds everything earned.

The game is deliberately non-punitive. There are no lives, no energy, no failure states, and no timers that can beat you. It monetises through opt-in rewarded video, a modest interstitial placement, a season pass, and a subscription.

**Positioning.** Every serious competitor in this category is calm, minimal, and blue. The puzzles are mathematically identical everywhere, so there is no puzzle-quality advantage to win. Doku Duty competes on personality and on respect for the player's time.

---

## 2. Audience

| Segment | Share of players | What they want | What converts them |
|---|---|---|---|
| Casual daily | ~65% | Five relaxing minutes, no stress | Ad removal, cosmetics |
| Improver | ~25% | To get measurably better | Technique tiers, per-technique stats |
| Serious solver | ~10% | Notes that work, honest difficulty | Subscription, provisional notes |

The serious solver is the smallest segment and the highest value. They subscribe, they review, and they recommend. Most of the notes system exists for them, and it costs the other segments nothing.

---

## 3. Core gameplay

### 3.1 The grid

Standard 9×9. Every puzzle has exactly one solution and is solvable by logic alone, with no guess-and-check required at any tier (D-08).

Input targets are a minimum of 44pt. Input response must be under 100ms, and no animation may block the next tap.

### 3.2 Values and notes

A cell holds **either** a value **or** notes, never both.

**Values** are the player's committed answers. Placing a value clears any notes in that cell and triggers auto-cleanup (below).

**Notes** are candidate digits — the player's working out. Up to nine per cell (D-09).

Notes are **positional**: each digit occupies a fixed slot in a 3×3 arrangement inside the cell. 1 is always top-left, 5 always centre, 9 always bottom-right. Adding or removing a candidate never moves the others (D-10). This lets players scan by position rather than by reading, which is what makes a densely marked board usable.

There are **two note inks** (D-11):

- **Settled** (blue) — candidates the player has derived
- **Provisional** (violet) — a hypothesis under test, for chain reasoning at the top tiers

A single control clears all provisional notes, so a failed line of reasoning can be abandoned in one tap without disturbing settled work.

### 3.3 Note behaviours

**Auto-cleanup.** Placing a value removes that candidate from every cell in its row, column, and box. Always on (D-12). Without it, notes go stale within twenty moves and players stop trusting them.

**Candidate highlighting.** Tapping a digit on the pad highlights every cell holding it as a note (D-13). This is how pointing pairs and X-wings become visible rather than deduced by squinting.

**Auto-notes.** Fills every empty cell with all its legal candidates in one action. Free during the technique tutorials, then metered — one charge per rewarded video, unlimited for subscribers.

**Notes never count as mistakes**, even when wrong (D-14).

**Undo** covers note actions at full depth, including auto-notes and auto-cleanup as single reversible operations.

### 3.4 Input model

- A persistent notes toggle, not a modifier held per entry. Players work in note-heavy bursts.
- Long-press a pad digit for the opposite mode, so power users never leave the grid.
- Number-first input (lock a digit, then tap cells) available as a setting.

### 3.5 Mistakes

Auto-check is **off by default** and there is **no mistake limit by default** (D-04). Mistakes are recorded silently for statistics.

**Strict mode** is an opt-in setting: errors flag immediately, three mistakes end the attempt. It exists for players who want stakes and is never enabled without a deliberate choice.

Overwriting an already-correct cell never counts as a mistake in any mode (D-05).

### 3.6 Timer

Display-only, hideable, never fails a puzzle (D-06). Feeds personal bests and tournament scoring.

---

## 4. Difficulty

Six ranks, graded by the hardest technique required to solve the puzzle without guessing (D-07, named in D-57). Clue count is not used for grading.

| Rank | Techniques required | Target solve time |
|---|---|---|
| Greenhorn | Full house, naked single | 2–4 min |
| Deputy | + hidden single | 4–7 min |
| Sheriff | + naked pair, pointing pair | 7–12 min |
| Marshal | + box-line reduction, naked triple | 12–20 min |
| Ranger | + hidden pair, X-wing | 20–35 min |
| Legend | + swordfish, XY-wing, simple chains | 35 min+ |

Each tier introduces its technique with a short interactive tutorial the first time the player meets a puzzle requiring it. Tutorials are skippable and replayable from the cabinet.

Notes become effectively mandatory from Marshal upward, so the notes tutorial must land no later than Sheriff rank.

---

## 5. Progression

Three independent layers (D-17).

### 5.1 Permanent — the cabinet

Never resets. Holds:

- Technique unlocks and rank
- Every trophy and medal ever earned, including seasonal ones from expired seasons
- Lifetime statistics
- Unearned seasonal trophies, shown as unfiled rather than hidden (D-21)

The cabinet is the retention engine. The map creates urgency; the cabinet creates sunk cost.

### 5.2 Seasonal — the map

Six weeks, 42 nodes, then rotates out and is replaced (D-18). Each season is one territory of the frontier, with its own palette, character, ambient audio, and rule variant.

Node composition:

| Type | Count | Notes |
|---|---|---|
| Puzzle | 30 | Difficulty ramps across tiers |
| Variant | 6 | The season's rule twist (killer, thermo, sandwich, jigsaw) |
| Chest | 4 | At 25 / 50 / 75 / 100%. Awards 12 Stamps plus cosmetics (§5.4) |
| Boss | 2 | Midpoint and finale; unique trophy to the cabinet |

Reward pacing is front-loaded — something meaningful roughly every other node through node 8, stretching through the middle, tightening for the final five (D-19).

Nodes never expire within a season, and missing days does not damage progress (D-20). Boss nodes have unlimited free retries (D-22).

Because each season introduces a **rule variant** rather than only a palette, the map has no content wall — variants are the most under-exploited content lever in the category.

### 5.3 Daily — challenge and streak

A fresh puzzle each day at midnight local time, identical for all players. A month-grid calendar fills in as days are completed; a full month unlocks a cabinet trophy.

The streak counter tracks consecutive days. One streak freeze is granted free each week and applied automatically when a day is missed (D-20). Subscribers get two additional.

The daily challenge carries no interstitial ad, ever.

### 5.4 Stamps and perks

**Stamps** are a perk currency, earned only through play (D-66). They cannot be
purchased at any price — there is no coin store and no Stamp bundle.

| Earned for | Stamps |
|---|---|
| Completing the daily challenge | 2 |
| Solving a puzzle with no mistakes | 3 |
| Reaching a 7-day streak milestone | 10 |
| Opening a chest node | 12 |
| Defeating a boss node | 20 |

A season yields roughly 200–250 Stamps for a player who finishes the map and
keeps a daily habit.

**Hints are metered** (D-67). Every puzzle includes one free hint. Beyond that a
hint costs Stamps or a rewarded video. Subscribers are unlimited (D-27).

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
This is what keeps the perk economy inside the non-punitive rule.

**Digit sweep is not candidate highlighting.** Highlighting (§3.3, D-13) is free
and always on, and shows where a digit is already marked or placed. Digit sweep
reveals where it *belongs*. The free feature is never metered.

---

## 6. Cast, comedy, and gags

Deadpan bureaucracy is the foundation, not the joke. On its own it reads as restrained rather than funny. The absurdity has to escalate visually, through a cast who react to each other and through gags that fire constantly.

### 6.1 The cast

Four characters at launch (D-58, superseding D-37). Each occupies a distinct comic role so they can be combined without overlapping.

| Character | Role | Behaviour |
|---|---|---|
| **The Sheriff** | Your boss | Grizzled. Dispenses dry, grudging approval and very little of it. Employs you; does not admire you. |
| **Ace** | Antagonist | The outlaw. Tallies your mistakes on the jailhouse wall with weary satisfaction, and cheats at numbers. Never openly hostile, which is worse. |
| **Biscuit** | Ally | A burro. Wordless, loyal, visibly delighted by your successes. Communicates entirely through movement and sound. |
| **Number Four** | Wildcard | A digit with opinions and a bounty on its head. Occasionally objects to placement and must be coaxed. Establishes that the numbers are people, which unlocks the digit gags below. |

Biscuit never speaks (D-59). This is deliberate: it costs nothing to localise, it lands in every market identically, and wordless characters reliably become the most-loved in a cast. Biscuit is the only warmth in a cast otherwise made of obstacles.

No character gives deliberately wrong advice (D-60). A character may be unhelpful in tone, never in content — hints are correct or absent. The comic-counterweight role has no occupant in the launch cast; if playtesting shows the cast needs a foil, it arrives as a fifth character with its own decision.

### 6.2 Reaction triggers

Reactions fire through animation and sound, with any spoken line under six words (D-02).

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

The character strip sits **below** the grid and never covers it. The grid is never obscured for a joke (D-40).

### 6.3 Running gags

These matter more than the character art, because they fire constantly and cost little per season.

**The jailhouse tally.** Errors physically accumulate as scratch marks on Ace's jailhouse wall, visible on the map screen and growing across the season. Solve a puzzle with no mistakes and Biscuit kicks the wall, knocking a few marks off with small ceremony. The tally is cosmetic — it never affects difficulty, rewards, or progression (D-61).

**Digits react to each other.** Place a 7 where an existing 7 can see it and both digits notice, in horror, for roughly half a second. This is the duplicate-detection feedback and the joke in a single motion, replacing the conventional red flash (D-42).

**The wanted-poster wall.** The cabinet is a wall of wanted posters of the player's deputy, one per season, in progressively more deranged outfits as rank increases.

**Telegrams as loading screens.** Loading and transition screens show genuine-looking telegrams and newspaper notices — a stolen ledger, mandatory numeracy retraining at the schoolhouse, a stern reminder about hitching posts. One line each, rotating from a pool of several hundred. Cheap comedy in otherwise dead time (D-62).

**Idle animations.** Left open, characters get bored. The Sheriff adjusts his hat. Biscuit naps. Ace recounts the tally. Idles begin after 20 seconds of no input and never make noise (D-44).

**Ad breaks in character.** The Sheriff announces the interruption as a mandatory territorial sponsorship obligation, visibly resenting it.

### 6.4 The deputy avatar

The player is a deputy, and the deputy is customisable: hats, moustaches, badges, kerchiefs, spectacles, regrettable waistcoats. Flat 2D layers on a single rig.

This is the primary cosmetics business, ahead of grid themes (D-63). Players see their own deputy constantly — on the map, in the cabinet, in every wanted-poster portrait — whereas a grid theme is a background they stop noticing within a week. Avatar parts are also far cheaper to produce than a full themed grid.

### 6.5 Production constraints

One Rive rig. Bodies, heads, props, and palettes are swapped rather than redrawn. Eight to ten looping animations per character covers every trigger above.

The discipline that makes this affordable is refusing to draw each character from scratch. If the art pipeline cannot sustain reuse at this level, cut a character rather than compromising the animation quality of the others.

---

## 7. Screens

Mockups in `docs/pages/screens.html`. Six screens define the product.

**Season map.** The spine of the session. Winding path of nodes with completed, current, and locked states. Season timer, streak, progress bar. Bottom navigation to daily, cabinet, and profile.

**Puzzle.** Grid, number pad, notes toggle, erase, hint. Character reaction strip below the grid. Timer and mistake count in the header, both hideable.

**Notes detail.** Positional candidates, two inks, candidate highlighting active.

**Node complete.** Celebration, reward, then an explicit continue tap. The interstitial, if one is due, fires after that tap — never before (D-24).

**Deputy Badge.** The subscription screen. Benefit list, plan comparison, trial framing.

**Cabinet.** Trophy shelves, unfiled gaps, lifetime and per-technique statistics.

---

## 8. Monetisation

### 8.1 What is free

All puzzles, all six tiers, the full season map, the daily challenge, the complete notes system, the cabinet, and offline play. Nothing in the core loop is paywalled.

### 8.2 Advertising

**Interstitial** (D-24). Fires only after a node completes, after the celebration animation, and after the player taps to continue. Hard limits:

- No more than one per three completed nodes
- Minimum ninety seconds between interstitials
- Maximum six per session
- Never on a chest node, a boss node, or the daily challenge

**Banner** (D-25). Permitted on the map, cabinet, and settings screens. Never visible while a grid is on screen.

**Rewarded video** (D-26). The only ad the player chooses to see. Offered for a hint, an auto-notes charge, doubling a chest, and one bonus daily chest. This is the volume driver — opt-in ads generate almost no complaints and carry higher eCPM than interstitials.

### 8.3 Purchases

| Item | Price | Notes |
|---|---|---|
| Deputy Badge, monthly | $4.99 | 7-day free trial |
| Deputy Badge, annual | $29.99 | Best value; ~9 season passes included |
| Remove ads forever | $9.99 | One-time, for non-subscribers |
| Season pass | $4.99 | Standalone; offered at node 5 |
| Cosmetic bundles | $1.99–$4.99 | Skins, themes, grid styles |

No purchasable currency and no gacha (D-23, refined by D-66). **Stamps** are earned in play and spent on assists — see §5.4. They cannot be bought at any price.

### 8.4 Deputy Badge benefits

- No ads of any kind
- Unlimited hints
- Unlimited auto-notes
- The season pass included, every season
- Two extra streak freezes weekly
- Full statistics, including per-technique speed and accuracy
- The complete daily challenge archive, replayable
- ~~Cloud save across devices~~ — moved out by **D-68**; cloud sync is free for any signed-in player
- A subscriber-only theme and character skin each season

The season pass inclusion is the load-bearing benefit: at nine seasons a year, the annual plan costs less than the passes alone, which makes annual the obvious choice and pushes players toward the lower-churn plan (D-27).

Ad removal is absolute and verified by automated test on every release (D-29).

### 8.5 Season pass

Offered at node 5, not at launch (D-30). Adds a parallel premium reward track to the same 42 nodes: extra cosmetics, an exclusive character skin, and a distinct trophy for the cabinet. It grants no gameplay advantage and no difficulty reduction.

---

## 9. Feel and completion effects

This is where clones fail, and it is engineering rather than concept. Budget real time for it — it cannot be added at the end.

### 9.1 Baseline

- Sub-100ms input response; no animation ever blocks the next tap (D-46)
- Notes appear instantly, with no transition
- A sound palette that stays pleasant on the four-hundredth note of a session
- Distinct haptic weight for placing a value, completing a row, and completing a block

### 9.2 Row or column completed

Roughly 260ms. Light sweeps outward from the cell just placed toward both ends of the unit. Cells pop to 1.06 scale and settle, staggered about 18ms apart, so the eye reads direction. Light haptic. A short rising three-note figure.

### 9.3 Block completed

Roughly 340ms. The block blooms outward from the placed cell rather than sweeping — cells brighten in a spiral so it reads as an area rather than a line, distinguishing it from a row at a glance. Medium haptic. A resolved chord rather than a rising figure.

### 9.4 Cascade

When one placement completes two or more units at once, effects **chain** with roughly 90ms offsets in the order row, column, block — never fire simultaneously (D-47). Pitch escalates with each step.

This is the single most satisfying moment in ordinary play and it happens often. Firing the effects on top of each other wastes it: the player sees one loud flash instead of three escalating rewards.

### 9.5 Puzzle completed

Roughly 1.4s, then the completion card. A wave crosses the grid from the final cell. Biscuit charges across the grid, and the paper confetti is made of tiny wanted posters. The digits take a small bow. Ace is visibly disappointed.

### 9.6 Persistent completion colour

Completed rows, columns, and blocks take a calm tint that persists for the rest of the puzzle.

Rules:

- **One flat tint level, never additive** (D-48). A cell in a completed row *and* a completed column *and* a completed block looks identical to a cell in just one. Stacking tints turns a nearly finished grid into mud, which is exactly when the board most needs to stay readable.
- **A freshly completed unit holds a warmer highlight for about two seconds**, then settles to the calm tint. The celebration and the record are different states.
- **Priority order** where highlights compete: selected cell, then candidate highlighting, then completion tint (D-49). The player's current focus always wins.
- **A corner mark accompanies the tint** so completion is never signalled by colour alone (D-50).
- Tints can be turned off in settings. Some experienced solvers find them distracting, and the information is redundant to them.

### 9.7 Restraint

Every in-puzzle effect is skippable by tapping and none exceeds 400ms (D-46). There is a reduce-effects setting, and OS-level reduce-motion is respected automatically.

Effects never fire on note entry. Notes are thinking, and thinking should be quiet.

---

### 9.8 Palette and state roles

The palette is eight tokens: six carry state — ink, focus, candidate, provisional, error, completion — and two are surfaces. Decorative elements draw from that same set and never add a ninth hue (D-53 as amended by D-71). Pale tints, depth shades, and on-colour text values derive from one of the eight rather than adding to them.

| Colour | Reserved for |
|---|---|
| Bone / sand | Surfaces only |
| Badge gold | Selection, focus, reward, progress |
| Night indigo | Candidate notes and highlighting |
| Turquoise | Provisional notes only |
| Sunset red | Errors, duplicates, Ace |
| Cactus green | Completed rows, columns, blocks |

The palette derives from the frontier's own materials — sun-bleached bone, deputy's badge, desert night, cactus — rather than being chosen for general pleasantness, which is what produces the interchangeable cream-and-pastel look common to the category (D-65). Role assignments are preserved hue for hue from the palette this replaces, so the one-hue-one-job discipline in D-53 carries over by renaming rather than re-deciding.

Season themes may repaint surfaces, props, and characters. The six state colours are fixed across every season, so the grid never has to be relearned (D-55).

Colour is never the sole signal for any state: corner marks accompany completion, position carries note identity, and character animation carries errors (D-50).

---

## 10. Technical

**Platform.** Flutter, single codebase for iOS and Android. The grid is drawn on a custom canvas for direct control of the render loop. Character animation via Rive (D-31).

**Puzzles.** Pre-generated offline in packs, each carrying its solution, required-technique grade, and seed. Server top-ups for the daily challenge and seasonal content. Full offline play is guaranteed (D-32).

**Persistence.** Note state is written on every change, not on a timer (D-33). Cloud sync for any signed-in player, subscriber or not (D-68); guests keep full local save.

**Analytics.** Instrument at minimum: node completion rate by tier, notes usage by tier, hint usage by technique, interstitial-adjacent session ends, trial start and conversion, season pass offer views and conversions.

---

## 11. Scope

**Version one** (D-35): one season, one variant beyond classic, all six tiers, the complete notes system, the daily loop, the cabinet, one character with a full reaction set, and the full monetisation stack.

**Post-launch**: additional seasons on a six-week cadence, further characters, tournaments, and a standalone killer sudoku app at roughly launch +6 months (D-34).

The notes system and technique grading must be excellent at launch, because everything else is built on them and neither can be retrofitted.

---

## 12. Risks

**The market leader.** Sudoku.com has enormous install share and a mature ad stack. You will not beat it on distribution, and any feature you ship can be copied in a sprint. Personality is the exception — matching it would require abandoning the calm minimalism their audience installed them for (D-36).

**The art budget is the product budget.** If the character animation and comedy writing are merely adequate, this is a competent sudoku app with no reason to exist.

**Non-punitive design reduces short-term ARPDAU.** Removing lives, energy, and mistake limits removes monetisation surfaces. The bet is that retention and subscription conversion more than cover it. Instrument it and be prepared to defend the choice with data rather than reopening it on the first weak month.

**Season cadence is a commitment.** Six-week seasons mean roughly nine content drops a year, indefinitely. Confirm the art pipeline can sustain that before the model depends on it.
