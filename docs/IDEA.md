# Doku Duty

A funny, non-punitive sudoku game for iOS and Android.

---

## The one-line version

You are a frontier deputy who files numbers for a living. Solve sudoku, rise from Greenhorn to Legend, and try to stop the outlaw Ace from tallying your mistakes on the jailhouse wall.

## Why this exists

Sudoku puzzles are mathematically identical in every app on the store. There is no puzzle-quality advantage available to win, and the category leader has enormous install share and a mature ad stack. Competing on features is futile — anything shippable can be copied in a sprint.

Every serious competitor is calm, minimal, and blue. Nobody owns comedy in this category.

Doku Duty competes on two things a competitor cannot copy without abandoning their own audience:

1. **Personality.** A cast of characters, running visual gags, and a world with a voice.
2. **Respect for the player's time.** No lives, no energy, no failure states, no timer that can beat you.

The art direction and comedy writing are the product. The sudoku engine is table stakes.

## The world

The frontier. A territory of dusty towns where the law is administered through paperwork and everyone takes numbers extremely seriously.

**You** are the Deputy, working your way up the ranks.

| Character | Role |
|---|---|
| **The Sheriff** | Your grizzled boss. Dispenses dry, grudging approval. |
| **Ace** | The outlaw. Tallies your mistakes on the jailhouse wall and cheats at numbers. |
| **Biscuit** | A burro. Wordless, loyal, delighted by your successes. |
| **Number Four** | A digit with opinions and a bounty on its head. |

Biscuit never speaks — zero localisation cost, identical comic timing in every market, and the only warmth in a cast otherwise made of obstacles.

## Core design principles

**Non-punitive by default.** No lives, no hearts, no energy, no session limits, no forced waiting, no failure state on any puzzle. Mistakes are recorded quietly for statistics. Auto-check is off by default. A strict mode exists for players who want stakes, and turning it on is a deliberate act.

**Honest difficulty.** Six ranks graded by the hardest solving technique the puzzle requires, not by clue count. Progression feels like getting smarter rather than grinding.

| Rank | Techniques required |
|---|---|
| Greenhorn | Full house, naked single |
| Deputy | + hidden single |
| Sheriff | + naked pair, pointing pair |
| Marshal | + box-line reduction, naked triple |
| Ranger | + hidden pair, X-wing |
| Legend | + swordfish, XY-wing, simple chains |

**Notes that actually work.** Up to nine candidates per cell in fixed positions, two inks (settled and provisional), auto-cleanup, and candidate highlighting. The top three ranks are unplayable without them.

**Three progression layers.** Permanent (ranks, trophy cabinet, lifetime stats — never resets), seasonal (a territory map, six weeks, rotates out), and daily (challenge calendar and streak).

**Effects that reward without obstructing.** Nothing over 400ms, nothing blocks input, cascades chain rather than overlap.

## Business model

Free to play. Everything in the core loop — all puzzles, all six ranks, the full season map, the daily challenge, the complete notes system, offline play — is free.

**Ads.** Interstitials only after a node completes, after the celebration, and after an explicit tap to continue. Capped at one per three nodes, six per session, ninety seconds apart. Never on a chest, a boss, or the daily. No banner is ever visible while a grid is on screen. Rewarded video is opt-in and carries the volume.

**The Deputy Badge subscription.** $4.99/month or $29.99/year with a seven-day trial. No ads, unlimited hints and auto-notes, every season pass included, extra streak freezes, per-technique statistics, the full daily archive, and a subscriber-only skin each season. Cloud sync is **not** a subscriber benefit — it is free for any signed-in player (D-68).

**One-time ad removal** at $9.99 for players who will never subscribe. **Season pass** at $4.99 standalone, offered at node 5 rather than on first open.

No purchasable currency and no gacha. **Stamps** are a perk currency earned only through play — chests, bosses, perfect solves, streaks, and the daily — and spent on assists such as a hint, revealing a cell, or solving a row (D-66, D-67). Money can never buy them. Running out never blocks play.

## Platform

Flutter, single codebase, iOS and Android. The grid is drawn on a custom canvas for direct control of the render loop. Character animation via Rive. Puzzles are pre-generated offline in packs, so the game is fully playable without a network.

## Visual direction

Cartoon, not authentic. The premise is a dusty frontier bureaucracy; the drawing should look like a cartoon about the West rather than the West itself. Thick warm outlines, generous corner radii, characters and props illustrated into the map.

Every colour has exactly one job:

| Colour | Reserved for |
|---|---|
| Bone / sand | Surfaces only |
| Badge gold | Selection, focus, reward, progress |
| Night indigo | Candidate notes and highlighting |
| Turquoise | Provisional notes only |
| Sunset red | Errors, duplicates, Ace |
| Cactus green | Completed rows, columns, blocks |

Season themes may repaint surfaces, props, and characters. The six state colours are fixed across every season, so the grid never has to be relearned.

## Scope for version one

One season, one variant beyond classic, all six ranks, the complete notes system, the daily loop, the trophy cabinet, the full cast, and the full monetisation stack.

The notes system and the technique grading must be excellent at launch, because everything else is built on them and neither can be retrofitted.

## The main risk

If the character animation and comedy writing are merely adequate, this is a competent sudoku app with no reason to exist. Budget the art before the engineering.
