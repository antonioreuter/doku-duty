# Narrative proposal — the case file

**Status: proposal.** Nothing here is canon yet. If it is accepted it folds into
`docs/doku-duty-game-bible.md` §1 and needs decision IDs from **D-118** onward
(117 decisions exist today; `CLAUDE.md` still says 101 and is stale).

---

## 1. The gap

The bible already has a world, four characters, ten reaction triggers and six
running gags. What it does not have — and what no decision, spec or backlog item
mentions anywhere — is a **story**.

The current cast is **stateless**. Ace behaves identically at node 2 and node 41.
The Sheriff's approval at Greenhorn is the approval at Legend. Nothing
accumulates, nothing escalates, nothing pays off, and the season ends because the
calendar says so rather than because anything concluded.

A reaction table is comedy. It is not a narrative. The difference is memory.

The second gap is in the cast themselves. The bible gives each character a
**tone** — "dry, grudging", "weary satisfaction" — which tells an animator a mood
but does not generate jokes. A comic character needs a *mechanism*: a rule that
produces the next line on its own. Four tones produce four moods. Four mechanisms
produce a cast.

---

## 2. The premise

> **A season is a case. The trail is the case being worked. The cabinet is the
> case closed.**

The frontier administers law through paperwork, and every season Ace steals the
one thing that makes paperwork possible: the territory's **ledger**. Without it
the numbers in Dust Gulch do not add up. The Deputy's job is to restore them —
one node, one page, one grid at a time.

This earns its keep in four ways:

- **It makes sudoku diegetic.** You are literally restoring numbers to their
  correct places. That is not a metaphor for the mechanic; it *is* the mechanic.
- **It gives rotation a reason.** A season does not expire, it *closes*. New
  territory, new case. Losing the map stops reading as loss.
- **It explains the node types.** Chests are recovered goods. Bosses are Ace.
  Variants are the case taking a turn.
- **It costs almost nothing to localise.** See §6.

---

## 3. The arc, mapped to the nodes that already exist

**No data changes.** The beats land on the node layout already committed in
`season.dart` — chests at 11, 21, 32, 42; bosses at 22 and 41; the rank ramp
reaching Sheriff at 22 and Legend at 39. That layout was paced before there was a
story and it takes one without moving a single number.

| Beat | Nodes | Rank | What happens |
|---|---|---|---|
| **Act I — The theft** | 1–10 | Greenhorn → Deputy | The ledger is gone. The Sheriff is unimpressed that you are what the territory could spare. Biscuit is the only one pleased to see you. Ace has not noticed you yet and is perfectly cordial. |
| *Chest 11* | 11 | Deputy | First pages recovered. Act I closes on a gift, not a test. |
| **Act II — The pursuit** | 12–21 | Deputy → Sheriff | Ace notices you. The tally stops being bookkeeping and becomes *attention*. Number Four turns up with a bounty on its head — Ace put it there. |
| *Chest 21* | 21 | Sheriff | Equipped immediately before the confrontation. Deliberate. |
| **Midpoint — first reckoning** | **Boss 22** | Sheriff | You corner Ace and recover half the ledger. He leaves cheerfully. You have just earned Sheriff rank on the same node — the ramp and the story peak together. |
| **Act II b — The long haul** | 23–31 | Marshal | The middle of a case. The Sheriff says less, not more. Ace is now openly enjoying himself. This is where the gags carry the pacing. |
| *Chest 32* | 32 | Ranger | The break in the case. |
| **Act III — The reckoning** | 33–40 | Ranger → Legend | Legend rank lands at 39, two nodes before the climax. The Sheriff, for the first time in forty nodes, is *almost* warm. |
| **Climax** | **Boss 41** | Legend | Ace is caught. He swears revenge — formally, in writing, because this is the frontier. |
| **Denouement** | *Chest 42* | Legend | The last thing that happens in a season is being given something, never being tested. The ledger is refiled. The poster goes on the wall. |

Two structural notes worth keeping:

**The season ends on a chest.** Node 42 is a reward, not a boss. That is already
in the data and it is exactly right for a non-punitive game — the final beat is
generosity. Do not "fix" this later by moving the boss to 42.

**Ace's revenge sets up the next season.** It is already in the reaction table
("Boss defeated — swears revenge, formally"). Promoted to a season-closing beat
it becomes the engine that makes season two feel like episode two.

---

## 4. How progress carries the story

Four mechanisms. Three of them already exist and need only a new dimension.

### 4.1 Act-gated line pools *(the whole proposal, mechanically)*

Keep all ten triggers in the bible's table. Give each one **four pools** instead
of one — Act I, II, IIb, III — selected by the player's current node.

This is the entire feature. No new triggers, no new systems, no new art. The
reaction table gains a column. "First mistake in a puzzle" fires Ace in every
act; in Act I he is being polite, in Act III he is being proprietorial. Same
trigger, same animation, different pool.

### 4.2 The tally is the season clock

Already specified and already cosmetic (D-61). Give it narrative weight: the wall
fills across the season and is visible on the trail. Biscuit kicking marks off
after a clean solve stops being a flourish and becomes the one act of loyalty in
the game.

**Non-punitive check:** Ace *likes* the tally, Biscuit removes it, the Sheriff
never mentions it, and nothing mechanical reads it. It can never become shame
because no one in the fiction treats it as shameful. If the player makes no
mistakes at all, Ace is *disappointed* — which is funnier than the alternative and
costs one extra line pool.

### 4.3 Two arcs, two layers

The three progression layers in D-17 are already two different stories:

- **Rank — your career.** Permanent, never resets. The Sheriff's regard is keyed
  to *rank*, not season. He is the long arc.
- **Season — the case.** Episodic, closes, goes on the wall. Ace is the short
  arc. He resets every season, cheerfully.

That is why the Sheriff must withhold. Forty nodes of filed-and-noted, and then
at Legend: "Good work, deputy." Three words that land only because nothing else
did. It is the emotional payoff of the entire game and it costs one line.

### 4.4 The cabinet is the series so far

One poster per closed case, in progressively more deranged outfits as rank rises
(already D-63, D-45). The wall is the show's episode list. Gaps stay visible
(D-21) — an unclosed case is a fact, not an accusation.

---

## 5. The four voices

Each gets a **mechanism** that generates lines, a rule for what it never does,
and samples. Every line is six words or fewer (D-02) — counted.

### The Sheriff — *praise expressed as paperwork*

He is incapable of saying "well done". He can only report that a form has been
processed. The comedy is the gap between what you did and the language available
to describe it.

- **Voice:** flat, procedural, passive. One clause. Never an exclamation mark.
- **Never:** direct praise (until the payoff), enthusiasm, more than one sentence.
- **Lines:** "Filed." · "Acceptable." · "Paperwork's in order." · "Noted,
  deputy." · "The territory has been informed." · "That's one way to file." ·
  "Your handwriting remains a concern." · "Sixteen days. I counted."
- **The payoff, once, at Legend:** "Good work, deputy."

### Ace — *your biggest fan, and that is the threat*

Never hostile. He is **delighted** by you. He keeps the tally because he admires
the numbers and he admires you keeping them. Misplaced warmth from someone who
should be an enemy is more unsettling than menace, and it clears §5.1 (no
weapons, no aggression) without effort.

- **Voice:** courteous, pleased, proprietorial about your mistakes.
- **Never:** threats, insults, anger, anything aimed at anyone.
- **Lines:** "That's one for the wall." · "Chalk." · "Don't hurry on my
  account." · "I do enjoy this." · "Beginner's luck, deputy." · "Seven
  candidates. Bold." · "We should do this weekly."
- **When you are flawless:** "Disappointing. You were doing badly."
- **Act III, possessive:** "My deputy. Look at you."
- **Boss 41:** "I'll want that back."

### Biscuit — *disproportion*

Wordless (D-59). Reacts **enormously** to small things and **not at all** to
large ones: ecstatic about a completed row, entirely unmoved by a defeated boss.
The joke is the calibration, and it needs no translation.

- **Never:** speaks, appears sad *about the player*, reacts to a mistake.
- **Vocabulary:** ears up, ears flat, delighted braying, sympathetic shrug, nap.
- **His one plot function:** he kicks the tally wall. That is his whole arc and
  it is the warmest beat in the game.

### Number Four — *labour relations*

A digit with a union. It objects to being placed, has opinions about the other
digits, and is proud of its bounty. It establishes that the numbers are people,
which is what makes the duplicate-reaction gag (D-42) land instead of reading as
a gimmick.

- **Voice:** aggrieved, formal, weirdly professional.
- **Never:** wrong. D-60 holds — Four objects to *placement aesthetics* and
  working conditions, never to correctness. It is unhelpful in tone, never in
  content.
- **Lines:** "Not there." · "Under protest." · "I have a bounty." · "Seven
  started it." · "This is my third shift." · "I'd like that in writing." ·
  "Check with nine."

---

## 6. What it costs

The constraint that looks like a limit is the thing that makes this affordable.

Every line is **six words or fewer** and the game ships in fifteen-plus
languages. A narrative told in cutscenes or journal entries would be a
five-figure localisation bill and a translator's nightmare. A narrative told in
≤6-word units, carried by **state the player can see** — the tally filling, the
posters accumulating, the ledger refiling — is close to free.

Rough shape: four acts × ten triggers × three or four variants ≈ **120–160 short
lines per season**, plus the ten or so beat lines. At six words that is under a
thousand words of source text. The *arc* is carried by state; the *lines* only
have to be funny.

This is also why the story must be **shown**. Nobody reads exposition in a sudoku
app. They will absolutely notice a wall filling up with chalk marks.

---

## 7. What this needs to become real

**New decisions, D-118 onward:**

| Proposed | Records |
|---|---|
| D-118 | A season is a case; the ledger premise; rotation as closure |
| D-119 | The four-act structure and its mapping to the existing node layout |
| D-120 | Act-gated line pools — the reaction table gains an act dimension |
| D-121 | The Sheriff withholds until Legend; one payoff line per career |
| D-122 | Character mechanisms, superseding the tone-only descriptions in §1.1 |

**Bible amendments:** a new §1.0 (the premise and arc) ahead of §1.1; §1.1
rewritten from tones to mechanisms; §1.2 gains the act column.

**Backlog:** this is mostly **change 20 `add-character-system`**, which already
owns the reaction trigger table — the act dimension is a small addition to work
that is already scoped. The tally escalation belongs to **change 22
`add-running-gags`**. Neither needs a new capability.

---

## 8. Open questions

1. **Does the ledger premise survive contact with season two?** It should be
   testable: if "Ace steals X, you restore X" cannot be varied six times without
   getting tired, it is too narrow. My view is that the *thing stolen* is the
   seasonal variable — ledger, census, brand registry, the town clock — and the
   shape stays.
2. **Who presents the store?** Still unanswered since D-58 removed Ruby, and it
   is now more pressing: with a narrative, the one screen with no character
   attached will read as the one screen that is not part of the game. The
   Sheriff resenting a mandatory sponsorship obligation is already in the gags
   list and is the cheapest answer.
3. **Does Number Four speak on the grid, or only in the strip?** A digit that
   talks while you are solving risks violating D-40's spirit even if the strip
   stays below the grid.
4. **How much does the trail show the story?** The tally wall is the obvious
   on-map state. Whether the trail also marks act boundaries is a layout question
   for the redesign in `docs/pages/screens-redesign.html`.
