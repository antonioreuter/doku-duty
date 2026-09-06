# add-persistence-layer

## Why

Nothing survives a restart yet. Every capability from the puzzle engine onward
writes state — a half-marked grid, a streak, a rank, a Stamp balance — and
constraint 9 makes note state in particular the thing that must never be lost.
Two shapes in the schema are expensive to add later because adding them means
migrating live saved games: note provenance (D-15) and the metadata cloud sync
will need.

## What changes

- **A local database on Drift over SQLite** (`docs/TECH_STACK.md` §1, §6), opened
  on first use, with the file living in the platform's application-support
  directory and nothing on the first-frame path.
- **Save state for a puzzle in progress**: the grid, which cells the player has
  filled, elapsed time, and enough to resume mid-puzzle after an app kill.
- **Note state, written on every change** (D-33) — never batched, never on a
  timer. **Settled notes** and **provisional notes** are separate, and manual and
  generated notes are distinguishable in the data model while identical on screen
  (D-15, D-11).
- **Puzzle pack storage** in the shape D-32 already fixes: each puzzle carries its
  solution, its required-technique grade, and its seed, inside a versioned pack.
  The solver, grader, and top-up logic are change 5; this is where they read from.
- **Statistics**: lifetime counters and per-technique counters, which
  `add-rank-progression` (change 12) and `add-trophy-cabinet` (change 16) read.
- **Settings**, including the **reduce effects** switch that `add-design-system`
  deliberately left unpersisted.
- **Sync metadata from day one**: every syncable row carries a last-modified
  stamp and a pending-upload flag, and the save carries the device it came from.
  Nothing reads them until `add-cloud-sync`; they exist so that change is not a
  migration of live saves.
- **Schema versioning and migration tests from version 1**, using Drift's
  `make-migrations` tooling, so the first real migration is not also the first
  time anyone tries the mechanism.

## Constraints

**Capabilities:** `persistence`

**Constraint 9 (note state written on every change) is the whole risk here.** It
has no visible symptom when it breaks, so it is enforced rather than intended: a
test asserts a write reaches the database within the same action that caused it,
and a second asserts no debounce, batch, or periodic flush sits between the two.
Any caching layer added later has to keep passing them.

**Constraint 5 (full offline play)** — this is the layer that makes it true.
Nothing here touches the network at all, and the database is created locally on
first launch with no account and no fetch.

**Constraint 3 (notes are positional)** — nine candidate slots per cell, stored so
that a candidate's identity is its digit rather than its position in a list.
A list that is compacted on removal would reflow the board on reload.

**Constraint 1 (non-punitive)** — a corrupt or unreadable database must lose the
saved game, never block play. The failure path is a fresh database and a playable
app, not an error screen.

**Constraints 2, 4, 6, 7, 8, 10** are untouched: no rendering, no colour, no ad
SDK, no puzzle generation, and no currency that money can reach.

## Technical notes

**Grid performance:** Nothing draws yet, but note writes land on the input path,
which is where the 100ms budget is spent. Writes are small single-row statements
rather than a re-serialisation of the whole grid, and they are issued without the
UI awaiting them — the note is already on screen before the write is
acknowledged. This is what lets constraint 9 and constraint 2 both hold.

**Offline, cold start, app kill:** No network, ever. The database opens lazily on
first read rather than during `bootstrap`, so cold start is unchanged and the
first frame still renders with an empty device. App kill is the case this change
exists for: a puzzle interrupted mid-move reopens with every value, every settled
note, and every provisional note intact, because the last write completed before
the action returned.

**New dependency:** `drift` with `drift_flutter` and `sqlite3_flutter_libs`, and
`drift_dev` at build time.
This adopts `docs/TECH_STACK.md` §6, which already replaced Isar; it does not
reopen the choice. §7 asks for that to be re-verified before it is written into a
proposal, so it was: **Drift is at 2.34.4, published three days ago, with 1.19M
downloads**, while **Isar's last stable is 3.1.0+1 from three years ago** with
only a `4.0.0-dev` prerelease since. The maintenance concern §6 cited has not
resolved. `dart run drift_dev make-migrations` generates the schema snapshots and the
migration tests, which is why version 1 can ship with the mechanism already
exercised.

**Corrected during implementation.** The proposal's version numbers did not
survive contact. `drift` is held at `^2.31.0`, not the latest: from 2.32 the
native sqlite is bundled by Dart build hooks, and on this Flutter the hook's
output never reaches the APK, so the app cannot open its database on Android at
all (D-77). An on-device test found it; all 227 host tests passed throughout,
because the test host links the OS's own sqlite. The database directory is also
set explicitly to Application Support rather than `drift_flutter`'s Documents
default (D-78).

**The backlog wording is stale.** `openspec/BACKLOG.md` still says "Isar schemas"
for this change. `docs/TECH_STACK.md` is canonical for the stack, so the backlog
line is corrected as part of this change rather than left to mislead the next
reader.

## Not doing

- **No solver, generator, or grader.** `add-puzzle-engine` (change 5) owns all of
  it. This change stores a graded puzzle; it cannot produce or verify one.
- **No pack downloading or top-up.** Packs are read from storage here. Fetching
  them from S3 is change 5, and the config that points at them is change 4.
- **No cloud sync, no upload, no conflict resolution.** The metadata that makes
  the §2a rules implementable is written; nothing acts on it. Guest-to-account
  migration, the two-saves choice, and last-write-wins semantics belong to the
  sync change.
- **No auth.** No account, no Cognito, no guest/signed-in distinction in the
  schema beyond the device origin field.
- **No settings UI.** Settings are stored and read; the screen that changes them
  arrives with the capability that owns each one.
- **No Stamp balance.** `add-stamps` (change 18) owns the currency and its earn
  rules, and it inherits this layer's write-on-every-change guarantee (D-66).
- **No statistics presentation.** Counters are recorded; the cabinet is change 16.
- **No encryption at rest.** There is nothing secret in a sudoku save, and a
  key-management story would be cost with no threat behind it.
- **No undo history in the database.** Undo is in-memory for the session
  (change 6). Persisting a full undo stack across launches is a bigger promise
  than any decision has asked for.
