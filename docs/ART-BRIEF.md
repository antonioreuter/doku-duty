# Art brief

For the character illustrator and animator. Commission this before engineering
starts — it is the long-lead item, and Milestone 3 assumes finished Rive files
already exist.

Read `docs/IDEA.md` for the world and `docs/DESIGN.md` for exact colour and stroke values.

---

## What this art has to do

The puzzles in this game are mathematically identical to every other sudoku app
on the store. There is no gameplay advantage available. The characters are the
product — if they are merely competent, this is a competent sudoku app with no
reason to exist (D-36).

The comedy is carried by **animation and sound**, not by written lines. Any
spoken line is under six words, because the game ships in fifteen-plus
languages and long jokes do not survive translation or a small screen (D-02).

---

## Tone

Deadpan. The joke is that everyone takes number-filing extremely seriously on a
frontier where the law runs on paperwork.

The rendering must be **warm cartoon, not authentic western** (D-51). An
accurate frontier aesthetic is dusty, harsh, and cold. Draw a cartoon *about*
the West — thick warm outlines, generous curves, exaggerated proportions. Think
a children's animated series set in a western town, not a spaghetti western.

Avoid: gunfights, weapons drawn in anger, saloon drinking, anything that reads
as violent or adult. Ace is a nuisance, not a threat.

---

## The cast

### Ace — the antagonist

An outlaw who tallies your mistakes on the jailhouse wall with weary
satisfaction, and is visibly disappointed when you solve cleanly. Never openly
hostile, which is worse.

Silhouette cues: bandana over the lower face, low hat brim, narrow eyes, a
playing card always somewhere on him. Lean, angular, slightly hunched.

### The Sheriff — the comic counterweight

Your grizzled boss. Absolutely certain and frequently wrong. Dispenses specific
old-timer advice the player learns to ignore. His advice is never harmful —
following it wastes a move, never a puzzle (D-39).

Silhouette cues: enormous hat, enormous moustache, barrel chest, small bowed
legs, thumbs hooked in a heavy belt. Star badge.

### Biscuit — the ally

A burro. **Never speaks, ever** (D-38). Celebrates completions with a hoof
stamp. Communicates entirely through movement, ears, and sound.

Silhouette cues: oversized ears, stocky body, saddlebag. The only warm,
uncomplicated presence in the cast — lean into it.

### Number Four — the wildcard

A digit with opinions and a bounty on its head. Occasionally objects to being
placed and must be coaxed. Establishes that the numbers are people, which is
what makes the digit reactions below work.

Silhouette cues: it is legibly the numeral 4 first and a character second.
Whatever face and limbs it has must not compromise reading as a digit at 30px.

---

## Design rules

**The silhouette test.** Fill each character solid black. If you cannot tell
which one it is, the design is not finished. All four must be distinguishable at
a glance and at small size.

**Push the proportions.** Cartoon appeal comes from exaggeration — the Sheriff's
hat and moustache should be absurdly oversized relative to his legs. Realistic
proportions read as stiff.

**Asymmetry always.** No character stands centred and face-on. Weight on one
leg, head tilted, hat off-axis. Symmetry is the fastest way to make a drawing
look dead.

**Line weight varies.** Thick outer contour, thinner interior detail. Uniform
stroke weight is the most common tell of lifeless vector art.

**Overlap creates depth.** Arms cross in front of bodies, props sit in front of
legs. Flat side-by-side shapes read as diagrams.

---

## Deliverables per character

1. **Turnaround** — front, three-quarter, side. Three-quarter is the primary
   game pose.
2. **Expression sheet** — minimum eight: neutral, pleased, disappointed,
   impatient, smug, surprised, bored, delighted.
3. **Rive rig** — one shared rig where possible, with swapped heads, props, and
   palettes. This is what makes nine seasons a year affordable.
4. **Animation set** — the states in the table below.

## Required animation states

| State | Character | Notes |
|---|---|---|
| Idle | All | Loops. Begins after 20s of no input. **Always silent** (D-44) |
| First mistake | Ace | Dry, marks the wall |
| Third mistake | Ace | Almost pleased |
| Solved with no mistakes | Ace | Openly disappointed |
| Long pause | Sheriff | Unhelpful suggestion |
| Technique unlocked | Sheriff | Claims credit |
| Row or block complete | Biscuit | Hoof stamp, enthusiastic |
| Provisional notes cleared | Biscuit | Sympathetic |
| Puzzle complete | Biscuit | Stamps the grid, confetti |
| Objects to placement | Number Four | Brief, playful |
| Boss defeated | Ace | Files a complaint |
| Return after days away | Ace | Pointed remark about attendance |

Eight to ten loops per character covers all of this. If the pipeline cannot
sustain reuse at this level, cut a character rather than compromising the
animation quality of the others.

---

## Digit reactions

Separate from the cast, and the highest-value single animation in the product
(D-42).

When a digit is placed where an identical digit can already see it, **both
digits notice each other, in horror, for roughly half a second.**

This replaces the conventional red flash. Same information, delivered as charm
rather than reproach. It fires constantly, it converts the game's sorest moment
into its most charming one, and it costs one animation. Budget for it properly.

Requirements: under 400ms, must not block input, must read at 30px, must work
for all nine digits from one rig.

---

## Also needed

**Deputy avatar parts** (D-45). The player character, customisable: hats,
moustaches, kerchiefs, badges, spectacles, waistcoats. Flat layers on one rig.
This is the primary cosmetics business, so plan for roughly forty parts at
launch and a steady drip after.

**Wanted posters.** One portrait frame per season for the cabinet wall, with
the deputy avatar composited in. Progressively more disreputable as rank rises.

**Map props per territory.** Cacti, water troughs, jailhouse, stagecoach, mine
head. Six to eight per season. Keep the character rig shared and let props be
the cheap seasonal variable — nine seasons a year makes this the difference
between sustainable and not.

---

## Technical constraints

- Everything must read at phone size. Test at 30px before considering a design
  finished.
- Rive, with runtime-controllable state machines — reactions fire on gameplay
  events, not on a timeline.
- The character strip sits below the grid and never overlaps it (D-40).
- Use only the tokens in `docs/DESIGN.md`. No new hues (D-53).
- Every animation under 400ms except the puzzle-complete sequence.

---

## Priority

If the budget only covers part of this, buy in this order:

1. Digit reactions
2. Biscuit, complete
3. Ace, complete
4. Deputy avatar parts
5. The Sheriff
6. Number Four

Biscuit outranks Ace because the wordless ally is the cheapest to localise and
the likeliest to be loved. Number Four is last because the game works without
it.
