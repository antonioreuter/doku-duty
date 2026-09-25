# Doku Duty — implementation backlog

Every item below is a proposed OpenSpec change. Create one with:

```
/opsx:propose <change-name>
```

Items are ordered by dependency. Milestones are checkpoints where something real is playable, not phase gates — work ahead where it makes sense.

**Capabilities** (kebab-case, used consistently across all changes):

`platform-shell` · `design-system` · `remote-config` · `puzzle-engine` · `grid-input` · `notes` · `mistake-model` · `completion-effects` · `rank-progression` · `stamps` · `perks` · `technique-tutorials` · `daily-challenge` · `season-map` · `trophy-cabinet` · `character-system` · `running-gags` · `deputy-avatar` · `ads` · `purchases` · `persistence` · `auth` · `cloud-sync` · `analytics` · `localization` · `accessibility`

---

## Status — 2026-09-25

**Twenty changes archived. Milestones 0, 1 and 2 are complete.** Items carry a
**Done** line naming the archive directory they landed
in; anything without one is not built. Six of the finished items — 6, 11, 14,
15, 16 and 17 — still carry an **OUTSTANDING** note; read those before treating the
capability as settled, because what is outstanding in every case is a
*measurement on physical hardware*, not code. One session with a mid-tier
Android phone and a Developer-Mode iPhone closes all of them.

| Milestone | Items | State |
|---|---|---|
| 0 — Foundation | 1–4 | Complete |
| 1 — A sudoku you can play | 5, 5a, 6–11 | Complete |
| 2 — A reason to come back | 12–17 | Complete |
| *(unlabelled)* — the perk economy | 18, 19 | Not started; 18 unblocked |
| 3 — The reason it exists | 20–23 | Not started |
| 4 — The business | 24–29 | Not started |
| 5 — Ship quality | 30–34 | Not started |

**18 and 19 sit under no milestone heading** — they fall between Milestone 2's
last item and Milestone 3's first, and always have. Left as they are rather than
renumbered, for the reason given under 5a: the docs and the code cite these
changes by number.

**Two archived changes are not numbered here.** `add-pad-tools-row`
(`2026-09-19-add-pad-tools-row`) replaced six unlabelled glyph keys with a named
**tools row** after `add-mistake-model` found the pad overflowing, and added
D-100 and D-101. It was corrective work on change 6's surface rather than a
backlog item. `add-trail-path` (`2026-09-20-add-trail-path`) drew the connector
joining the **trail**'s 42 **node**s, which `add-season-map` had left to artwork
and running the built app showed was geometry. Both are recorded here so the
archive and this list can be reconciled.

---

## Milestone 0 — Foundation

*Done when: a signed build installs on both platforms from CI and shows a themed empty screen.*

**Complete.** The one thing it could not verify — cold start, orientation, a real
Sentry event, and a signed iOS archive, all of which need physical hardware and
credentials — was deliberately carried to change 34 rather than holding this
milestone open (D-70).

### 1. `setup-mobile-foundation`
**Done** — `openspec/changes/archive/2026-09-05-setup-mobile-foundation/`.
**Capabilities:** `platform-shell`
Flutter project, iOS and Android targets, flavours for dev/staging/prod, Riverpod, routing, `flutter analyze` and `dart format` in CI, Fastlane lanes for both stores, Sentry.
**Blocks:** everything.
**Watch for:** get the minimum OS versions and bundle identifiers right now — changing a bundle ID after store registration is painful.

### 2. `add-design-system`
**Done** — `openspec/changes/archive/2026-09-05-add-design-system/`.
**Capabilities:** `design-system`
The eight colour tokens — six carrying state, two surfaces — as named tokens, typography scale, corner radii, stroke weights, haptic vocabulary, and a theme structure where seasons can repaint surfaces but not state colours (D-53 as amended by D-71, D-65, D-55).
**Depends on:** 1.
**Watch for:** enforce the "one colour, one job" rule in the token API itself, so a later change physically cannot introduce a ninth hue.

### 3. `add-persistence-layer`
**Done** — `openspec/changes/archive/2026-09-06-add-persistence-layer/`.
**Capabilities:** `persistence`
Drift schemas for puzzle packs, save state, notes, statistics, and settings. Write-on-every-change for note state (D-33). Survives app kill mid-puzzle. (`docs/TECH_STACK.md` §6 replaced Isar with Drift over SQLite; this line said Isar until `add-persistence-layer` corrected it.)
**Depends on:** 1.
**Watch for:** model manual and generated notes as distinguishable from day one (D-15) — retrofitting this means migrating saved games.

---

### 4. `add-remote-config`
**Done** — `openspec/changes/archive/2026-09-06-add-remote-config/`.
**Capabilities:** `remote-config`
Versioned JSON on S3 behind CloudFront with a short TTL, a client fetch with cache and a baked-in fallback, and typed accessors. Carries the ad caps from D-24, season definitions, and any value that must change without a release.
**Depends on:** 3.
**Watch for:** this must land before `add-ads-integration`. The ad caps in D-24 — one interstitial per three nodes, six per session, ninety seconds apart — have to be server-tunable against retention data, and retrofitting that after the ad logic ships means touching every placement. The fallback must work fully offline; a missing config never blocks play.

## Milestone 1 — A sudoku you can play

*Done when: a player can solve a puzzle at any of six ranks, with full notes, offline, and it feels good.*

**Complete.** A player can open a puzzle from the shipped **pack** at any of the
six **rank**s, place values, mark notes in fixed positional slots, run a **chain
test** in **provisional note**s, and watch **unit**s celebrate and hold a
**completion tint** — with **auto-cleanup**, **candidate highlighting**, and
**auto-notes** throughout. "It feels good" is measured everywhere except on a
physical Android phone; see the OUTSTANDING notes on changes 6 and 11.

### 5. `add-puzzle-engine`
**Done** — `openspec/changes/archive/2026-09-09-add-puzzle-engine/`.
**Capabilities:** `puzzle-engine`
Puzzle model, solver, uniqueness verification, technique-based grading. Offline-first.
**Depends on:** 3.
**Watch for:** grading is the load-bearing system. A puzzle graded Marshal that only needs a hidden single destroys trust in the whole progression. Test the grader against a known-graded corpus.
**Note:** shipped as scoped, without a generator or a pack — see 5a.

### 5a. `add-puzzle-generation`
**Done** — `openspec/changes/archive/2026-09-09-add-puzzle-generation/`.
**Capabilities:** `puzzle-engine`
Seeded generation on top of the engine's uniqueness check and grader, the first real shipped pack with puzzles at all six ranks, and pack loading and top-up. Without it there is nothing to play: change 6 can render a grid and change 7 can mark notes, but neither has content behind it, and Milestone 1's "a player can solve a puzzle at any of six ranks" is unreachable.
**Depends on:** 5.
**Watch for:** generation is a loop that proposes a grid, checks uniqueness, and grades it — all three already exist, so the risk is not the algorithm but the shipped pack. Every puzzle in it must pass the exhaustive uniqueness check (constraint 8), and the rank on the row must be the grader's answer rather than a generator parameter.

*Numbered 5a rather than inserted as 6 deliberately: the proposal, the docs, and existing code comments all cite changes by number ("change 19 is where a hint...", "generation and grading are change 5's business"), and renumbering twenty-nine items would silently invalidate every one of them.*

### 6. `add-grid-and-input`
**Done** — `openspec/changes/archive/2026-09-10-add-grid-and-input/`.
**Capabilities:** `grid-input`
Custom-canvas grid render, cell selection, value entry, number pad, erase, undo at full depth, number-first input as a setting, peer highlighting.
**Depends on:** 2, 5.
**Watch for:** the sub-100ms latency budget is a product requirement, not an aspiration. Profile on a mid-tier Android device before this change is considered done.
**OUTSTANDING — the device profile above was never taken.** Implemented and archived with tap-to-repaint measured on the host, an Android emulator, and an iOS simulator only (`docs/PERFORMANCE.md`): median 285–464 µs against a 100 ms budget, on debug builds. No physical Android phone was available. The headroom is roughly 200×, so the budget is very likely met — but that is an inference, and the backlog asked for a measurement. **Take it on the first mid-tier Android phone that comes to hand**, with `flutter test integration_test/grid_latency_test.dart -d <device> --flavor dev`, and record the number. Until then, treat the latency claim for this capability as unverified on real hardware.

### 7. `add-notes`
**Done** — `openspec/changes/archive/2026-09-10-add-notes/`.
**Capabilities:** `notes`
Nine candidates per cell in fixed positions, persistent notes toggle, long-press for the opposite mode, notes never counting as mistakes (D-09, D-10, D-14).
**Depends on:** 6.
**Watch for:** positional layout is the whole point. Notes that reflow when a candidate is removed are the hidden cause of an app feeling bad.

### 8. `add-note-automation`
**Done** — `openspec/changes/archive/2026-09-11-add-note-automation/`.
**Capabilities:** `notes`
Auto-cleanup on value placement, candidate highlighting, auto-notes fill, and single-action undo for each (D-12, D-13).
**Depends on:** 7.
**Watch for:** auto-cleanup is not optional. A setting to disable it would exist only to make the game worse.

### 9. `add-provisional-notes`
**Done** — `openspec/changes/archive/2026-09-13-add-provisional-notes/`.
**Capabilities:** `notes`
A second turquoise ink for hypotheses under test, and a one-action clear of all provisional marks (D-11).
**Depends on:** 8.
**Watch for:** this is a real differentiator — almost nobody ships it. Worth doing properly rather than as a colour toggle.

### 10. `add-mistake-model`
**Done** — `openspec/changes/archive/2026-09-17-add-mistake-model/`.
**Capabilities:** `mistake-model`
Silent mistake recording, auto-check off by default, opt-in strict mode, and overwriting a correct cell never counting as a mistake (D-04, D-05).
**Depends on:** 6.
**Watch for:** the default matters more than the feature. If auto-check ships on, the product's whole positioning is gone.

### 11. `add-completion-effects`
**Done** — `openspec/changes/archive/2026-09-17-add-completion-effects/`.
**Capabilities:** `completion-effects`
Row, column, and block completion effects; chained cascades at 90ms offsets; puzzle completion sequence; persistent non-additive completion tints with corner marks (D-46 … D-50, D-52).
**Depends on:** 6, 2.
**Watch for:** tints must not stack. A cell in three completed units looks identical to one in a single unit, or a nearly finished board turns to mud.

**OUTSTANDING — the mid-tier Android profile was not taken here either.** Everything short of a physical phone is measured and recorded in `docs/PERFORMANCE.md`: repaint under a full three-step cascade with sixty particles and a fully tinted board, on the host (399 µs), an Android emulator (3.9–4.5 ms), and an iOS simulator (409 µs), against a 100 ms budget and a 16.6 ms frame. `integration_test/completion_effects_test.dart` is the device runner, so the phone measurement is one command rather than a morning's work. **A cascade is a heavier frame than anything change 6 measured, so one session on a mid-tier Android phone settles change 6's outstanding profile and this one together.** Haptics are covered by none of it — the simulator reports success for a haptic it never played, so telling the light impact from the medium one is a manual check on real hardware. Sound was deferred out of this change entirely: no audio package is chosen in `docs/TECH_STACK.md` and no change owns audio, so the per-event cues in `docs/DESIGN.md` §5 are still unbuilt and need a decision plus a change of their own.

---

## Milestone 2 — A reason to come back

*Done when: there is a season to progress through, a daily habit, and a permanent record.*

**Complete — 12 through 17 are archived.** 18, under no milestone heading, is
the next unblocked item.

### 12. `add-rank-progression`
**Done** — `openspec/changes/archive/2026-09-19-add-rank-progression/`.
**Capabilities:** `rank-progression`
Six ranks Greenhorn through Legend, mapped to required techniques; rank state; per-technique statistics (D-07).
**Depends on:** 5, 10.

**What it left for 13, 15, and 16.** A player's **rank** is the hardest **rank**
they have completed a puzzle at and never falls (D-102); **rank**s above theirs
are marked and stay openable (D-103); a **technique unlock** is that technique's
counter standing above zero, meaning *solved* rather than *encountered* (D-104).
Ask `ProgressionRepository` rather than reading the counters directly, and ask
`PlayerRank.above` rather than comparing enum indices.

Two things it also fixed, because nothing worked without them: neither
`recordSolve` nor `markSolved` had ever had a production caller, so finishing a
puzzle recorded nothing at all; and the **rank** picker cached what was next, so
it went on offering a puzzle the player had solved. Any later screen that caches
a progression read needs the same invalidation (D-105).

**`rank_picker_screen.dart` is scaffolding change 15 promotes — not, as this
line said until change 15 ran, scaffolding it deletes.** The mark's presentation
lives there; the rule lives in the capability and survives. Carry the mark onto
the map. The screen itself stays: a **trail** walked in order puts Legend forty
**node**s away, so deleting the only by-**rank** route would void both D-103 and
`grid-input`'s "a puzzle can be reached at any rank". It becomes **free play**
behind the navigation (D-111).

### 13. `add-technique-tutorials`
**Done** — `openspec/changes/archive/2026-09-19-add-technique-tutorials/`.
**Capabilities:** `technique-tutorials`
Short interactive tutorial the first time a player meets a puzzle requiring a new technique. Skippable, replayable from the cabinet.
**Depends on:** 12, 8.
**Watch for:** the notes tutorial must land no later than Sheriff rank. Marshal upward is unplayable without notes.

**What it left for 16 and 33.** Eleven **lesson**s — ten techniques plus notes —
fire on encounter, at most one per puzzle opening and the hardest due (D-106).
`LessonsScreen` is the replay list, and it is deliberately self-contained so
`add-trophy-cabinet` can adopt it whole rather than rebuild it; it lives behind
a settings row until then. Full house and naked single have no **lesson** on
purpose: a player who cannot find those has not met a technique, they have not
met the game, which is change 33's business.

**The content is derived, not written.** `tool/find_lesson_positions.dart` walks
the shipped **pack** until each technique actually fires, and
`lesson_catalogue_test.dart` re-checks every grid against the engine. Regenerate
rather than hand-editing a grid; a lesson demonstrating a pattern its own board
does not contain reads perfectly and teaches nothing.

**It amended a shipped scenario.** D-103 said a marked **rank** opens with "no
extra step"; a **lesson** is one. `grid-input` now says a **lesson** may precede
the grid and is never a penalty for reaching upward. It also fixed a schema
defect it did not cause — see D-107.

### 14. `add-daily-challenge`
**Done** — `openspec/changes/archive/2026-09-22-add-daily-challenge/`.
**Capabilities:** `daily-challenge`
One puzzle per day, identical for all players, month-grid calendar, streak counter, one automatic free streak freeze per week (D-20). No interstitial, ever.
**Depends on:** 5, 3.
**Watch for:** the freeze must apply automatically. A freeze the player has to remember to use is a trap, not a safety net.

**A daily names a puzzle, a node names a rank** — the mirror of D-110, so every
player meets the same board (D-115). The **rank** follows a weekly ramp rather
than the player (D-116), the freeze regenerates weekly and never banks (D-117),
and anything drawn from the clock is injected so no golden reads the wall
(D-118). The schedule format is in `lib/features/remote_config/PUBLISHING.md`.

**The Android emulator found a real bug:** changing the device timezone with the
app running left the old day's board on screen, because the status read was
cached and nothing invalidated it on resume. Fixed and covered in
`daily_screen_test.dart`.

**OUTSTANDING — the device checks.** `integration_test/daily_challenge_test.dart`
passes on the iOS simulator (safe area 62/34pt) and the Android emulator
(52/24pt). It has been taken on **no** physical device.

### 15. `add-season-map`
**Done** — `openspec/changes/archive/2026-09-20-add-season-map/`.
**Capabilities:** `season-map`
42-node territory map, node types (puzzle, variant, chest, boss), front-loaded reward pacing, non-expiring nodes, unlimited free boss retries, season rotation (D-18, D-19, D-22).
**Depends on:** 12, 3.
**Watch for:** build seasons as data from the start. If season one is hard-coded, the six-week cadence dies in month two.

**It reversed this list's own instruction about change 12.** The line under 12
said this change would *delete* `rank_picker_screen.dart`; it promotes it to
**free play** instead (D-111). A **trail** walked in order (D-108) puts Legend
forty **node**s away, so deleting the only by-**rank** route would have voided
both D-103 and `grid-input`'s "a puzzle can be reached at any rank" on the day
it landed. The **trail** is the spine; **free play** keeps the ladder open.

**Three seams are named rather than silent**, each with a test that says which
change owns it: a **chest node** completes and mints no **stamp** (18), a **boss
node** completes and files no trophy (16), and a **variant node** is typed as one
and plays a classic board (17). D-19's pacing is carried by the **variant node**
positions for now, because the rewards it was written about do not exist yet —
worth revisiting when 18 lands.

**A season is a publish, not a release.** The document lives under
`remote-config` with season one compiled in, and `lib/features/remote_config/PUBLISHING.md`
is the specification the first upload is checked against. A **node** names a
**rank**, never a puzzle (D-110), which is what lets a **pack** be topped up
mid-**season**.

**OUTSTANDING — the device checks.** `integration_test/season_map_test.dart` is
the runner and passes on the iOS simulator (safe area 62/34pt, navigation clear
of the home indicator, all 42 **node**s reachable, a completion surviving a real
SQLite round trip). It was **not** taken on the physical iPhone — the connected
device reports Developer Mode off — and **not** on Android, because none is
attached. The mid-tier Android profile carried against changes 6 and 11 is
unchanged and still wants the same session.

### 16. `add-trophy-cabinet`
**Done** — `openspec/changes/archive/2026-09-23-add-trophy-cabinet/`.
**Capabilities:** `trophy-cabinet`
Permanent trophies and medals, unearned seasonal awards shown as unfiled rather than hidden, lifetime and per-technique statistics (D-17, D-21).
**Depends on:** 15, 14, 12.

**It shipped one concept, not two.** "Trophies and medals" became **trophy**
alone; nothing said what a medal would mean. A **trophy** is minted when earned
(D-124) and a **season** declares its own **award**s (D-125), with the format in
`lib/features/remote_config/PUBLISHING.md`. The **boss node** and perfect-month
seams left by 15 and 14 are filled; the **chest node** → **stamp** seam (18) is
untouched. A perfect month mints one **trophy** per month — the first cut minted
only the first month ever, and was caught against `docs/SPEC.md` §5.3 at archive.

**OUTSTANDING — the device checks.** `integration_test/trophy_cabinet_test.dart`
passes on the iOS simulator (safe area 62/34pt) and the Android emulator
(52/24pt), with the four-destination navigation clear of the bottom inset. It
has been taken on **no** physical device, and joins the runners from 6, 11 and 15
waiting on the same session.

### 17. `add-puzzle-variants`
**Capabilities:** `puzzle-engine`, `grid-input`, `notes`, `season-map`,
`persistence`, `technique-tutorials`, `design-system` — widened from the first
two when planning found a **cage** reaches every system that reads **peer**s,
and the puzzle table.
**Done** — `openspec/changes/archive/2026-09-25-add-puzzle-variants/`.
**Killer**, on **variant node**s only (D-127 … D-131).
One rule variant beyond classic for the season's variant nodes — killer recommended for v1.
**Depends on:** 6, 15.
**Watch for:** scope. One variant, properly. Not four.

A **cage** is peers, not a **unit** (D-130): auto-cleanup, auto-notes and the
selection highlight reach **cage** mates, and a filled **cage** celebrates
nothing. Two techniques join the ladder — cage combination at Greenhorn, the 45
rule at Sheriff — each with a **lesson**, and cage combination's is owed before
any other **killer** **lesson** (D-128). The **pack** is version 2: 72
**killer** puzzles, 12 per **rank**, with every classic row unchanged. Schema
v7 → v8 adds a nullable `cages` column. Notes on a **killer** board shrink to
8.3px on the smallest phone (D-129, amending D-74 for **killer** only).

**Deferred to change 30 (D-131):** a screen reader announcing a cell's **cage
sum** — no board has per-cell semantics yet.

**Found in review and fixed before archiving:** the cached **cage** outline
stayed put when the grid moved inside a taller box, and hardest-first **lesson**
choice could skip the cage combination **lesson** for good.

**OUTSTANDING — the device checks.** `integration_test/killer_test.dart` opens a
**variant node** and checks **auto-cleanup** reaches a **cage** mate. It passes
on the iOS simulator (iPhone 17e) and the Android emulator (Pixel 10 Pro), and
has been taken on **no** physical device. Whether 8.3px notes and 8px sums read
at arm's length is a check by eye on the smallest real phone.

---

### 18. `add-stamps`
**Capabilities:** `stamps`
The perk currency. Earning on daily completion, perfect solve, streak milestone, chest, and boss; a persisted balance that survives app kill; and the earn values in D-66. Never purchasable — no store surface of any kind.
**Depends on:** 3, 14, 15.
**Unblocked** — 3, 14 and 15 are all archived. 15 left a seam test asserting a
**chest node** mints no **stamp**; replace it rather than edit it, the way 16
replaced the **boss node** one.
**Watch for:** the balance is save state, so it inherits constraint 9 — write on every change, never on a timer. A Stamp awarded and lost to a crash is worse than one never awarded.

### 19. `add-perks`
**Capabilities:** `perks`
The assist catalogue and the hint meter (D-67): one free hint per puzzle, then Stamps or rewarded video. Hint, auto-notes charge, reveal a cell, scan a unit, digit sweep, solve a row.
**Depends on:** 5, 7, 18.
**Watch for:** running out of Stamps must never block play — no locked node, no ended attempt, no unsolvable grid. And digit sweep must stay distinct from free candidate highlighting; metering a feature that is already free is the failure mode here.

## Milestone 3 — The reason it exists

*Done when: the game is funny.*

### 20. `add-character-system`
**Capabilities:** `character-system`
Rive rig, the four characters, reaction trigger table, character strip below the grid, silent idles after 20 seconds (D-58, D-59, D-60, D-40, D-44).
**Depends on:** 6, 10, 11.
**Watch for:** the character strip must never cover the grid, and idles must never make noise.

**The trigger table is act-gated, and that is not optional (D-121).** Each row
draws from a pool chosen by the player's act, so Ace at **node** 2 and Ace at
**node** 41 are not the same character. This is one column on a table that is
already being built — no new triggers, no new animations, no new art. Built
stateless it cannot be retrofitted without rewriting every line, and the cast
will comment for a whole **season** without ever developing.

**Each character is a mechanism, not a tone (D-123).** "Dry, grudging" tells an
animator a mood and writes no lines. The Sheriff expresses praise as a filing
status; Ace is fond of you, never hostile; Biscuit runs on disproportion;
Number Four objects to working conditions and never to correctness. Write from
the mechanism or the four voices blur into one.

**Two of the four have never been drawn.** Ace exists in the mockups; the
Sheriff and Number Four exist nowhere in `lib/` at all, and the Sheriff carries
the entire rank arc (D-122). Budget them as new work, not as variants.
`docs/pages/narrative-screens.html` has both, and the avatar lesson learned
there: **an avatar crop is a silhouette, not a portrait** — a numeral with eyes
and a mouth at 46px reads as a pair of goggles.

### 21. `add-digit-reactions`
**Capabilities:** `character-system`, `completion-effects`
Digits reacting to duplicates in place of a conventional red flash (D-42).
**Depends on:** 20, 10.
**Watch for:** this is the single clearest expression of the product's positioning, and it costs one animation. Do not cut it for schedule.

### 22. `add-running-gags`
**Capabilities:** `running-gags`
Ace's jailhouse tally (cosmetic only), telegram and newspaper loading screens, wanted-poster season portraits (D-61, D-62).
**Depends on:** 20, 15.
**Watch for:** the tally must never affect difficulty, rewards, or progression. The moment it carries consequence it breaks the non-punitive principle.

**The tally has to be somewhere the player looks.** Marks accumulating in a
database are not a running gag. It belongs on the **trail** as a drawn wall,
which means this change edits a screen that shipped in 15 — expect that, and do
not let it become a reason to put the tally somewhere nobody goes.

**Three narrative surfaces on the trail ride along (D-119, D-120).** The header
names the case rather than only the territory; the progress line reads *ledger
refiled — 13 / 42 pages* instead of *trail progress*, which is the same number
with the story attached and the cheapest item in this whole change; and a
leaning signpost names the act. All three are drawn in
`docs/pages/narrative-screens.html`.

**Telegrams are the only place the plot can move.** They fire between **node**s,
which is the one moment nothing is being interrupted (constraint 4). Act-gated
like every other pool. They decorate a load that was already happening and must
never gate the first frame — if there is nothing to wait for, no telegram.

### 23. `add-deputy-avatar`
**Capabilities:** `deputy-avatar`
Customisable player character — hats, moustaches, badges, kerchiefs — as flat layers on one rig, feeding the wanted-poster wall (D-63).
**Depends on:** 20, 16.

### `add-node-complete-beat` *(unnumbered)*
**Capabilities:** `season-map`
The reward beat after a **node** is cleared: what was achieved, the technique
unlocked, the time, the explicit **Continue**, and the slot an interstitial is
permitted to fire into. Plus the **season** close at **node** 42 — the case
filed, the poster to the **cabinet**, Ace's exit line (D-24, D-22, D-119).
**Depends on:** 15, 20.

**Nothing builds this today and change 24 assumes it.** 24's placement rule is
"after node completion, after celebration, **after an explicit tap**" — so the
tap it names has no screen to live on. D-24's entire ad policy, which is the
product's main defence against the category leader's worst habit, currently
rests on a surface no change owns. This is the gap, and it is the reason this
entry exists.

**Unnumbered on purpose.** The numbers here are load-bearing — every entry's
**Depends on** line refers to them — so inserting a 24 would renumber eleven
changes and silently invalidate a dozen references. `add-pad-tools-row` set the
precedent for corrective work that does not fit the numbering; this follows it.
Its position in this file is its position in the order: it lands before 24.

**Capability assignment is a judgement call worth revisiting.** Filed under
`season-map` because a **node** completing is already that capability's
business — it owns `completeNode`, chest opening, and boss attempts, and a beat
that only ever fires on the **trail** belongs with the **trail**. It touches
`completion-effects` (11, archived — which owns the in-grid celebration, not the
screen after it) and `ads` (24). If it grows a second screen, split it out then.

**Watch for:** there is no failure variant of this screen and there must never
be one (D-22). Boss retries are unlimited and free, so the most loaded moment in
the **season** has nothing to lose attached to it. Drawn in
`docs/pages/screens-redesign.html` §04.

---

## Milestone 4 — The business

*Done when: the app can earn, and paying players are never let down.*

### 24. `add-ads-integration`
**Capabilities:** `ads`
AdMob with mediation. Interstitial only after node completion, after celebration, after an explicit tap. Caps: one per three nodes, ninety seconds apart, six per session, never on chest, boss, or daily. Banners on map and cabinet only (D-24, D-25).
**Depends on:** 15.
**Watch for:** the caps are the feature. Ship the placement rules as testable logic, not as an ad-SDK configuration someone can quietly loosen later.

**Already done for you by change 4.** The D-24 volume caps are remotely tunable and read from `ConfigValue` — consume them rather than re-deciding where they live. They are clamped so a config can only tighten them, never loosen them, and *placement* is deliberately not configurable at all. `lib/features/remote_config/PUBLISHING.md` is the specification for the config document.

### 25. `add-rewarded-video`
**Capabilities:** `ads`
Opt-in rewarded placements: a hint, an auto-notes charge, doubling a chest, one bonus daily chest (D-26).
**Depends on:** 24, 8.

### 26. `add-purchases-and-entitlements`
**Capabilities:** `purchases`
RevenueCat, StoreKit 2 and Play Billing, the Deputy Badge subscription with seven-day trial, one-time ad removal, restore purchases, and an automated test asserting zero ads under an active entitlement (D-27, D-28, D-29).
**Depends on:** 24.
**Watch for:** the no-ads test is a release blocker. Ads appearing after ad removal is the most trust-destroying failure in the category.

### 27. `add-season-pass`
**Capabilities:** `purchases`, `season-map`
Parallel premium reward track on the same 42 nodes, offered at node 5, included free for subscribers. No gameplay advantage, no difficulty reduction (D-30).
**Depends on:** 26, 15.

### 28. `add-auth`
**Capabilities:** `auth`
Cognito user pools with Sign in with Apple and Google federation, and a guest tier that requires no account and loses nothing locally. Sign-in prompts at three moments only — after the first season completes, on subscription purchase, and in settings — never on first open, never blocking. Guest-to-account migration on first sign-in (`docs/TECH_STACK.md` §2a).
**Depends on:** 3.
**Watch for:** the migration is where this breaks. A player who signs in after three weeks of guest play must not find an empty cabinet. Never merge two saves silently — present both with rank, streak, and season progress and let the player choose — and never delete local state until the upload is confirmed. Sign in with Apple is mandatory on iOS if any other third-party sign-in is offered; submissions are rejected without it. Meta federation is a defensible cut.

### 29. `add-cloud-sync`
**Capabilities:** `cloud-sync`
API Gateway + Lambda + DynamoDB save sync, free for any signed-in player and not a subscriber benefit (D-68). Debounced sync triggers, the merge semantics in `docs/TECH_STACK.md` §3b, and graceful offline degradation.
**Depends on:** 28, 3.
**Watch for:** last-write-wins is the wrong default. Counters take the maximum, sets union, and the **streak is recomputed from the unioned calendar rather than synced as a number** — that single rule removes most conflicts. In-progress puzzle state is device-local and never synced. Never block the grid on a network call.

---

## Milestone 5 — Ship quality

*Can run in parallel with milestones 3 and 4. None of it is optional at launch.*

### 30. `add-accessibility-settings`
**Capabilities:** `accessibility`
Reduce-effects setting, OS reduce-motion respected, completion tints toggleable, dynamic type, screen reader labels on the grid, colour-independent state signalling verified (D-50).
Screen reader labels on the grid means **per cell**: today the grid is one
semantics node on every board. On a **killer** board a cell's label also names
its **cage sum** and **cage** size — deferred here from change 17 (D-131).
**Depends on:** 11.

### 31. `add-analytics`
**Capabilities:** `analytics`
Node completion by rank, notes usage by rank, hint usage by technique, interstitial-adjacent session ends, trial start and conversion, season pass offer views and conversions.
**Depends on:** 15, 24, 26.
**Watch for:** instrument interstitial-adjacent churn specifically. It is the number that proves or disproves the whole ad policy.

### 32. `add-localization`
**Capabilities:** `localization`
Localisation infrastructure and the first language set. Character lines stay under six words; Biscuit needs none (D-02, D-59).
**Depends on:** 20.

### 33. `add-onboarding`
**Capabilities:** `technique-tutorials`, `season-map`
First-run experience: first puzzle inside 15 seconds, no account required, no paywall on first open.
**Depends on:** 13, 15.

### 34. `add-store-release-pipeline`
**Capabilities:** `platform-shell`
Store listings, screenshots, age ratings, privacy manifests, App Tracking Transparency, Play Data Safety, phased rollout, release checklist including the no-ads entitlement test.

**Also inherits the hardware verification from change 1** (D-70). `setup-mobile-foundation` built and shipped all of this; none of it could be *verified* without a physical device, a Sentry account, or signing certificates, and holding change 1 open for that would have blocked all 33 other items:

- Cold start on a mid-tier physical Android device, and on an iOS device, against the 2-second budget in `openspec/project.md`. An emulator cannot substitute — the same binary measured 931ms and 3189ms on one depending on host load
- Orientation on a real iOS device: portrait-locked on iPhone, rotating on iPad
- A real Sentry event from a `dev` build, arriving tagged `dev`
- The iOS Fastlane lane producing a signed archive, with `match` and an App Store Connect API key
- The accessibility check, once `add-design-system` has given it something to check

**Depends on:** 26, 31.
**Watch for:** the cold-start requirement archived into `openspec/specs/` from change 1 as intent, never as a measurement. It is the one requirement in the foundation with no evidence behind it, and this is where it gets some.

---

## Deliberately not in v1

Recorded so they do not creep in:

- Additional seasons beyond the first (content pipeline, not engineering)
- Additional rule variants beyond one
- Tournaments and leaderboards
- A standalone Killer Sudoku app (target: launch +6 months, D-34)
- Friends, social features, or sharing
- Tablet-specific layouts beyond basic landscape support
- Any *purchasable* currency, coin store, Stamp bundle, or gacha mechanic (D-23, D-66). Stamps themselves are in v1 and are earned only through play

---

## Working with mattpocock/skills

Install once per repository:

```
npx skills add mattpocock/skills
```

Take at minimum `setup-matt-pocock-skills`, `grill-with-docs`, `handoff`, `tdd`,
and `diagnose`. The skills are written into your repo as ordinary files you own
and can edit — adjust them to match the conventions in `openspec/project.md`
rather than working around them.

### Where each skill sits in the loop

| Stage | Tool | Output |
|---|---|---|
| Idea is still loose | `/grill-with-docs` | Decisions appended to `docs/DECISIONS.md`, glossary updated in `openspec/project.md` |
| Decisions are settled | `/opsx:propose <name>` | `proposal.md`, `design.md`, `tasks.md`, delta specs |
| Building | `/opsx:apply` + `/tdd` | Code and tests |
| Something breaks | `/diagnose` | A cause, before any fix |
| Session getting long | `/handoff` | A document pointing at the change directory |
| Change is complete | `/opsx:verify` then `/opsx:archive` | Deltas merged into `openspec/specs/` |

### The overlap to watch

`grill-with-docs` maintains a documentation layer by default — `CONTEXT.md` and
individual ADR files. This project already has both: `openspec/project.md` is
the context document and `docs/DECISIONS.md` is the ADR log. `openspec/config.yaml`
redirects the skill's output at the existing files.

Check after your first grilling session that no `CONTEXT.md` or `adr/` directory
appeared. If one did, the redirect is not landing — edit the installed skill
file directly, since it lives in your repo and you own it.

---

## The lightweight workflow

This project uses a custom schema, `doku-lite`, in `openspec/schemas/`. It
produces three artifacts instead of four — `design.md` is gone, and its
questions live inside the proposal template as three prompts you answer only
where they apply.

Per change:

```
/opsx:propose <name>     # proposal, specs, tasks in one pass
/opsx:apply              # implement
/opsx:archive            # merge deltas into openspec/specs/
```

Use `/opsx:ff` when you want fast-forward rather than step-by-step review.

**Skip the specs artifact** for changes with no observable behaviour — set
`skip_specs: true` in the change's `.openspec.yaml`. Refactors, dependency
bumps, and CI work do not need requirements. Anything a player or another
capability can observe does.

**What was deliberately kept.** Delta specs stay, because archive is what
builds durable truth under `openspec/specs/`. Drop them and that directory
never populates, which removes the main reason to run OpenSpec at all on a
solo project.
