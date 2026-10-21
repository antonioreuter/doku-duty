# Glossary

The canonical vocabulary for Doku Duty. Use these terms exactly in proposals,
specs, tasks, code identifiers, and test names. A change that needs a new
concept adds it here in the same change — never to a `CONTEXT.md`.

Never write "box" for **unit**, "level" for **node** or **rank**, "pencil mark"
for note, "difficulty" where **rank** is meant, or "coin"/"gem"/"token" for
**stamp**.

| Term | Meaning |
|---|---|
| **Node** | One stop on the season map: a puzzle, a variant, a chest, or a boss |
| **Season** | A six-week territory containing 42 nodes, then rotated out |
| **Pack** | A versioned, immutable shipment of pre-generated puzzles, each carrying its solution, its rank, and its seed (D-32). A pack is content; a season is play. One pack can supply several seasons, and a pack version never installs backwards |
| **Rank** | One of six difficulty tiers, from Greenhorn to Legend |
| **Unit** | A row, column, or 3×3 block. A **cage** is not one (D-130) |
| **Peer** | One of the twenty other cells a cell shares a unit with — and on a **killer** board also every other cell of its **cage** (D-130). A digit may appear at most once among a cell and its peers |
| **Settled note** | A candidate the player has derived (indigo) |
| **Provisional note** | A hypothesis under test (turquoise), clearable in one action |
| **Generated note** | A candidate **auto-notes** marked rather than the player. Identical on screen to one marked by hand; the distinction exists for undo, **auto-cleanup**, and clearing (D-15) |
| **Auto-cleanup** | Removing a placed value's candidate from its **peer**s — its row, column, and block, and on a **killer** board its **cage** |
| **Auto-notes** | The one action that marks every empty cell with each candidate its peers do not already hold as a value. Unions with what is already marked; never replaces it (D-87) |
| **Candidate highlighting** | Lighting every cell that holds the held digit, or failing that the selected cell's digit, as a candidate or as a value. Derived rather than set by the player (D-88). Free and always on, unlike **digit sweep** (D-13) |
| **Promote** | The one action that turns every **provisional note** on the board into a **settled note**, adding and removing nothing. The other way a chain test ends, beside the D-11 clear (D-91) |
| **Cabinet** | The permanent trophy and statistics screen |
| **Trophy** | A permanent record of something the player did, minted at the moment it was earned and never removed. Carries the **season** it came from, captured at mint time, so it survives that **season** rotating away (D-124). A record of an *event*, unlike a **streak**, which is a state derived from the **calendar** |
| **Award** | A **trophy** a **season** offers, declared in its published document (D-125). Before it is earned it is **unfiled**; once earned it is a **trophy**. Permanent **award**s belong to no **season** and are always on offer |
| **Unfiled** | An **award** the player has not earned yet, shown in the **cabinet** in the place it will occupy rather than hidden (D-21). **Not a failure and never a countdown** — the visible gap is an invitation to come back, and the distance between that and a reproach is entirely in the wording (constraint 1) |
| **Mistake** | A placement that disagrees with the puzzle's solution. Counted per placement, never per cell, and never lowered by a correction, an erase, or an undo (D-96). Overwriting an already-correct cell is exempt (D-05), and no note is ever one (D-14) |
| **Attempt** | One run at a puzzle, and the **mistake**s recorded during it. Ends at the third in **strict mode** (D-95); starting again is the only route back to zero |
| **Strict mode** | Opt-in setting, off until the player turns it on: immediate error flagging *and* a three-**mistake** limit, together in one switch (D-04, D-94) |
| **Stamp** | The perk currency. Earned in play only, never purchasable. The balance is the sum of the player's **earning**s, recomputed on every read and never stored as a number (D-133) |
| **Earning** | One payment of **stamp**s, recorded against the event that earned it — a day, a puzzle, a **streak** day, a **node** — so the same event never pays twice (D-133). Distinct from an **award**, which is a **trophy**'s definition, not a payment |
| **Perk** | An assist bought with Stamps — hint, reveal a cell, scan a unit, digit sweep, solve a row, auto-notes charge |
| **Digit sweep** | The perk that reveals every remaining cell where a chosen digit belongs. Distinct from free candidate highlighting |
| **Guest** | A player with no account. Keeps full local save, streaks, and cabinet; lacks cross-device sync and reinstall recovery |
| **Signed in** | A player with a Cognito account. Adds cloud sync and recovery, free of charge (D-68) |
| **Flavour** | One of the three builds — `dev`, `staging`, `prod`. Each has its own identifier and launcher name and installs alongside the others (D-69) |
| **Design token** | A named value in the design system — a colour, type role, radius, stroke weight, duration, depth, or haptic. Code reads tokens; it never writes a literal |
| **State colour** | One of the six colour tokens that carries meaning on the grid: ink, focus, candidate, provisional, error, completion. Fixed across every season, unlike the two surface tokens (D-71, D-55) |
| **Reduce effects** | The in-app setting that silences tokenised motion. Independent of the OS reduce-motion setting; either one alone is enough |
| **Completion tint** | The flat colour a completed **unit** keeps for the rest of the puzzle, always accompanied by a **corner mark**. One level only: a cell in three completed **unit**s looks identical to a cell in one (D-48). Derived from the board, never stored |
| **Corner mark** | The small glyph in a cell's corner that says its **unit** is complete without using colour. Survives both colour vision deficiency and the player hiding **completion tint**s (D-50) |
| **Tools row** | The named controls below the digit keys — **Notes**, **Test**, **Fill notes**, **Undo**, and the two that end a **chain test**. Words, never symbols, and only the ones with work to do are on screen (D-100, D-101) |
| **Chain test** | A hypothesis the player is following through the board, written in **provisional note**s. It ends one of two ways: discarded in one action (D-11) or kept by **promote** (D-91) |
| **Cascade** | Two or more **unit**s completed by a single placement. Their effects chain at 90ms offsets in the order row, column, block, never simultaneously, for 520ms in total (D-47) |
| **Technique unlock** | A technique the player has met, meaning a puzzle they solved required it. Read from that technique's counter standing above zero rather than stored separately, so there is one source of truth (D-104). `add-technique-tutorials` fires its lesson on the unlock |
| **Solve record** | What is written when a puzzle is completed: the puzzle marked solved, the lifetime counters, the counters for the techniques it required, and whether the **attempt** was perfect. One transaction at the moment of completion, so no part of it can survive without the others (constraint 9). Written once per puzzle — completing the same board again changes nothing |
| **Lesson** | A short guided walkthrough teaching one technique on a small fixed grid: highlights step through the reasoning and the last step is the player making the placement. Fires when a puzzle requiring that technique is opened, at most one per opening (D-106), and never once the technique is a **technique unlock**. Skippable in one tap, replayable, and marked seen either way |
| **Notes lesson** | The one **lesson** that teaches notes rather than a technique. Fires on opening the first puzzle at Sheriff **rank or harder** — Sheriff is one **rank** before Marshal, where notes stop being optional, and "or harder" is there because the soft **rank** gate (D-103) lets a player skip past Sheriff entirely. Teaching no technique, no **technique unlock** can suppress it; it takes precedence over a technique **lesson** due on the same opening, being the prerequisite for them |
| **Trail** | The **season** map screen: 42 **node**s on a winding path, with the season's name, how far along the player is, and the days remaining — that last shown only while there are any, never as a negative (D-109). *Trail* is what the interface calls it; `season-map` is the capability |
| **Node type** | One of four, fixed per **node** by the **season** definition and never changing within a season: puzzle, variant, chest, boss (D-18) |
| **Variant node** | A **node** playing the **season**'s rule twist rather than classic sudoku. Six per season. Plays a **killer** puzzle (D-127) |
| **Killer** | The rule variant every **variant node** plays: a classic grid also divided into **cage**s. Reached only from a **variant node** — never **free play** or the **daily challenge** (D-127) |
| **Cage** | A group of orthogonally connected cells on a **killer** board, every cell in exactly one. No digit repeats inside a **cage**, and its digits add up to its **cage sum**. Not a **unit**: filling one fires no completion effect (D-130) |
| **Cage sum** | The number a **cage**'s digits add up to, printed top-left of the **cage**'s first cell in reading order (D-129) |
| **Chest node** | A reward **node** carrying no puzzle. Four per season, at 25/50/75/100% of the trail. Opening one is the reward; it costs nothing and cannot be failed |
| **Boss node** | The **node** at a **season**'s midpoint and at its finale. A puzzle like any other except that it retries without limit and without cost (D-22) |
| **Current node** | The one **node** the player is at: the first not yet completed. Drawn larger as well as differently coloured, so someone returning after three days finds their place without reading anything. *First* rather than *furthest* — the two differ only if a completion is ever missing from the middle, and sending the player back to close the gap loses nothing, where sending them past it would leave a hole they can see and cannot reach |
| **Not yet reached** | A **node** further along the **trail** than the player has walked. The phrasing is the requirement: a node is never *locked*, because nothing the player earned is being withheld — they have simply not got there yet (D-108) |
| **Free play** | The route to a puzzle by **rank** rather than by **node**, always available beside the **trail**. It exists so D-103's guarantee survives a trail walked in order: without it a **rank** at the far end of a **season** would be unreachable, which is the gate D-103 refused (D-111). A puzzle solved here writes a **solve record** like any other and advances no **season** |
| **Daily challenge** | One puzzle a day, the same board for every player, rolling over at midnight local time. The third of D-17's progression layers. Unlike a **node**, it names a *puzzle* and not a **rank** — sameness is the thing it promises, which is why it is built on a different mechanism from the **season** (D-110). Never carries an interstitial (D-24) |
| **Calendar** | The month grid recording which days the **daily challenge** was completed. A set of dates, unioned when two devices merge — never a count (`docs/TECH_STACK.md` §3b). The **streak** is read from it |
| **Streak** | Consecutive days the **daily challenge** was completed, counting a day a **streak freeze** covered as unbroken. **Recomputed from the calendar, never stored as a number**, so two devices cannot disagree about it |
| **Streak freeze** | One day of absence that does not break a **streak**. Granted every 7 days, at most one held and never banked, and consumed automatically on the first missed day — a freeze the player has to remember to use is a trap, not a safety net (D-20, D-117) |
