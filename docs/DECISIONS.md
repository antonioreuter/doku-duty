# Doku Duty — decision log

Every decision below was made in the absence of a stated preference. Each one is reversible, but the rationale explains what breaks if you reverse it. Decisions are numbered for reference in tickets.

Decisions are never edited away. When one is replaced, the original stays where it is with a **Superseded by D-NN** marker, and the replacement is appended as a new entry that says what changed and why. D-56 onward record the move from the original bureau setting to the frontier setting in `docs/IDEA.md`.

---

## Product identity

### D-01 · Working title: Sudoku Bureau

> **Superseded by D-56** — the title is Doku Duty and the setting is the frontier. Kept for the rationale about what any replacement theme must supply, which is the test D-56 had to pass.
The comedic setting is a vast, self-important government department that processes numbers. Regions of the season map are departments. Difficulty tiers are civil-service ranks. The antagonist is an auditor who logs your mistakes.

**Rationale.** A single coherent world beats scattered jokes. It gives art direction, copy voice, difficulty naming, region theming, and character design one source to draw from, which cuts both cost and the risk of tonal drift. It also produces visual assets (stamps, forms, ledger paper, filing cabinets) that read instantly at phone size, unlike, say, a fantasy or space setting where everything becomes mush at 40px.

**What breaks if reversed.** Nothing structural. The theme is a skin over the mechanics. But a replacement theme must supply the same four things: a rank ladder, a place metaphor for the map, an antagonist for mistakes, and a collection metaphor for the cabinet.

### D-02 · Comedy is delivered through character animation and sound, not written jokes
Six to eight recurring reactions per character, animated, with short subtitle-length lines under six words.

**Rationale.** Written humour localises badly and you will want 15+ languages. Animation and sound survive translation. Short lines also survive a small screen and a player who is mid-thought on a hard grid. Long jokes interrupt concentration, which is the opposite of what a puzzle game should do.

---

## Core play

### D-03 · The game is non-punitive by default
No lives. No hearts. No energy. No session limits. No forced waiting. No failure state on any puzzle.

**Rationale.** This was an explicit requirement, and it also happens to be correct commercially. Sudoku is a solo logic game with no opponent, so artificial scarcity has no competitive justification — it reads purely as a monetisation lever and players say so in reviews. Removing it costs you a small IAP category you were never going to win anyway, and buys you the positioning line competitors cannot use.

### D-04 · Auto-check is OFF by default; there is no mistake limit by default
Mistakes are recorded silently for stats. The player may enable strict mode, which flags errors immediately and caps mistakes at three.

**Rationale.** Reviews of the market leader repeatedly complain about the immediate wrong-answer buzz and about being penalised for overwriting a cell that was already correct. Defaulting to off respects the player who wants to find their own errors, which is the actual skill sudoku teaches. Strict mode preserves the option for players who want stakes, and turning it on is a deliberate act, so it never feels imposed.

### D-05 · Overwriting a correct cell never counts as a mistake, in any mode
**Rationale.** It is a well-documented frustration in a competitor and there is no design argument for it. The player did not get a logic problem wrong; they mis-tapped.

### D-06 · The timer is display-only and can be hidden
It never fails a puzzle. It feeds leaderboards and personal bests only.

**Rationale.** Non-punitive. A visible countdown converts a relaxing activity into a stress activity for a large share of the audience, and that audience is the one that plays daily for years.

### D-07 · Six difficulty tiers, defined by required solving technique

> **Rank names superseded by D-57.** The grading method below is unchanged and still current; only the six names have moved to the frontier ladder.
Trainee, Clerk, Officer, Inspector, Auditor, Commissioner. Puzzles are generated and graded by the hardest technique required to solve them without guessing, not by clue count.

**Rationale.** Clue count is a poor proxy for difficulty — a 26-clue puzzle can be easier than a 30-clue one. Technique grading gives honest difficulty, a natural curriculum, and progression that feels like getting smarter rather than grinding. It also creates a defensible differentiator: players who learn X-wing from your app will attribute the learning to your app.

Three tiers, as originally proposed, compresses too much. "Advanced" would have to span a beginner's first genuinely hard puzzle and a veteran's expert grid.

### D-08 · Every puzzle has exactly one solution and is solvable by logic alone
No puzzle in any tier requires guess-and-check.

**Rationale.** Non-negotiable for credibility with serious solvers, who are the ones who review, recommend, and subscribe.

---

## Notes (pencil marks)

### D-09 · Up to nine candidates per cell, not three
**Rationale.** The proposed three-note cap would make tiers 4–6 literally unplayable. Naked triples require holding three candidates in three cells while having eliminated from four or five elsewhere; X-wing requires full candidate sets across two rows. A cap of three does not merely inconvenience the advanced player, it removes the techniques that define the upper tiers — which are the tiers the technique-based progression system exists to teach.

### D-10 · Notes are positional, in a fixed 3×3 arrangement
1 is always top-left, 5 always centre, 9 always bottom-right. Adding or removing a candidate never moves the others.

**Rationale.** Players scan by position rather than reading digits, which is several times faster on a densely marked board. Sequential notes that reflow on every edit are a leading cause of a puzzle app "feeling bad" without players being able to say why.

### D-11 · Two note inks: settled candidates and provisional ones
Blue for candidates the player has derived. Violet for a hypothesis under test. One control clears all provisional marks at once.

**Rationale.** On tiers 5–6 players test chains — assume a value, follow the consequences, look for a contradiction. Today they do that in their head or on real paper. Almost no competitor supports it. It is cheap to build on top of an existing note model and it is the kind of feature serious solvers tell other solvers about.

### D-12 · Auto-cleanup is on and not optional
Placing a value removes that candidate from every cell in its row, column, and box.

**Rationale.** Without it, notes go stale within roughly twenty moves, players stop trusting them, and the feature is effectively dead. Making it optional gives players a setting whose only function is to make the game worse.

### D-13 · Candidate highlighting
Tapping a digit on the pad highlights every cell holding it as a note.

**Rationale.** This is what makes a heavily marked board readable, and it is how pointing pairs and X-wings become visible rather than deduced by squinting. It is the single highest-value comfort feature for hard grids.

### D-14 · Notes never count as mistakes, even when wrong
**Rationale.** Notes are thinking out loud. Punishing exploration directly undermines the technique learning the progression system depends on.

### D-15 · Manual and generated notes are distinguishable in the data model, identical on screen
**Rationale.** Undo, auto-cleanup, and "clear notes" all need to know the provenance. Retrofitting the distinction later means migrating saved games.

### D-16 · There is no "you still have notes" completion check
A cell holds either a value or notes, never both, so a completed grid has no notes by construction.

**Rationale.** The originally proposed end-of-game rule describes a consequence, not a rule. Implementing it as a check would produce a dead end on an otherwise solved puzzle, which is the worst possible moment to block a player.

---

## Progression

### D-17 · Three separate progression layers
Permanent (technique unlocks, trophy cabinet, lifetime stats), seasonal (the map, six weeks, rotates), daily (challenge calendar and streak).

**Rationale.** The originally proposed single permanent map has a content wall — a finite map runs out and the whole progression system dies with it. Making the map seasonal and disposable removes the wall entirely and creates a live-ops calendar. The permanent layer is what stops rotation from feeling like loss.

### D-18 · Season length is six weeks, 42 nodes
Roughly one node per day, with several days of slack for a daily player.

**Rationale.** Long enough to justify a season pass purchase, short enough that a player who joins late in a season is not permanently behind. Six weeks also gives eight to nine seasons a year, which is a manageable art production cadence for a small team.

### D-19 · Reward pacing is front-loaded
Something meaningful roughly every other node for nodes 1–8, stretching through the middle, tightening again for the final five.

**Rationale.** The decision to buy the pass is made early, so the season must feel generous before the player has committed. The tightening at the end covers the completion push.

### D-20 · Missing days never damages season progress
Nodes do not expire within a season. One streak freeze is granted free each week and applied automatically.

**Rationale.** Non-punitive. A streak that punishes a sick day or a holiday converts a habit into an obligation, and players resolve obligations by uninstalling. Automatic application matters — a freeze the player must remember to use is a trap, not a safety net.

### D-21 · Unearned seasonal trophies show in the cabinet as unfiled, not hidden
**Rationale.** Visible gaps drive return engagement far better than absence does, and it is honest about what was missed without shaming.

### D-22 · Boss nodes have unlimited free retries
**Rationale.** A retry cost would reintroduce the punitive economy removed in D-03, at the single most emotionally loaded moment in the season.

---

## Cast and comedy

### D-37 · Four characters at launch, not one

> **Superseded by D-58** — the four roles survive, the names and the setting do not. Kept for the rationale on why four, which D-58 does not repeat.
The Auditor (antagonist), Deputy Undersecretary Pip (comic counterweight), the Stamp (ally), and Number Four (wildcard).

**Rationale.** A single character can only react to the player, which produces a narrow, repetitive comic range that wears out within a week of daily play. Characters who react to each other produce combinations, and combinations are what make a small pool of animations feel large. The four roles are chosen to be non-overlapping so any pair can share a screen without redundancy. This revises the earlier one-character scope in D-35; the additional cost is accepted because personality is the product (D-36) and one character is not a personality, it is a mascot.

### D-38 · The Stamp never speaks

> **Superseded by D-59** — same decision, now attached to Biscuit.
Communicates entirely through movement and sound.

**Rationale.** Zero localisation cost across fifteen-plus languages, and identical comic timing in every market. Wordless characters reliably become the most-loved member of a cast, and the Stamp is the only ally in a game otherwise populated by obstacles — that warmth matters more than any line it could deliver.

### D-39 · Pip's advice is always wrong and never harmful

> **Retired by D-60** — Pip has no successor in the frontier cast, so there is no character the decision applies to.
Following it wastes a move, never a puzzle.

**Rationale.** The joke only works if trying it is safe. A wrong hint that costs real progress converts a gag into a trap, and players who feel tricked stop engaging with characters entirely — which would poison the rest of the cast. This also keeps Pip usable at every difficulty tier without balance work.

### D-40 · The character strip sits below the grid and never covers it
**Rationale.** The grid is the product. Covering it for a joke interrupts the exact concentration the game exists to support, and a joke that costs the player their train of thought on an expert puzzle is not a joke.

### D-41 · The mistake pile is cosmetic only

> **Superseded by D-61** — same decision, now Ace's jailhouse tally.
Errors accumulate visibly on the Auditor's desk but never affect difficulty, rewards, or progression.

**Rationale.** It is a running visual gag, not a punishment mechanic. The moment it carries consequence it violates the non-punitive principle (D-03) and turns a piece of comedy into a source of anxiety. The clean-solve shredding ceremony gives the pile a satisfying release without ever making it a threat.

### D-42 · Digit reactions replace the conventional duplicate flash
Place a 7 where an existing 7 can see it and both digits react for roughly half a second.

**Rationale.** Sudoku's sorest emotional moment is the discovered mistake. Conventional apps mark it with a red flash, which is information delivered as mild reproach. Routing the same information through character animation converts the game's most frustrating beat into its most charming one — this is the single clearest expression of the product's positioning, and it costs one animation.

### D-43 · Loading and transition screens carry rotating internal memos

> **Superseded by D-62** — same decision, now telegrams and newspaper notices.
A pool of several hundred one-line departmental notices.

**Rationale.** Loading time exists whether or not it is used. Text-only memos are the cheapest comedy in the product — no art, no animation, no engineering beyond a string table — and a large pool means the repetition that kills most loading-screen humour never sets in. It also gives the writing team a low-risk surface to establish the Bureau's voice.

### D-44 · Idle animations start after 20 seconds and are always silent
**Rationale.** Idles reward the player who leaves the app open and make the world feel inhabited. Silence is non-negotiable: a player who has set the phone down to think, or who is playing in bed or in company, must never be startled by a character making noise unprompted.

### D-45 · The clerk avatar is the primary cosmetics business, ahead of grid themes

> **Superseded by D-63** — same decision, now the deputy avatar.
**Rationale.** Players see their own clerk constantly — on the map, in the cabinet, in every employee-wall portrait — whereas a grid theme is a background they stop consciously noticing within a week. Avatar parts are also markedly cheaper to produce than a fully themed grid, so the margin is better on the item players value more. Grid themes remain, but as season rewards rather than the main store.

---

## Monetisation

### D-23 · No consumable currency and no gacha in v1

> **Refined by D-66** — the prohibition now attaches to *purchasable* currency. Stamps are earned in play only and can never be bought, so the coin store this decision rejects still does not exist.

Hints are earned by rewarded video or included in the subscription. There is no coin store.

**Rationale.** A currency layer obscures price, invites the predatory patterns the non-punitive positioning is built to reject, and adds meaningful build and balance cost. For a solo puzzle game, direct purchases are simpler for the player and cheaper to operate.

### D-24 · Interstitial ads run only after a node completes, after the celebration, and after the player taps to continue
Hard limits: no more than one interstitial per three completed nodes, minimum ninety seconds between interstitials, maximum six per session. None on chest nodes, boss nodes, or the daily challenge.

**Rationale.** The market leader's most consistent review complaint is being congratulated and then immediately hit with an ad. The damage is not the ad, it is the timing — it lands on the exact beat where the player expects reward. Placing the ad after an explicit tap converts it from an ambush into a transition. The volume caps trade a modest amount of impression inventory for retention, which is worth more over a player's lifetime.

### D-25 · No banner ad is ever visible while a grid is on screen
**Rationale.** Banners on a puzzle grid cost accidental taps and screen real estate on the one screen where both matter. Banners are permitted on the map, cabinet, and settings screens only.

### D-26 · Rewarded video is the only ad type the player can choose to see
Offered for: a hint, a charge of auto-notes, doubling a chest, and one bonus daily chest.

**Rationale.** Opt-in ads generate almost no complaints because the player set the price themselves. They also carry substantially higher eCPM than interstitials, so a rewarded-heavy mix can hold revenue while cutting interstitial volume.

### D-27 · Subscription: the Bureau Card, $4.99 monthly or $29.99 annually, seven-day free trial

> **Renamed by D-64** — the subscription is the Deputy Badge. Pricing, trial, and the benefit list below are unchanged.
Benefits:
- No ads of any kind
- Unlimited hints
- Unlimited auto-notes
- The current season pass included, every season
- Two additional streak freezes per week
- Full statistics, including a per-technique breakdown of speed and accuracy
- The complete daily challenge archive, replayable
- ~~Cloud save across devices~~ — **moved out by D-68**; free for any signed-in player
- A subscriber-only theme and character skin each season

**Rationale.** The season pass inclusion is the load-bearing benefit. At $4.99 per season standalone and roughly nine seasons a year, the annual subscription costs less than the passes alone, which makes annual the obvious choice and pushes players toward the higher-LTV, lower-churn plan. Unlimited hints are safe to give away because there is no opponent to be unfair to. The per-technique statistics are the benefit that appeals specifically to the serious solver, who is both the most likely subscriber and the most likely to recommend the app.

### D-28 · A separate one-time purchase removes ads forever, $9.99
**Rationale.** A large share of players will never subscribe to anything but will pay once to be left alone. Pricing it at twice the monthly rate makes the subscription look better without making the one-time option feel punitive.

### D-29 · Ad removal is absolute and verified by automated test on every release
**Rationale.** Reports of ads appearing after ad removal was purchased are the most trust-destroying complaint in competitor reviews. Whether the cause is a bug or mediation leakage, the remedy is the same: treat it as a release-blocking test, not a support ticket category.

### D-30 · The season pass is offered at node 5, not at launch
**Rationale.** The offer converts far better after the player has experienced the season and has visible progress to protect. Presenting it on first open reads as a paywall on a free game.

---

## Feel and effects

### D-46 · No in-puzzle effect exceeds 400ms, and none blocks input
All effects are skippable by tapping. Reduce-effects setting available; OS reduce-motion respected.

**Rationale.** A celebration that delays the next tap converts a reward into an obstacle, and a fast player will hit it dozens of times per puzzle. The effect must be something the player passes through, never something they wait out. This is also why every effect is interruptible: the player who is mid-flow is the player having the best time, and interrupting them to show them how well they are doing is self-defeating.

### D-47 · Simultaneous completions chain, they do not overlap
Row, then column, then block, roughly 90ms apart, with escalating pitch.

**Rationale.** A placement that completes several units at once is the most satisfying moment in ordinary play and it happens frequently. Firing the effects simultaneously collapses three rewards into one indistinct flash. Chaining them costs 180ms and roughly triples the perceived payoff.

### D-48 · Completion tints are one flat level and never stack
A cell in a completed row, column, and block looks identical to a cell in only one.

**Rationale.** Additive tinting darkens progressively as the puzzle nears completion, which is precisely when the board must stay most readable. It also produces an arbitrary patchwork of shades that carries no useful information — the player does not need to know a cell is in three completed units, only that it is settled.

### D-49 · Highlight priority: selection, then candidate highlighting, then completion tint
**Rationale.** The player's current focus must always win. A completion tint that obscures the selected cell or the highlighted candidate makes a decorative state override a functional one, which is the wrong way round.

### D-50 · Completion is never signalled by colour alone
A small corner mark accompanies the tint.

**Rationale.** Roughly one in twelve men has some form of colour vision deficiency, and this is a colour-heavy grid. A secondary cue costs nothing and makes the state legible to everyone. It also survives the player turning tints off.

### D-51 · The visual language is cartoon, not institutional

> **Amended by D-56.** The principle stands exactly as written; read "a cartoon *about* the West" for "a cartoon *about* an office".
Thick warm outlines, generous corner radii, a warm paper palette, and characters and props illustrated into the map. The bureaucratic premise is carried by the writing and the characters, not by the rendering.

**Rationale.** An earlier revision styled the interface as an authentic government form — hairline rules, right angles, institutional grey. It was accurate to the theme and completely wrong for the product: real bureaucratic aesthetics are cold, and nobody wants to relax with one. The joke should be bureaucratic; the drawing should look like a cartoon *about* an office rather than an actual office. This separation is what lets the theme stay funny without the app feeling unfriendly, and it is why the comedy premise survived the restyle unchanged.

### D-52 · Effects never fire on note entry
**Rationale.** Notes are thinking, and thinking should be quiet. A player marking a dense board makes dozens of note entries in a row; any celebration attached to that becomes noise within seconds and would make the notes system unpleasant to use — the opposite of what the top three tiers need.

---

### D-53 · One hue, one job — state colour is reserved before decoration

> **Amended by D-71** — the principle stands exactly as written. Only the count was wrong, and this entry did not agree with itself: five states cannot forbid a seventh hue. Read D-71 for the number, this entry for the reasoning.
Five states need dedicated colour: selection, candidate highlighting, provisional notes, error, completion. Decorative elements draw from that same set and never introduce a seventh hue.

**Rationale.** A sudoku grid is a dense information surface where colour carries meaning, not mood. If a decorative accent shares a hue with a state, the board becomes ambiguous exactly when it is busiest. Reserving state colour first and letting decoration follow is the only ordering that keeps the grid legible as complexity grows.

The palette this replaces — cream with coral, amber, mint and purple — failed on two counts. It was the default friendly-mobile-game palette, indistinguishable from a dozen competitors. And all five accents sat at roughly equal saturation, so nothing had visual priority, while green simultaneously carried completion, progress, and correctness.

### D-54 · The palette is sourced from the Bureau's materials, not chosen for pleasantness

> **Superseded by D-65** — same method, different world. Kept because the reasoning about why derived palettes beat chosen ones is the load-bearing part.
Ledger paper for surfaces, carbon-copy violet for candidates, rubber-stamp red for errors, ochre for focus and reward, teal for provisional marks, sage for completed units.

**Rationale.** Palettes picked for general pleasantness converge on the same warm cream and pastel accents, because that is what "friendly" defaults to. Deriving colour from the world's actual materials produces combinations nothing else in the category uses — pale sage-green ledger paper with violet ink is distinctive precisely because no one arrives at it by asking what feels nice. It also ties the palette to the theme, so seasonal repaints stay coherent.

### D-55 · Season themes may repaint surfaces and props, never state colours

> **Amended by D-71** — six state hues, not five. The rule is unchanged; it inherited D-53's miscount.
The state hues are fixed across every season.

**Rationale.** Seasons rotate every six weeks. If completion or error colour changed with the theme, players would relearn the grid nine times a year, and the muscle memory that makes an expert board readable would never form. Surfaces and props carry the seasonal identity; the functional layer stays constant.

---

## Technical

### D-31 · Flutter, with the grid drawn on a custom canvas
Character animation via Rive.

**Rationale.** Sudoku is a dense UI grid with heavy custom hit-testing, not a physics or 3D scene. Unity would ship a far larger binary and a slower cold start, both of which measurably hurt retention in casual puzzle. Flutter gives a single codebase for both platforms, direct control of the render loop for the sub-100ms input response the feel depends on, and native-feeling scroll and haptics. Rive keeps character animation small and runtime-controllable, which matters when reactions must trigger on gameplay events.

### D-32 · Puzzles are pre-generated offline and shipped in packs, with server top-ups
Each puzzle carries its solution, its required-technique grade, and a seed.

**Rationale.** On-device generation of a graded expert puzzle is slow enough to be felt, and grading requires running a full solver. Pre-generation moves that cost off the device entirely, guarantees full offline play, and makes the daily challenge identical for every player, which leaderboards require.

### D-33 · Note state is written on every change, not on a timer
**Rationale.** A player twenty minutes into an expert grid with a fully marked board will not forgive losing it to an app kill. The write is small and the cost is negligible.

### D-34 · Killer sudoku ships as a separate app at launch +6 months
**Rationale.** Two store listings mean two ASO surfaces and two sets of category rankings, with cross-promotion between them at zero acquisition cost. This is the structure the market leader uses. Variants still appear as nodes inside the main app's seasons; the standalone app is additive, not exclusive.

---

## Scope

### D-35 · Version one ships one season, one variant beyond classic, all six tiers, the full notes system, the daily loop, and one character
Additional regions, variants, characters, and tournaments follow once retention data exists.

**Rationale.** The full proposal is roughly a year of work. The notes system and the technique grading are the two things that must be excellent at launch because everything else is built on them, and neither can be bolted on later. Characters and regions are additive content that can ship continuously — and shipping them into a live game with real retention data is a better use of the art budget than guessing before launch.

### D-36 · The art direction and comedy writing are the product, not the sudoku engine
Budget accordingly.

**Rationale.** Sudoku puzzles are mathematically identical in every app on the store. There is no puzzle-quality advantage available to win. The market leader has enormous install share and a mature ad stack, and cannot be beaten on distribution or on features that any competitor can copy in a sprint. Personality is the one axis where a competitor cannot simply match you, because matching it would require abandoning the calm minimalism their existing audience installed them for.

---

## The frontier revision

D-56 through D-65 replace the original bureau setting with the frontier setting described in `docs/IDEA.md`. The mechanics are untouched — every decision here changes a name, a place, or a piece of art direction, and none changes how the game plays.

### D-56 · Title and setting: Doku Duty, on the frontier
Supersedes D-01. The world is a territory of dusty frontier towns where the law is administered through paperwork and everyone takes numbers extremely seriously. The player is a Deputy. Regions of the season map are territories. Difficulty tiers are frontier ranks. The antagonist is an outlaw who tallies your mistakes.

**Rationale.** D-01's own test for a replacement theme was that it must supply four things: a rank ladder, a place metaphor for the map, an antagonist for mistakes, and a collection metaphor for the cabinet. The frontier supplies all four more naturally than the bureau did — deputy-to-legend is a ladder players already know without being taught, a territory is a map rather than an org chart, an outlaw is a more legible antagonist than an auditor, and a wanted-poster wall collects better than a personnel file.

The deeper reason is warmth. The bureau premise was funny in a register that stayed cold: its jokes were all about tedium, and a game the player opens to relax was being asked to make drudgery entertaining for a year of daily sessions. The frontier keeps the same core joke — solemn bureaucracy applied to numbers — while giving the art direction somewhere warm to sit, which is what D-51 was already reaching for when it insisted on cartoon over institutional.

**What breaks if reversed.** Nothing structural, same as D-01. But this is the second theme change, and a third would start costing real credibility with any art contractor working from these documents. Treat the setting as settled.

### D-57 · The six ranks are Greenhorn, Deputy, Sheriff, Marshal, Ranger, Legend
Supersedes the rank names in D-07. The grading method is unchanged: puzzles are graded by the hardest technique required to solve them without guessing, never by clue count.

| Rank | Techniques required |
|---|---|
| Greenhorn | Full house, naked single |
| Deputy | + hidden single |
| Sheriff | + naked pair, pointing pair |
| Marshal | + box-line reduction, naked triple |
| Ranger | + hidden pair, X-wing |
| Legend | + swordfish, XY-wing, simple chains |

**Rationale.** The bureau ladder — Trainee through Commissioner — required the player to learn an invented hierarchy before the rank told them anything. Sheriff outranks Deputy without explanation in most of the markets this ships to, so the ladder does its job the first time a player sees it. Legend as the top rank also breaks the pattern deliberately: the sixth tier is the one players brag about reaching, and a job title is a weaker brag than an epithet.

**Known collision.** Sheriff and Deputy are both ranks and characters, and the player is also "the Deputy". This is inherited from `docs/IDEA.md` and is left as-is, but UI copy must never leave the reader guessing which is meant — prefer "Sheriff rank" and "the Sheriff" as fixed phrasings, and never use a bare rank name as a speaker label.

### D-58 · The cast is the Sheriff, Ace, Biscuit, and Number Four
Supersedes D-37. Four characters at launch, unchanged in number and in the requirement that the roles not overlap.

| Character | Role | Replaces |
|---|---|---|
| **The Sheriff** | Your grizzled boss. Dry, grudging approval. | Pip's slot, not Pip's personality |
| **Ace** | The outlaw. Tallies your mistakes and cheats at numbers. | The Auditor |
| **Biscuit** | A burro. Wordless, loyal, delighted by your successes. | The Stamp |
| **Number Four** | A digit with opinions and a bounty on its head. | Unchanged |

**Rationale.** D-37's argument for four characters over one is unaffected and not repeated here. The reassignment is what matters: Ace inherits the Auditor's function of noticing mistakes, but as a rival rather than a supervisor, which is a warmer relationship to be in for a year of daily play. The Sheriff takes the boss role the Auditor also partly occupied, so that approval and antagonism come from two different characters instead of one — the bureau cast had the same figure both judging and employing you, which flattened both jokes.

### D-59 · Biscuit never speaks
Supersedes D-38. Communicates entirely through movement and sound.

**Rationale.** Unchanged from D-38: zero localisation cost across fifteen-plus languages, identical comic timing in every market, and wordless characters reliably become the most-loved member of a cast. Biscuit is the only warmth in a cast otherwise made of obstacles, and that matters more than any line the character could deliver. A burro carries this better than a rubber stamp did — it can be affectionate, which a stamp cannot, and affection is the specific thing the cast was short of.

### D-60 · No character gives deliberately wrong advice
Retires D-39. Pip has no successor in the frontier cast. Hints are correct or absent; a character may be unhelpful in tone, never in content.

**Rationale.** D-39 was a containment rule for a gag that no longer exists, and it should not be quietly carried over onto the Sheriff. The wrong-advice joke needed a character whose incompetence was the point, and the Sheriff's comedy is grudging approval — confident wrong advice from an authority figure reads as the game misleading the player rather than a character being funny, which is exactly the trap D-39 existed to avoid.

**What this costs.** The comic-counterweight role is gone from the launch cast, and the reaction triggers that fired on it — long pauses and technique unlocks — now go to the Sheriff in a dry-approval register. If playtesting shows the cast is short of a foil, add one as a fifth character with its own decision, rather than reopening this one.

### D-61 · Ace's jailhouse tally is cosmetic only
Supersedes D-41. Mistakes accumulate as scratch marks on the jailhouse wall, visible on the map screen and growing across the season, but never affect difficulty, rewards, or progression.

**Rationale.** Unchanged from D-41. It is a running visual gag, not a punishment mechanic, and the moment it carries consequence it violates the non-punitive principle (D-03) and turns comedy into a source of anxiety. The clean-solve release — Biscuit kicking the wall and knocking marks off — gives the tally a satisfying discharge without ever making it a threat.

### D-62 · Loading and transition screens carry telegrams and newspaper notices
Supersedes D-43. A pool of several hundred one-line frontier notices.

**Rationale.** Unchanged from D-43: loading time exists whether or not it is used, text-only notices are the cheapest comedy in the product — no art, no animation, no engineering beyond a string table — and a large pool means the repetition that kills most loading-screen humour never sets in. Telegrams also buy a formatting joke the memos did not have, since the clipped STOP-punctuated register is funny before the sentence is read.

### D-63 · The deputy avatar is the primary cosmetics business, ahead of grid themes
Supersedes D-45. The player's deputy is customisable — hats, moustaches, badges, kerchiefs — as flat 2D layers on a single rig, feeding the wanted-poster wall in the cabinet.

**Rationale.** Unchanged from D-45. Players see their own deputy constantly — on the map, in the cabinet, in every wanted-poster portrait — whereas a grid theme is a background they stop consciously noticing within a week. Avatar parts are markedly cheaper to produce than a fully themed grid, so the margin is better on the item players value more. Grid themes remain, but as season rewards rather than the main store.

### D-64 · The subscription is the Deputy Badge
Renames the Bureau Card in D-27. Pricing, trial length, and the full benefit list are unchanged: $4.99 monthly or $29.99 annually, seven-day free trial.

**Rationale.** Name only, for consistency with D-56. A badge is also a better object than a card for the thing being sold — it is worn rather than filed, which is closer to what a subscription to this game actually is.

### D-65 · The palette is sourced from the frontier, not chosen for pleasantness
Supersedes D-54. Bone and sand for surfaces, badge gold for focus and reward, night indigo for candidates, turquoise for provisional marks, sunset red for errors and Ace, cactus green for completed units.

| Colour | Reserved for |
|---|---|
| Bone / sand | Surfaces only |
| Badge gold | Selection, focus, reward, progress |
| Night indigo | Candidate notes and highlighting |
| Turquoise | Provisional notes only |
| Sunset red | Errors, duplicates, Ace |
| Cactus green | Completed rows, columns, blocks |

**Rationale.** The method is D-54's and is the load-bearing part: palettes picked for general pleasantness converge on the same warm cream and pastel accents, because that is what "friendly" defaults to, whereas deriving colour from the world's own materials produces combinations nothing else in the category uses. Only the world changed. Bone and sand under a night-indigo ink is as distinctive as ledger paper under carbon violet was, and it ties the palette to the setting so seasonal repaints stay coherent.

The role assignments are deliberately preserved from D-54 hue for hue — gold sits where ochre sat, indigo where carbon violet sat, and so on — so that D-53's one-hue-one-job discipline and any work already done against the old tokens carry over by renaming rather than re-deciding. D-55 continues to apply: season themes may repaint surfaces and props, never these state colours.

---

## The perk economy

### D-66 · Stamps are an earned-only perk currency, never purchasable
Stamps are awarded for play and spent on assists. There is no coin store, no
Stamp bundle, and no way to convert money into Stamps at any price. This refines
D-23 rather than reversing it.

| Earned for | Stamps |
|---|---|
| Completing the daily challenge | 2 |
| Solving a puzzle with no mistakes | 3 |
| Reaching a 7-day streak milestone | 10 |
| Opening a chest node | 12 |
| Defeating a boss node | 20 |

A season yields roughly 200–250 Stamps for a player who finishes the map and
keeps a daily habit, which is comfortably more than the perk catalogue in D-67
costs to use freely.

**Rationale.** D-23's argument is against a *purchase* layer: it obscures price,
invites predatory patterns, and costs real balance work. None of that applies to
a currency that money cannot reach. What remains is a pacing tool — the game
needs some scarcity for an assist to feel earned, and the non-punitive rule
removed every other source of tension. Scarcity in the *assists* is legitimate;
scarcity in *play* is what the ten constraints forbid.

Subscribers already receive unlimited hints and auto-notes under D-27, so Stamps
must never become the sole route to any assist, or the subscription turns into a
paywall over a mechanic rather than a convenience.

**What breaks if reversed.** Nothing structural — the perks can revert to
permanent unlocks gated by rank. But if Stamps are ever made purchasable, D-23 is
reversed rather than refined, constraint 10 falls, and the positioning line that
competitors cannot copy is no longer true.

### D-67 · Hints are metered per puzzle; perks are spent, never required
Every puzzle includes **one free hint**. Beyond that, a hint costs Stamps or a
rewarded video. Subscribers are unlimited (D-27, unchanged).

| Perk | Stamps | What it does |
|---|---|---|
| Hint | 3 | Names the next logical step and the technique that produces it |
| Auto-notes charge | 4 | One auto-notes fill |
| Reveal a cell | 5 | Fills one chosen cell with its correct value |
| Scan a unit | 8 | Marks which candidates in one chosen unit are eliminable |
| Digit sweep | 12 | Reveals every remaining cell where one chosen digit belongs |
| Solve a row | 15 | Completes one chosen row |

**Running out of Stamps never blocks play.** No puzzle becomes unsolvable, no
node locks, no attempt ends. A player with zero Stamps has the full grid, the
complete notes system, one hint per puzzle, and rewarded video if they want more.
This is the boundary that keeps D-67 inside constraint 1.

**Digit sweep is deliberately distinct from candidate highlighting.** Highlighting
(D-13) is free, always on, and shows where a digit is *already* marked or placed.
Digit sweep reveals where it *belongs*, which is solving rather than surfacing.
Charging for the free feature would be indefensible; charging for the stronger one
is not.

**Rationale.** The non-punitive rule removed lives, energy, timers, and failure
states, which also removed every source of tension the category normally relies
on. Metering the assists restores a decision — *is this puzzle worth a Stamp?* —
without putting anything at risk. The player never loses; they only choose.

One free hint per puzzle rather than zero matters more than it looks: a new player
with no Stamps and no earned balance must still be able to get unstuck on their
first Marshal-rank grid, or the difficulty ramp becomes a wall exactly where the
technique tutorials are meant to carry them.

### D-68 · Cloud sync is free for any signed-in player, not a subscriber benefit
Cross-device sync and recovery after reinstall come with a Cognito account, at no
cost. The Deputy Badge no longer lists cloud save; its benefit list is otherwise
unchanged from D-27 as amended by D-64.

**Rationale.** Three reasons, in order of weight.

It resolves a live contradiction. `docs/SPEC.md` listed cloud save as a Deputy
Badge benefit while `docs/TECH_STACK.md` §2a granted sync to any signed-in
player. Two documents disagreeing about who gets a feature is the kind of thing
that ships as a bug.

Gating *backup* behind a subscription reads as punitive in a product built on not
being punitive. Losing a season and a 200-day streak to a lost phone is exactly
the class of loss D-03 exists to prevent, and charging to prevent it converts the
non-punitive positioning into a sales pitch. The one line competitors cannot copy
is that this game does not punish you; a paywall over recovery undercuts it.

It is close to free to operate. Small last-write-wins documents on DynamoDB
on-demand cost pennies at this scale (`docs/TECH_STACK.md` §2), so almost nothing
is given away in margin.

There is also a funnel argument. Sync is the strongest reason to create an
account for the large majority who will never subscribe, and accounts are what
make entitlement follow the player across platforms (§3a). Putting sync behind
the subscription suppresses sign-in among exactly the players whose retention it
would most improve.

**What the subscription loses, and why that is acceptable.** D-27's own rationale
names the season pass inclusion as the load-bearing benefit — nine seasons a year
at $4.99 standalone against $29.99 annually. Cloud save was never carrying the
price. The daily archive and the per-technique statistics remain the benefits
aimed at the serious solver, who is the likely subscriber. No replacement benefit
is invented here; if the subscription later needs shoring up, that is its own
decision with its own rationale.

**What breaks if reversed.** Nothing technical — the same Cognito and DynamoDB
path serves either model, and the entitlement check is one condition. But
reversing it restores the contradiction this decision exists to close, so the
reversal must also amend `docs/TECH_STACK.md` §2a rather than leaving it.

---

## Build and release

### D-69 · The bundle identifier is `com.alreuter.dokuduty`, with suffixed flavours
`com.alreuter.dokuduty` for `prod`, `com.alreuter.dokuduty.staging` for
`staging`, and `com.alreuter.dokuduty.dev` for `dev`. This is
`dokuduty.alreuter.com` in reverse-DNS form. Minimum OS versions are fixed at the
same time: iOS 15 and Android 8.0 (API 26), as stated in `openspec/project.md`.

**Rationale.** Nothing in the documents decided this, and `setup-mobile-foundation`
cannot create the Android `applicationId` or the iOS bundle identifier without
it. It is recorded here rather than left inside a change directory because that
directory is archived, and the identifier outlives it — every store record,
signing certificate, provisioning profile, RevenueCat app entry, and push
certificate is keyed to it.

Suffixes rather than three unrelated identifiers keep the three flavours related
in the consoles and let `prod` carry the clean identifier, which is the one a
player ever sees.

**What breaks if reversed.** Before store registration, nothing — it is a
find-and-replace across two build files. After registration it is not a rename
at all: a new identifier is a new app, with a new store listing, no reviews, no
ranking history, no install base, and no upgrade path for existing players. That
asymmetry is the entire reason it is decided now rather than when the first build
is uploaded.

### D-70 · Hardware verification moves to change 34 rather than holding the foundation open
The five verification steps in `setup-mobile-foundation` that need a physical
device, a Sentry account, or signing certificates move to
`add-store-release-pipeline` (backlog change 34). The foundation archives with
its implementation complete and those steps recorded as inherited, not as done.

**Rationale.** `openspec/BACKLOG.md` says change 1 blocks everything, and it
does — all 33 remaining items depend on it. Every task left open in it was a
verification step rather than a line of code: cold start on a mid-tier Android
device, rotation on a real iPhone, a live Sentry event, an iOS signed archive,
and an accessibility check on a screen that has nothing to scale. None of them
can change what the foundation *is*; they can only confirm it. Holding two
milestones of work hostage to hardware that is not currently available trades a
real cost for a bookkeeping one.

Change 34 is the right home rather than a new change. It already owns the
release checklist, it already depends on real devices and real certificates, and
it is already the last gate before submission — which is the honest deadline for
"has anyone actually measured this?"

**What this costs, stated plainly.** The cold-start requirement in the
`platform-shell` delta spec archives into `openspec/specs/` as intent with no
measurement behind it. That is a real gap and it is why it is written down here
rather than left implicit. It is also the only requirement in the foundation in
that position — the flavour identifiers, the offline first frame, the
orientation rules, and the crash reporter's silence were all verified.

**What breaks if reversed.** Nothing technical. Reversing it means reopening
change 1 and blocking changes 2 and 3 until a mid-tier Android device, an iOS
device, a Sentry account, and signing certificates are all available at once. If
that hardware appears before change 34 is reached, doing these checks early is
strictly better than waiting — the move sets a deadline, not a schedule.

---

## The token API

### D-71 · The palette is eight tokens — six carrying state, two surfaces
Amends D-53. The principle is unchanged: state colour is reserved before
decoration, and decoration draws from the same set. Only the count is corrected,
and `docs/DESIGN.md` §1 is the canonical list of values.

| Token | Carries |
|---|---|
| `bone` | Surface — grid cells, cards |
| `sand` | Surface — page background, ground shadows |
| `duskInk` | State — outlines and primary text |
| `badgeGold` | State — selection, focus, reward, progress |
| `nightIndigo` | State — settled notes and candidate highlighting |
| `turquoise` | State — provisional notes |
| `sunsetRed` | State — errors, duplicates, Ace |
| `cactusGreen` | State — completed units |

There is no ninth hue. Pale tints, depth shades, and on-colour text values are
derived from one of these eight and are not independently meaningful, so they do
not add to the count and cannot be used as a route around it.

**Rationale.** Four documents stated this number four different ways, and one of
them contradicted itself. `docs/DESIGN.md` said eight tokens, six state and two
surfaces, with hex values. `openspec/config.yaml` and `openspec/project.md` said
six state colours and then listed *surface* as one of the six, which is a
different six. `docs/SPEC.md` §9.8 said five, never a sixth. D-53 said five
states and then forbade a seventh hue.

None of them disagreed about the actual colours or their roles — the roles have
been stable since D-54 and survived the rename in D-65 unchanged. What differed
was only whether the ink and the surfaces were being counted. That is a
bookkeeping error, but it is an expensive one here: `add-design-system` exists to
make an extra hue impossible to add, and a rule that cannot state its own number
cannot be enforced by a test.

`docs/DESIGN.md` wins because it is the newest, the most precise, and the only
one carrying values. The other three are corrected to it in the same change.

**What breaks if reversed.** Nothing in the product. The count is a description
of a palette that is not changing. But the enforcement test asserts a number, so
reverting the wording without reverting the test leaves a document that
disagrees with the build — which is the condition this decision exists to end.

### D-72 · Four palette values are corrected for measured contrast
Amends the values in `docs/DESIGN.md` §1. Hue and role assignments are untouched
— only luminance moved, and D-65's assignments stand exactly as written.

| Token | Was | Now | Why |
|---|---|---|---|
| `turquoise` | `#2AA39A` | `#1B6661` | 2.21–2.70:1 on the five cell backgrounds; needed 4.5:1 at 11px, and again under simulated protanopia, deuteranopia, and tritanopia |
| `inkSoft` | `#6B5F73` | `#64596B` | 4.08:1 on `sand`; needed 4.5:1 at 12px |
| `sunsetRed` on-colour | `#5C1409` | `#3D0D06` | 3.63:1; needed 4.5:1 at 12px |
| `cactusGreen` on-colour | `#123A1E` | `#0E2D17` | 3.87:1; needed 4.5:1 at 12px |

**Rationale.** The palette was never measured. `add-design-system` measured it,
because a token API that cannot state its own contrast budget cannot enforce one,
and four pairs failed WCAG AA at the sizes they are actually used at.

The correction is luminance-only and deliberately minimal — each value is the
first step darker that clears its budget, not a redesign. Two of the four are
on-colour text values that no one sees except as a label on a coloured chip.

The interior `hairline` at 1.33:1 on `bone` was measured and deliberately left.
It is not text, and cell separators are not what a solver reads structure from —
the 3px outer contour and the 2.5px `duskInk` box dividers carry that at 12.44:1.
Darkening the hairline to 3:1 would make the grid read as a table, which is what
D-51 exists to prevent.

**What breaks if reversed.** The four pairs go back below AA, and the enforcement
test in the token layer fails, which is the point of having it.

### D-73 · Provisional notes carry an underline, not colour alone
Supplements D-11. A **provisional note** is drawn in `turquoise` *and* underlined;
a **settled note** is `nightIndigo` with no rule. The one-action clear in D-11 is
unchanged.

**Rationale.** D-11 separated the two note inks by hue alone, and measurement
showed hue cannot carry it. Once `turquoise` is dark enough to be legible on a
cell (D-72), the two inks sit **1.33:1 apart in normal vision and 1.07:1 under
deuteranopia** — at which point they render as the same dark blue-grey and the
distinction is gone for roughly one in twelve men.

The conflict is structural, not a bad colour pick: the provisional ink must be
dark to be legible at 11px, and dark is where the settled ink already lives.
Nothing in the cool half of the wheel resolves that, and the warm half is spoken
for by focus, error, and completion.

This was already a constraint-5 violation before the contrast fix — at 2.19:1
under deuteranopia the original pairing was not distinguishable either. The rule
"colour is never the sole signal for any state" applies to the two note kinds
exactly as it applies to completion, which has carried a corner mark since D-50.
The measurement is what made a long-standing gap visible.

**Why an underline.** It survives at 11px, where a hollow or outlined glyph does
not. It does not move the digit, so the fixed 3×3 positional arrangement in D-10
is untouched and notes still never reflow. It costs one line per note on a canvas
that is already drawing per-cell. Italic was rejected because the bundled UI face
is not guaranteed to carry a true italic and a synthesised slant is not a reliable
signal.

**What breaks if reversed.** Provisional notes become unreadable as a distinct
state for colourblind players, and the one-action clear in D-11 becomes a control
whose effect the player cannot predict.

### D-74 · The UI face is Nunito, chosen on its 11px aperture
Bundled as three static weights (400/500/600) under the SIL Open Font License,
about 380KB. Not fetched at runtime.

| Candidate | Verdict |
|---|---|
| **Nunito** | Chosen. Widest counters and clearest digit separation at note size |
| Fredoka | Rejected. The best match to "rounded and slightly condensed" and the smallest files, but its apertures close at 11px, which is the size that matters |
| Baloo 2 | Rejected. Loose vertical metrics fight the fixed 3×3 note slots, and 1.25MB for three weights |

**Rationale.** `docs/DESIGN.md` §2 asked for a face that is rounded, slightly
condensed, and carries real weight contrast. No open-licensed face does all
three well, so one had to give, and the test that decides it is not the specimen
sheet — it is nine digits at **11px**, which is where a rounded face either holds
its counters or fills them in. A sudoku app is a typography application wearing a
game's clothes; the note is the smallest and most-read glyph in it.

Nunito is not condensed. That is the deviation, and it is the cheap one: width
costs a little horizontal room in a five-column pad, whereas a closed aperture
costs legibility in the one place the player is doing the actual work. §2 is
corrected to match rather than left to disagree with the build.

`google_fonts` was rejected outright. It resolves over the network by default,
and the first frame must render on a fresh install in airplane mode.

**What breaks if reversed.** Swapping the face changes every text metric, so the
type goldens regenerate and anything laid out against note size is re-measured.
Cheap now, expensive once the grid exists.

### D-75 · The design system's on-device checks move to change 6, not change 34
The four device verifications in `add-design-system` that need something on
screen — the six type roles, the pressable's feel, the tilt's stability, and the
haptic vocabulary — move to `add-grid-and-input` (backlog change 6). The surface
and grain checks were done here, on both platforms.

**Rationale.** This is D-70's situation with a different destination. The
foundation's accessibility check moved because an empty screen has nothing to
scale; these move because an empty screen has nothing to *press, read, or feel*.
The proposal deliberately excludes a debug gallery route, so nothing in this
change renders a glyph in any of the six roles, draws a button, or fires a
haptic. A device run confirms the surface token and the paper grain, and both
were confirmed on both platforms — it cannot confirm the rest, because the rest
is not on screen.

Change 6 rather than change 34 is the right home. It is the first change that
draws text at grid-value and note size, the first with a number pad made of
pressables, and the first to fire a haptic on a placement. Deferring to the
release pipeline would mean the type scale went eleven changes without anyone
looking at it, and the whole reason Nunito was chosen over Fredoka is a
legibility judgement that ought to be confirmed on glass.

**What this leaves unproven.** The type scale, the primitives, and the haptics
are covered by widget tests and goldens only. Goldens are rendered by the test
host, not by a device, so they prove the values are wired correctly and prove
nothing about how the face looks at 11px on a real panel or how the press feels
under a thumb. That is a real gap and it is why it is written down.

The haptic line carries a second, independent blocker: the connected iPhone
cannot be codesigned, because no `DEVELOPMENT_TEAM` is configured in the Xcode
project. That is the same obstacle D-70 recorded and it has not moved.

**What breaks if reversed.** Nothing technical — the alternative is a debug
gallery route to look at, which the proposal excluded on scope grounds. If that
exclusion is reconsidered, these checks come back here and close immediately.

---

## The local database

### D-76 · Timestamps are stored as ISO-8601 text, not unix seconds
Drift's `store_date_time_values_as_text` is enabled from schema version 1.

**Rationale.** Drift's default stores a `DateTime` as unix **seconds**, with no
timezone and no sub-second component. Both halves of that are wrong for this
schema, and neither is obvious until sync exists.

Seconds cannot order two writes made inside the same second. Note state is
written on every change (D-33), and a player marking a dense board makes several
changes a second, so a last-write-wins merge would be resolving genuine
conflicts by whichever row the query happened to return first. The player would
see notes reappear or vanish after a sync, with nothing in any log to explain it.

The missing timezone is the smaller problem but the more embarrassing one: two
devices in different zones comparing stamps is the ordinary case for the feature
these columns exist to serve.

Set now because changing it later is a data migration over live saved games —
drift documents it as a schema change needing special care — and avoiding
exactly that migration is why the sync columns were added at version 1 rather
than when sync ships.

**What this costs.** Text stamps are larger than integers and marginally slower
to compare. At this volume — a few thousand rows on a phone — the difference is
not measurable, and it buys stamps that are readable when someone is debugging a
save that went wrong.

**What breaks if reversed.** Before release, nothing: regenerate and the schema
changes. After release, it is a migration over every timestamp in every player's
database, which is the highest-risk kind of migration this app can have.

### D-77 · Drift is held on the 2.31.x line, with `sqlite3_flutter_libs`
`drift ^2.31.0`, `drift_flutter ^0.2.8`, `sqlite3_flutter_libs ^0.5.0`. Not the
newest, and pinned on purpose.

**Rationale.** From drift 2.32 the dependency moves from `sqlite3` 2.x to 3.x,
and `sqlite3` 3.x replaced the old bundling with Dart **build hooks**. On the
Flutter version this project builds with, the hook produces the library into
`build/app/intermediates/flutter/<variant>/native_assets/jniLibs/lib/<abi>/` and
Gradle packages from `jniLibs/<abi>/` — one directory shallower. The result is an
APK with no `libsqlite3.so` in it, and an app that throws
`dlopen failed: library "libsqlite3.so" not found` the first time it opens the
database.

Adding `sqlite3` as a direct dependency did not help, and neither did
`flutter config --enable-native-assets`. The 2.31 line bundles through
`sqlite3_flutter_libs`, which is ordinary Gradle and CocoaPods and works.

**How this was found, because the method matters more than the fix.** Every one
of the 227 host tests passed with the broken configuration, and they always
would have: the test host links macOS's own sqlite, so the missing Android
library is invisible there. It took an `integration_test` running on an emulator
to see it. That is the argument for keeping such a test in the suite — this
class of defect is undetectable from the host and would have shipped as "the app
cannot save anything on Android".

**What this costs.** Being three minor versions behind on drift, and carrying a
package the newer line has retired. Both are cheap. Losing every saved game on
Android is not.

**What breaks if reversed.** Moving to drift 2.32+ without confirming the hook
output reaches the APK reintroduces a total loss of persistence on Android. The
check is one command: build the APK and
`unzip -l ... | grep libsqlite3`. If it is absent, the app is broken however
green the tests are.

### D-78 · The database lives in Application Support, not Documents
`driftDatabase` is given an explicit `databaseDirectory` of
`getApplicationSupportDirectory`.

**Rationale.** `drift_flutter` defaults to the *documents* directory. On iOS that
is user-facing space: it is backed up to iCloud, and an app that ever enables
file sharing exposes its contents in the Files app. Apple's guidance reserves it
for documents the player created and made. A sqlite save file is app data, and
Application Support is where the OS expects it and knows not to show it.

The default is not dangerous today — nothing in this app enables file sharing —
but it is the kind of default that becomes a problem in a later change made by
someone who has no reason to look at where the database lives.

**What breaks if reversed.** Nothing immediately. After release it is worse than
nothing: the file would move, and a player upgrading would find an empty cabinet
unless the change also migrated the old path. That is why it is set now.

### D-79 · Backlog items inserted between two changes take a letter, not a renumber
A change added between existing items 5 and 6 is numbered `5a`. Existing numbers
never move.

**Rationale.** `add-puzzle-generation` had to go between `add-puzzle-engine` and
`add-grid-and-input`, and inserting it as a new 6 would have renumbered
twenty-nine items. Numbers are cited from outside the backlog — the proposals
say "change 19 is where a hint has to answer while a player waits", the code
comments say "generation and grading are change 5's business", and
`docs/TECH_STACK.md` refers to items by number too. A renumber silently makes
every one of those references point at the wrong change, and nothing fails when
it does.

Letters are ugly and that is the point: `5a` reads as an insertion, which is what
it is. The alternative — renumbering and then hunting every citation — is work
proportional to the size of the backlog, repeated on every insertion.

**What breaks if reversed.** Nothing visibly, which is the danger. Every
cross-reference by number becomes wrong, and the first symptom is somebody
implementing the wrong change.

### D-80 · The engine's technique corpus is found by a throwaway search, and the tool is not kept
The twelve corpus puzzles in
`test/features/puzzle_engine/support/corpus.dart` were found by a script that
generated solved grids, removed clues while the exhaustive uniqueness check still
reported one solution, and kept the first puzzle whose hardest required technique
was each of the twelve. The script was deleted once the corpus was baked in.

**Rationale.** `add-puzzle-engine` deliberately ships no generator (its proposal
says so, and `add-puzzle-generation` now owns that). But a corpus of twelve
puzzles that *provably* require one named technique each cannot be recalled from
memory and cannot be hand-built at that count. Finding them needs the same loop a
generator uses, so the loop was written, used once, and removed rather than
becoming a shipped capability nobody proposed.

What survives is the evidence rather than the tool: each entry carries the exact
deduction no easier technique can reach — the cells, the digits, its position in
the solve — and `corpus_test.dart` re-derives every claim from scratch. It checks
uniqueness by the exhaustive search, solves each entry with the ladder cut to its
**rank**, and asserts it stalls with the technique withheld.

**The circularity is real and bounded.** The corpus is found by the engine and
checked by the engine, so a technique that is wrong in the same way twice would
not be caught here. The one independent judgement in the loop is the exhaustive
uniqueness check, which shares no code with the technique solver — the reason
those two questions are answered separately in the first place (constraint 8).
The isolation tests carry the rest of the weight: each technique is asserted to
say *nothing* on a position it does not apply to, which is the direction the
failure would come from.

**What breaks if reversed.** Keeping the tool would have put a generator in the
repo two changes before one was proposed, with no spec and no tests, and the
first real pack would have been tempted out of it.

### D-81 · Where test-first is not followed, a mutation pass stands in for it
The twelve solving techniques were implemented before their tests, contrary to
the test-first rule for the load-bearing pure-logic systems. Each technique was
then mutated to deduce nothing, and its tests were required to fail. All twelve
did.

**Rationale.** Recorded rather than quietly skipped, because the rule exists for
a specific reason: the puzzle engine is on the test-first list in
`openspec/config.yaml`, and a technique that is subtly too eager grades puzzles
*easier* than they are — a symptom nobody reports as a bug. What test-first buys
there is the guarantee that the test can actually fail. Writing the tests
afterwards forfeits that guarantee, and mutation testing buys it back directly:
a test that still passes against a neutered implementation was never testing
anything.

This is not a licence to stop writing tests first. It is the repair when it has
not happened, and it is weaker in one respect worth naming — test-first also
shapes the interface around what a caller needs, and no mutation pass recovers
that.

**What breaks if reversed.** Nothing mechanical. The cost of dropping the
mutation pass without the ordering is a suite that looks green and asserts
nothing, which is worse than no suite at all, because it is trusted.

### D-82 · A shipped puzzle carries at most forty clues
No **pack** ships a puzzle with more than forty givens, at any **rank**.

**Rationale.** The generator digs clues out of a solved grid one at a time and
every intermediate is a uniquely solvable, honestly gradable puzzle — including
the eighty-clue grid that is one full house from finished. Measurement during
`add-puzzle-generation` found Greenhorn spanning 26 to 80 clues, which would have
filled most of the shipped pack with grids nobody would call puzzles while
passing every test then written. Nothing in the proposal or the tasks had named a
floor, because the problem is invisible until the distribution is looked at.

Forty is the top of the ordinary easy-sudoku range. A Greenhorn puzzle at 26 to
40 clues still needs nothing harder than a full house or a naked single, so the
gentlest rank stays gentle without becoming trivial.

**Where it is applied matters.** The ceiling filters *selection*, not the dig, so
a seed still names the same puzzle whatever a given run was selecting for. Moving
it into the dig would silently change what every existing seed means, and the
seed is what makes a shipped pack re-derivable.

**What breaks if reversed.** Nothing mechanical — the pack would still be unique,
still correctly graded, still pass the audit. It would just be full of grids a
player finishes in four taps, and the first rank a new player meets would be the
one that taught them the game is not worth playing.

### D-83 · The engine's no-Flutter rule is scoped to `domain/`, and that is the layout
Pure logic lives in `lib/features/<capability>/domain/` and carries no Flutter
import. `data/` and `application/` may.

**Rationale.** `add-puzzle-engine` asserted that *no* file under
`lib/features/puzzle_engine/` imports Flutter, which was true while the capability
was nothing but arithmetic. `add-puzzle-generation` had to read a bundled asset,
and reading an asset needs Flutter's bundle. The alternative was putting
puzzle-engine code inside the persistence feature, which trades a real rule for a
misfiled capability.

The rule that was worth keeping is the one about the pure core — the solver, the
grader, the uniqueness check, the generator, and the pack format are unit-testable
by the plain runner and cannot acquire a platform behaviour. All of them are under
`domain/`, so scoping the assertion there loses nothing. This is also just the
feature-first layout the project already used everywhere else; the original test
was stricter than the convention by accident, not by design.

The test now also names `pack.dart` and `generator.dart` individually, because a
directory-scoped rule is defeated by moving a file out of the directory, and those
two are what the offline tool runs outside a device.

**What breaks if reversed.** Widening it back to the whole feature means the
bundled pack cannot be read, and the first workaround anyone reaches for — a
loader in another feature — puts content-loading in the persistence layer where
nobody will look for it.

### D-84 · The 44pt minimum is a control floor, not a grid-cell floor
Amends `docs/DESIGN.md` §8, which stated it as a grid rule. The grid takes the
width available and divides it by nine; buttons and number-pad keys keep the 44pt
minimum absolutely.

**Rationale.** Nine 44pt cells need 396 logical pixels of grid before any gutter,
and most phones in the market do not have it: an iPhone SE gives 39pt cells with
a 12pt gutter, a Pixel 7 gives 41pt, and only the largest handsets clear 44pt.
The rule as written could not be met on the devices this ships to, and a rule
nobody can meet is not followed carefully — it is ignored, and then so are the
rules next to it.

Holding 44pt absolutely would mean a grid wider than the viewport, scrolled or
clipped. A sudoku grid the player cannot see all of is not a sudoku grid: the
whole skill is scanning rows, columns, and blocks against each other, and that
needs the board in one view more than it needs a comfortable target.

The 44pt figure comes from Apple's guidance for discrete controls, where a miss
costs an unintended action. A grid cell is different in kind — a mis-tap selects
the neighbouring cell, is visible immediately, and is corrected by tapping again
with nothing placed and nothing lost. The number pad is where a miss actually
costs something, and that is where the floor is kept.

**What breaks if reversed.** Restoring it as a grid rule makes the layout
impossible on the most common devices, so it would be quietly broken everywhere
instead of deliberately amended here.

### D-85 · The widget tree may read the database, but never before the first frame
Refines the rule `add-persistence-layer` established. The guarantee is about the
first frame specifically, not about the widget tree for all time.

**Rationale.** `appDatabaseProvider` was built lazily so that nothing on the path
to a rendered screen opens the file, and `lazy_open_test` enforced it by pumping
two frames and asserting the database was never constructed. That was exact while
the home screen was an empty placeholder that read nothing.

`add-grid-and-input` replaced it with the rank picker, which has to know which
puzzle is next at each **rank** — and that lives in the database. The picker
paints its six rows from `Rank.values`, which needs nothing, and reads the pack
from a post-frame callback. That is the same discipline the config refresh
follows, and it satisfies the rule as the provider's own doc comment states it:
*"as long as nothing on the first-frame path watches this, opening the file
happens after the app is already on screen."*

The test now asserts both halves — zero opens on the first frame, exactly one
after — rather than only the first. Pinning the second half matters as much: a
future change that moves the read back onto the first frame fails the first
assertion, and one that removes the read entirely fails the second, so neither
can happen quietly.

**What breaks if reversed.** Reading it again as "the widget tree never opens the
database" makes any screen with content unbuildable, and the workaround anyone
reaches for — loading content from `bootstrap` and pushing it down — puts
content-fetching in the startup path, which is the thing the rule was protecting.

### D-86 · Everything that reads the shipped pack awaits one shared install
`packInstallationProvider` is a `FutureProvider` that installs the bundled
**pack** exactly once. Every reader — the **rank** picker, the puzzle opener,
and anything added later — awaits it before its first query. `bootstrap` starts
it through that provider rather than calling the installer.

**Rationale.** Found by running the app rather than by reading it. The install
and the first screen both start after the first frame, deliberately, so neither
sits on the cold-start path. Without a rendezvous they raced: the picker queried
the six **rank**s with sequential awaits while the install transaction was still
open, saw an empty table for the first two, reported *nothing left here for now*,
and never asked again. On a fresh install, with three hundred puzzles in the
binary, a new player was told the two easiest **rank**s had no content.

Every test passed. They each seeded the database before pumping, so the ordering
they were testing did not exist — which is the general lesson: a test that
arranges its state up front cannot catch a defect in how that state arrives.

**Why a rendezvous rather than a refresh.** Invalidating the reader when the
install finishes would also work, and would leave the race in place with a
repaint papered over it. Awaiting removes it: there is no window in which a
reader can see a half-installed pack, so there is nothing to recover from.
"Knowing nothing" and "knowing there is nothing" stay distinct, which is what the
player-facing message depends on.

**What breaks if reversed.** The same silent wrong answer, on first launch only,
which is the launch that decides whether a player opens the app again. Any new
reader of the pack that forgets to await this reintroduces it for itself —
`test/features/grid_input/first_launch_test.dart` is what catches that, and it
uses a deliberately slow **pack** source so the race fails every run rather than
on an unlucky morning.


### D-87 · Auto-notes unions with what is already marked; it never replaces it
Filling every empty cell with its legal candidates adds what is missing and
leaves what is there. A candidate the player marked keeps its slot and stays
theirs, including one the fill would not have offered. A legal candidate the
player had *eliminated* comes back.

**Rationale.** The three options were union, replace, and fill-only-empty-cells,
and each loses something. Replace is truest to the name and gives the cleanest
board, but it discards hand-marked work — including a candidate the player put
somewhere the fill disagrees with, which is exactly the thinking the technique
ladder is meant to reward. Fill-only-empty-cells protects deliberate
eliminations, but it returns a half-filled board: the player asked for a
candidate grid and got a mixture, which is harder to read than either extreme
and impossible to reason about, because a blank cell no longer means the same
thing everywhere.

Union loses one thing — eliminations the player had made by hand in a cell they
went on to work in. That loss is bounded and visible: the returning candidate
is in its slot where they can see it, and the whole fill is a single undo away.
The other two options lose something the player cannot see, which is the worse
kind of loss. "Every legal candidate" is what the action promises, so the fill
has to be free to offer one back; making it cheap to reverse is what keeps that
honest.

**What breaks if reversed.** Under replace, a player who has spent twenty
minutes eliminating candidates and then taps the fill out of curiosity loses all
of it, and — because both boards look plausible — may not notice until the
deductions stop working. Under fill-only-empty-cells, the fill silently does
less than it says on a board that has been touched at all, which is every board
worth filling.

### D-88 · Candidate highlighting is derived, not a third piece of state
The digit **candidate highlighting** lights cells for is the digit held in
digit-first input, or failing that the digit in the selected cell. There is no
separate "highlighted digit" the player sets and clears.

**Rationale.** D-13 says "tapping a digit on the pad highlights every cell
holding it", which reads literally only in digit-first input — in cell-first a
digit tap places a value. The obvious repair is a sticky highlighted digit that a
pad tap sets, but that is a third source of truth needing its own rules for when
it clears: on a selection change, on a mode change, on an undo, on opening a
puzzle. Each rule is a way to leave the wrong digit lit, and a board lit for a
digit the player is no longer thinking about is worse than one lit for nothing.

The two derived sources already clear themselves — a held digit is put down, a
selection moves — so the feature has no lifecycle of its own to get wrong. It
also reaches the same behaviour in cell-first for free: tapping a digit into a
cell leaves that cell selected holding it, so it lights. Selecting a cell that
already holds a digit lights it too, which is what every major sudoku app does
and what players arrive expecting.

**What breaks if reversed.** A fourth state field on the session, and the class
of bug where the pad shows one thing and the grid lights another. The cost of
this decision is that a cell-first player who wants to see every 7 must select a
cell holding a 7 rather than tapping 7 on the pad — one extra tap, on the path
players already use.

### D-89 · The ink is a second axis, not a third value on the notes toggle
The notes toggle stays two-valued — value against note. Which ink note entry
writes is a separate control the player changes independently, and every puzzle
opens in the **settled note** ink whichever one the last puzzle ended in.

**Rationale.** Folding the ink into the notes toggle gives one control three
values: value, settled note, provisional note. That reads as a saving of one key
until long-press is considered. Long-press means "one entry in the opposite
mode" (`docs/SPEC.md` §3.4), and on a three-valued control the opposite of
provisional is two things — settled and value — with no answer that is not
arbitrary. The gesture would have to be dropped, given a rule nobody can
predict, or made to cycle, and cycling on a long-press is the worst of the
three.

Two axes also match what the player is doing. Whether this entry is a value or a
note is a question about *this tap*; which ink notes are written in is a
question about *what they are working on*, and it survives across many taps. A
control that mixes a per-tap choice with a per-session one has to be re-read
before every entry.

Opening in the settled ink rather than the ink the last puzzle ended in follows
the same reasoning as D-11's clear: a hypothesis belongs to the grid that
prompted it. Carrying the provisional ink into a fresh puzzle would have the
player's first candidates arrive as a hypothesis about nothing.

**What breaks if reversed.** Long-press loses its meaning, and a player who
wants one note during a run of values has to make a trip to a control whose
next value depends on where in the cycle they are.

### D-90 · Marking a digit in the other ink converts it rather than removing it
Three outcomes from one control: a digit absent from the cell is marked in the
ink in force, a digit present in that same ink is removed, and a digit present
in the *other* ink is re-inked rather than removed. The candidate never leaves
the slot its digit owns.

**Rationale.** The workflow the second ink exists for is deriving candidates and
*then* testing one of them. A player who has settled candidates in a cell,
switches to the provisional ink, and taps one of them means "take this into the
hypothesis" — every time. Removal would make that common path two taps and a
mode change, and would make the rarer path (removing a candidate while in the
wrong ink) no cheaper than switching ink and tapping, which is what it already
costs.

Converting rather than removing-and-remarking also keeps the origin D-15
records. Ink and origin are separate questions — which of the player and
**auto-notes** first marked a candidate is not the same as which ink it now
carries — and a remove would silently answer the first one wrong.

**What breaks if reversed.** The path the feature was built for becomes the
expensive one, and a **generated note** taken into a hypothesis becomes the
player's own work in the store.

### D-91 · Promote ships alongside clear, not after it
One control turns every **provisional note** on the board into a **settled
note** (**promote**), beside the D-11 control that clears them all. Both are one
action and one undo.

**Rationale.** A chain test ends one of two ways: the hypothesis contradicts
something, or it holds. D-11 shipped the control for the first — one tap to
abandon the line. Without **promote**, the half that *succeeds* is the slower
half: the player must re-enter by hand every candidate they have just proved,
in a cell-by-cell pass with nothing to check it against, which is exactly the
tedium the second ink was meant to remove. The asymmetry would also teach a
subtle lesson — that being right costs more than being wrong — in a product
whose whole positioning is that it does not punish (constraint 1).

It is one action rather than a per-cell confirmation because the player has
already made the decision the moment they know the chain held. A promotion that
asked cell by cell would be the same manual pass wearing a dialog.

**What breaks if reversed.** The successful half of every chain test becomes
hand work, and players stop writing hypotheses down for the same reason they
did before the ink existed.

### D-92 · Grid glyphs grow with dynamic type until they fill their box, then stop
A value's glyph is capped to its cell and a candidate's to its 3×3 slot. Type
below the cap scales normally; above it the glyph holds at the largest size that
fits. The cap is measured at layout — the glyph's width and its em box against
the box it sits in — rather than set as a constant.

**Rationale.** `docs/DESIGN.md` §2 says dynamic type is respected everywhere and
nothing pins a size, and the grid took that literally: `TypeRole.scaled` multiplied
and nothing clamped the result. A sudoku grid cannot honour that promise, because
it cannot reflow — nine columns are nine columns at every text size, and the cell
is the screen width divided by nine (D-84). Uncapped, a candidate's em box passes
its slot at about 1.2× and a value's passes its cell at about 1.8×: ordinary
"Larger Text" settings, not accessibility extremes. The result was not large text
but unreadable text, digits overlapping their neighbours in every direction.

Capping is a real compromise and worth naming as one: a player at 3× gets digits
about as large as 1.8× would have given them, not three times the default. The
alternative that actually serves them is magnification — the grid drawn larger
than the viewport with pan — and that is a feature with its own gestures, state,
and tests, which `add-accessibility-settings` (change 30) is where the backlog
puts it. Until then the choice is between text that is smaller than asked for and
text that cannot be read at all.

**Why measured rather than a constant.** The ratio between a font size and the box
its glyph fills is a property of the face. A factor tuned to Nunito would be
silently wrong the day D-74 is revisited, and silently wrong here means text that
overflows again with every test still green.

**Why the em box and not the laid-out height.** A laid-out line in Nunito is about
1.36em tall and most of the excess is empty leading: at the default scale a
candidate's line box is already 15px inside a 13.3px slot while the digit itself
sits comfortably. Capping on that number shrinks type that visibly fits. A digit
has cap height and no descender, so its ink is always shorter than its em, which
makes the em a bound that holds without depending on any one face's metrics.

**What breaks if reversed.** The defect returns at the text size a large fraction
of players actually use, and returns silently: the test that should have caught it
asserted the *widget's* size and that no exception was thrown, both of which stayed
true while every glyph inside it overflowed.

### D-93 · A pad key grows with dynamic type until its row is full, then stops
A number-pad key's side is `44pt × the reader's text scale`, capped at the pad's
width divided by its five columns. The 44pt floor outranks the cap: a pad too
narrow to hold five 44pt keys keeps the 44pt keys and lets the row be cut. The
glyph scales with the key rather than with the text size, so a capped key never
holds an uncapped glyph.

**Rationale.** D-92 capped the glyphs inside a grid cell; this is the same
defect one layer out, and it was found the same way — by driving the OS's own
text setting rather than a `TextScaler.linear` a test chose. A row of five keys
cannot reflow any more than a row of nine cells can, and the key side was
`44 × scale` with no ceiling: five keys need 370pt at 1.5×, **480pt at 2×**, and
722pt at 3.1×, against a 393pt phone. 2× is an ordinary "Larger Text" setting,
so the pad ran off the screen for a large fraction of players — silently, since
every test until now supplied its own scaler and its own unbounded surface.

**Why the floor outranks the cap.** `docs/DESIGN.md` §8 keeps 44pt for pad keys
even though D-84 lifted it off grid cells, because this is where a miss costs a
placed digit. Below about 260pt five 44pt keys do not fit, and the choice there
is between a key that cannot reliably be hit and a row that is cut. The narrowest
phone is 320pt, where the cap is 56pt and the floor is never reached — the cut
row is a bound the pad is never actually laid out in.

**Why the glyph follows the key.** A capped key holding a glyph still scaled by
the raw text factor is the same overflow moved inside the button. Deriving the
glyph's scale from the key's achieved side keeps the proportion the key has at
the default size, so a key does not change shape as it caps.

**What breaks if reversed.** The pad runs off the screen from 2× — and does it
without an error a player could report, because what they see is a pad with keys
missing rather than a pad that is too wide.

### D-94 · Strict mode is one switch, and auto-check is retired
The player has one opt-in setting, **strict mode**, and it carries both
behaviours D-04 names: a wrong digit is flagged as it is placed, and the third
**mistake** ends the **attempt**. There is no separate auto-check. The
`AppSetting.autoCheck` key that stood beside it from `add-persistence-layer` is
removed; a row left on disk under that key is inert.

**Rationale.** D-04 already describes one thing — "strict mode, which flags
errors immediately and caps mistakes at three" — but the storage layer shipped
two keys, and two keys is a promise of four states. Two of them are incoherent:
a cap with no flagging tells a player they have failed without ever telling them
why, and flagging with no cap is the competitor behaviour this product exists to
be unlike, one tap away from every new player who goes looking through settings.

The half-state that *sounds* reasonable — flagging without stakes — is the one
worth refusing deliberately. It is the most requested sudoku feature and the
most corrosive: a player who can see their errors stops looking for them, and
looking for them is the skill the six-**rank** technique ladder is built to
teach. Anyone who wants that trade can have it, and takes the three-**mistake**
cap with it, which is exactly the deliberate act D-04 asks for.

A stored setting nothing reads is worse than no setting at all. It survives
sync, appears in exports, and reads to the next developer as a feature that was
finished.

**What breaks if reversed.** Two settings, four states, two of which need their
own copy, their own tests, and their own answer to "what does long-press do" —
and the most dangerous default in the product becomes reachable without the
thing that makes it a deliberate choice.

### D-95 · The third mistake locks the board and offers a fresh start
In **strict mode** the third **mistake** ends the **attempt**: input stops, the
board stays on screen, and the player is offered the same puzzle from the start
or a route back to the map. The **attempt** cannot be continued, and nothing
sells a way back into it.

**Rationale.** Three options were real. Returning straight to the map is
cleanest to build and worst to receive — a player forty minutes into a Marshal
grid is shown a map and never gets to see what went wrong. Letting them drop
**strict mode** and keep the board is the kindest and makes the cap advisory,
which removes the stakes the player deliberately turned on; a limit that
dissolves when reached is not a limit, and the mode's only reason to exist is
that it is real.

Locking and keeping the board is the middle, and the middle is right here: the
failure is honest, and the player still gets to look at the position, find their
own error, and decide. Constraint 1 is not violated by a failure state the
player switched on themselves — it is violated by one they did not.

**Why nothing is sold at that moment.** A player who has just lost forty minutes
is the most monetisable person in the app, which is exactly why this product
does not monetise them (D-24's spirit, constraint 6). Selling a revive turns the
only failure state into a funnel and turns **strict mode** from a difficulty
option into a purchase prompt.

**What breaks if reversed.** Either the mode stops meaning anything, or the
player loses their board without being allowed to look at it.

### D-96 · A mistake is one wrong placement, and the count never falls
Each placement that disagrees with the solution counts, so the same wrong digit
put down twice counts twice. Correcting the cell, erasing it, and undoing the
placement all leave the count where it was. The only route back to zero is
starting the puzzle again.

**Rationale.** The alternative — one wrong *cell*, counted once — is kinder to a
player fumbling one hard cell, and it makes the number stop matching what the
player saw happen. Ace chalks a mark on the wall for each wrong answer; a tally
that quietly merged them would be describing a different game from the one on
screen.

A count undo could walk back is the more serious version of the same problem. It
would be trivially gameable — place, see nothing happen, undo, try again — and
"solved with no **mistake**s" would come to mean "solved with no **mistake**s
still visible", which is a different and much easier achievement to buy Stamps
with. Undo reverses the board. It does not reverse what happened.

**What breaks if reversed.** The perfect-solve reward stops measuring anything,
and in **strict mode** undo becomes a way to play with no limit at all.
