# add-note-automation

## Why

Notes go stale on the second placement. Nothing removes a candidate from a cell
whose **peer** now holds that digit, so a board twenty moves in disagrees with
itself and the player stops trusting it — at which point the feature is dead
(D-12). Candidate highlighting and a full candidate fill are the two things that
make a densely marked Marshal-rank grid readable at all, and neither exists. The
technique ladder above the singles is what the progression is built to teach, and
it cannot be taught on a board the player has stopped believing.

## What changes

- **Auto-cleanup, always on** (D-12). Placing a value removes that digit as a
  candidate from every **peer** of the cell. Not a setting: a setting here would
  exist only to make the game worse.
- **Auto-cleanup is one undo step with the placement that caused it.** Undoing
  the value restores the cell's own candidates *and* every candidate the cleanup
  took from a peer.
- **Candidate highlighting** (D-13). The digit held in digit-first input, or the
  digit in the selected cell in cell-first, lights every cell holding it — as a
  candidate or as a value. Free, always on, and no control of its own.
- **Auto-notes fill.** One action marks every empty cell with all its legal
  candidates. It **unions**: candidates already there stay and keep their manual
  origin; the ones it adds are generated. One undo reverses the whole fill.
- **Origin reaches the domain model.** A note set carries manual against
  generated per digit, so the store's `NoteOrigin` column stops being written as
  the constant `manual` (D-15). A generated candidate the player toggles becomes
  theirs.
- **Glossary:** **auto-notes**, **candidate highlighting**, and **generated
  note** become entries in `openspec/project.md`. All three are already used
  across `docs/SPEC.md` and the game bible without one.

## Constraints

**Capabilities:** `notes`

**Constraint 3 (fixed positions).** It survives, and that is not automatic:
auto-cleanup removes candidates from twenty cells at once and a fill adds them to
eighty-one. Both go through the note set, whose slot is a pure function of the
digit and whose storage is a mask — there is no list to compact, so a mass edit
cannot reflow a cell any more than a single toggle can.

**Constraint 9 (written on every change, never on a timer).** The fill is the
first action that changes hundreds of rows at once. It is written as one
transaction that commits with the action. A transaction is not a batch: nothing
is deferred, nothing waits for backgrounding, and the write is still caused by the
change rather than by a clock. Anything that buffered these would be
indistinguishable from correct until a player lost a filled board.

**Constraint 1 (non-punitive).** Auto-cleanup removes candidates a placement has
disproved; it never says so, counts it, or marks the cell (D-14). Auto-notes is
unmetered here — the charge and the Stamp price are change 19's business (D-67),
and shipping the meter first would put a price on a board before there is any way
to earn Stamps.

**Constraints 4 and 5.** Highlighting uses `nightIndigo`'s pale derivative, the
tint `docs/DESIGN.md` §2 already names for exactly this. No ninth hue. It sits
below selection in the D-49 priority order, and a highlighted cell always holds
the digit it is lit for, so colour is never the only signal.

**Constraint 2.** Both new actions are bounded — cleanup touches twenty cells, a
fill eighty-one — and neither runs on the frame the player is waiting for.

## Technical notes

**Grid performance:** highlighting is one more fill in the painter, computed from
a single digit and the board, with no new layout pass and no per-cell allocation.
The fill computes legal candidates for eighty-one cells once, through the engine's
existing candidate code; it is a one-shot action, never a per-tap cost.

**Offline, cold start, app kill:** all three are local and unchanged. The one new
risk is the fill's write — a kill part-way through must leave the board as it was
rather than half filled, which is what the transaction buys.

**Undo shape:** an applied edit currently records one cell's candidates. Cleanup
and fill each change many, so a history entry has to carry note changes across
cells rather than a single before/after pair. That generalisation is the
load-bearing edit of this change and the place a silent bug would live.

**New dependency:** none. Drift already has transactions and the engine already
computes legal candidates.

## Not doing

- **Metering auto-notes** — no charge, no Stamp price, no rewarded-video offer.
  Change 19.
- **Provisional notes.** Cleanup and fill act on **settled note**s only; the
  second ink is change 9.
- **Any setting to disable auto-cleanup** (D-12).
- **Flagging a candidate as wrong.** Cleanup removes what a placement disproves
  and nothing more; the mistake model is change 10.
- **Digit sweep**, which reveals where a digit *belongs* rather than where it is
  already marked. A perk, deliberately distinct from free highlighting.
- **Auto-notes refreshing itself.** The fill is one action, not a mode that
  re-runs as the board changes.
- **A "clear generated notes" action.** Origin is stored so it becomes possible;
  nothing here exposes it.
