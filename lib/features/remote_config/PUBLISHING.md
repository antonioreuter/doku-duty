# What the client expects to find

The bucket does not exist yet. Creating it is a developer action outside
`add-remote-config`, which is why this file exists: it is the specification the
first upload should be checked against rather than written from memory.

`test/features/remote_config/fixtures/config.json` is a valid document, byte for
byte, and is exercised by the test suite.

## The document

One JSON object. Every field is optional — a document with none of them is valid
and changes nothing, because each key falls back to its compiled-in value on its
own.

| Key | Type | Meaning |
|---|---|---|
| `schema_version` | integer | Recorded, never enforced. Lets a config from the future be told apart from a corrupt one when someone is debugging |
| `ads.interstitial_node_interval` | integer | Completed nodes between interstitials |
| `ads.interstitial_minimum_gap_seconds` | integer | Seconds between interstitials |
| `ads.interstitials_per_session` | integer | Interstitials in one session |
| `season` | object | The **season** the **trail** shows. Absent is valid and common — see below |
| `daily` | object | The **daily challenge** schedule. Absent is valid and common — see below |

Whole numbers may be written as `3`, `3.0`, or `"3"` — all three are accepted,
because a hand-edited file will eventually contain each of them. A fractional
number is rejected in favour of the default rather than rounded.

## The season

`season` is the one structured key. Absent, the client walks the **season**
compiled into the binary, which is a complete 42-**node** trail — so a document
with no `season` is not a degraded one, and the first upload need not carry one
at all. Publishing a `season` is how a **season** is rotated without a release
(D-109).

| Key | Type | Meaning |
|---|---|---|
| `season.id` | string | Stable identity. **Progress is keyed to it** |
| `season.name` | string | The territory, shown on the **trail**. "Copper Hollow" |
| `season.starts_at` | string | ISO-8601. The same instant for every player |
| `season.length_days` | integer | Whole days. Six weeks is 42 (D-18) |
| `season.nodes` | array | Exactly 42 objects, in trail order |
| `season.palette` | object | Optional. What this territory repaints |
| `season.awards` | array | Optional. The **award**s this territory offers — see [The awards](#the-awards) |

Each entry in `season.nodes` carries a `type` — `puzzle`, `variant`, `chest`, or
`boss` — and, for every type but `chest`, a `rank`: one of `greenhorn`,
`deputy`, `sheriff`, `marshal`, `ranger`, `legend`.

**A node names a rank, never a puzzle (D-110).** There is no key for a puzzle
id, a seed, or a grid, and adding one has no effect — the client resolves a
puzzle of the node's **rank** from the installed **pack** when the node is
opened. That is what lets a **pack** be topped up mid-**season** without
stranding a node or reverting a completion.

### The palette

`season.palette` is optional, and absent is not a degradation — a **season**
with no palette wears the default surfaces. It takes `bone` and `sand`, and
optionally `hairline` and `surface_depth`, each as `0xRRGGBB` written either as
a number or as a `"#RRGGBB"` string.

**Those four are the whole list, and no fifth key does anything.** The six state
colours — ink, focus, candidate, provisional, error, completion — are fixed
across every **season** so the grid never has to be relearned (D-55, constraint
4). A document asking for a different completion green is not rejected; there is
simply nowhere for the value to go, and it is ignored like any other
unrecognised key. A palette missing `bone` or `sand`, or carrying a value that
is not a colour, falls back to the default surfaces rather than taking the
**season** down with it.

### What the client refuses

A `season` is checked against D-18 before it is used, and a **season** that
fails any of these is **ignored whole** — the **season** already in force
continues, every other key in the document still applies, and the player is told
nothing:

- Not exactly 42 nodes
- Not exactly 30 `puzzle`, 6 `variant`, 4 `chest`, 2 `boss`
- A `chest` anywhere but nodes 11, 21, 32, 42
- A `boss` anywhere but nodes 22 and 41
- A node of any type but `chest` with no `rank`, or with one that does not
  resolve
- A `type` that does not resolve
- A missing or empty `id` or `name`, an unparseable `starts_at`, or a
  `length_days` that is not a positive whole number

It is refused rather than repaired on purpose. Trimming 44 nodes to 42, or
padding 40 up to it, would produce a **season** nobody authored and no reviewer
saw — and every player would walk it.

`test/features/remote_config/fixtures/config_with_season.json` is a valid
document carrying a **season**, byte for byte, and is exercised by the test
suite.

### Changing the season a player is already walking

Progress is keyed to `season.id`. Publishing a **season** with a **new** id
rotates: the player starts at node 1 of the new trail, and their permanent
progress — **rank**, **technique unlock**s, statistics, seen **lesson**s — is
untouched (D-17). Their old **season**'s completions are kept, not deleted.

Publishing changes under an **existing** id does not rotate, and is the one
thing to be careful with: the completions already written still refer to
positions 1…42, so **node** 7 becoming a different **rank** changes what a
player who has passed it already did. Editing a live **season** in place is for
fixing a typo in its `name`; anything structural should be a new `id`.

## The daily schedule

`daily` is the second structured key, and it is the mirror image of `season` in
the one way that matters. A **node** names a **rank** and never a puzzle
(D-110), so that a **pack** top-up cannot strand it. A **daily challenge** names
a **puzzle** and never a **rank**, so that every player is solving the same
board — which is the only thing this capability promises and the reason it is
built on a different mechanism at all.

Absent is valid and common, exactly as `season` is. With no `daily` key the
client derives each day's board from the installed **pack** by a seed fixed by
the date, so every date still resolves and no player is ever told the **daily
challenge** is unavailable (D-115).

| Key | Type | Meaning |
|---|---|---|
| `daily.schema_version` | integer | Recorded, never enforced |
| `daily.days` | array | One object per date, in any order |

Each entry in `daily.days` carries:

| Key | Type | Meaning |
|---|---|---|
| `date` | string | `YYYY-MM-DD`. The player's **local** date, not an instant |
| `puzzle_id` | string | The id of a puzzle in a shipped **pack** |

### The date is local, and that is deliberate

`date` is a calendar day, not a timestamp, because the **daily challenge**
rolls over at midnight *local* time (`docs/SPEC.md` §5.3). Two players in
different timezones meet the same board on the same calendar date and not at
the same instant. Do not publish an ISO-8601 datetime here; it will be refused.

### Difficulty follows a weekly ramp

A published week MUST rise in **rank** from its start to its end (D-116).
Monday is the easiest board of the week and the weekend carries the hardest.

This is a rule for whoever builds the document, not something the client
enforces — it cannot, because it only ever sees one day at a time. The client's
own fallback follows the same shape, so a player who outruns the schedule keeps
the curve.

**The ramp is not optional and not a stylistic preference.** The board is
identical for every player, so its **rank** cannot scale to the individual the
way **free play** does. A flat schedule at one **rank** is permanently
unsolvable for a Greenhorn and permanently trivial for a Legend; a schedule that
rotates all six guarantees a new player meets Legend boards on a counter whose
entire job is to reward turning up.

### What the client refuses

Per **day**, never per document. One malformed entry loses that day and no
other, and the day it loses falls back to the derived board — the same thing an
absent publish does, so there is no failure a player can be shown.

- An entry that is not an object
- A `date` that is not `YYYY-MM-DD`
- A missing or empty `puzzle_id`
- A `puzzle_id` naming a puzzle the installed **pack**s do not contain

The last is worth stating plainly because it is the one a publisher will
actually hit: **publishing a schedule ahead of the pack that contains its
puzzles is safe.** Those days quietly use the derived board until the **pack**
reaches the device, then start using the named one. Nothing breaks and nothing
is announced.

A `daily` key that is not an object, or whose `days` is not an array, is refused
whole — the client falls back to deriving every day.

### What a schedule cannot do

It cannot withhold a **daily challenge**. There is no representation for "no
puzzle today": a date with no entry is a date the client derives a board for. A
**streak** can therefore never be broken by a publishing mistake, which is the
property constraint 1 needs and the reason the fallback exists at all.

It cannot set a **rank** directly. The **rank** is whatever the named puzzle
already carries, graded when the **pack** was built (D-32). A schedule that
wants a Marshal board on a Thursday names a Marshal puzzle.

## The awards

`season.awards` lists the **trophy**s a territory offers, so a new **season**
gets its own without a release (D-125). It lives inside `season`, not beside
it, because an **award** belongs to the territory that declared it.

Absent is valid and common. With no `awards` key the client offers the
compiled-in set for whichever **season** is in force: one **award** for each
**boss node**, at 22 and 41, and one for closing the **season**, named after
the territory. A **cabinet** with nothing published is complete, not degraded.

| Key | Type | Meaning |
|---|---|---|
| `id` | string | Stable identity. **A minted trophy is keyed to it** |
| `name` | string | What the **cabinet** shows. "The assayer, cornered" |
| `trigger` | string | `boss` or `season_complete` |
| `node_position` | integer | Required for `boss`: the **boss node** that earns it, 22 or 41 |

A published list **replaces** the compiled-in one rather than joining it. A
**season** that wants a trophy for each boss and one for closing must list all
three.

**Ids are forever, and names are too once earned.** A **trophy** is written
when it is earned and keeps the id, name, and territory it was minted with
(D-124, D-126). Renaming an **award** in place changes what is still on offer as
**unfiled**; every player who already holds it keeps the old name. Review a
name before it goes live — a typo fixed later stays on every **trophy** minted
before the fix. Changing an `id` is different: it orphans the old one, and the
player who earned it keeps a **trophy** the new **award** does not recognise and
can earn the new one again. Prefix ids with the **season** id —
`copper-hollow.boss.22` — so two territories cannot collide.

### What the client refuses

Per **entry**, never per document — the same rule as the daily schedule. One
malformed entry loses that **award** and no other:

- An entry that is not an object
- A missing or empty `id` or `name`
- A `trigger` other than `boss` or `season_complete`
- A `boss` entry with no integer `node_position`

The last is refused rather than kept because an **award** that can never be
matched to a completion would sit **unfiled** for ever, which reads to the
player as something they failed to get.

An `awards` value that is not an array, an empty array, or an array in which
every entry is refused all fall back to the compiled-in set. **A refused
`season` takes its `awards` with it:** the compiled-in **season** comes back
into force with its own compiled-in **award**s, never with the refused
document's under the wrong territory.

### What an award cannot do

It cannot invent a way to earn something. `trigger` is a closed set of events
the client already records; there is no key for a score, a time, or a count,
and a new trigger needs a build.

It cannot declare a permanent **award**. The perfect-month **award** and one for
each **rank** from Sheriff to Legend are compiled in and belong to no
**season**, so no publish can add to them, rename them, or withdraw them (D-17).

It cannot take anything away. Removing an **award** from a later publish stops
offering it; every **trophy** already minted under it stays in the **cabinet**
under the name and territory captured when it was earned.

It cannot carry a reward. A **trophy** grants no **stamp**s and no **perk** —
`add-stamps` owns every way a **stamp** is earned (D-66).

## What a value cannot do

**The ad caps can be tightened, never loosened.** D-24 states its numbers as hard
limits, and the client clamps against them: a document asking for ten
interstitials per session gets six, and one asking for a thirty-second gap gets
ninety. Publishing a looser value is not an error and produces no warning — it
simply has no effect, which is worth knowing before someone spends an afternoon
wondering why a change did not take.

Loosening beyond D-24 requires amending that decision and shipping a build.

**Placement is not configurable at all.** No key can permit an ad during a
puzzle, before a celebration finishes, without an explicit tap, or on a chest,
boss, or daily node. Those rules are compiled in. A key that looks like one is
ignored like any other unrecognised key.

## Serving it

- **URL** — supplied at build time, not committed:
  `--dart-define=REMOTE_CONFIG_URL=https://…/config.json`.
  A build with no URL never fetches, and behaves exactly like one that has never
  been online, which is a fully working app.
- **`ETag`** — the client stores whatever the server returns and sends it back as
  `If-None-Match`. A `304` costs a round trip and no payload, which is what makes
  a short TTL cheap. Serving no `ETag` works, and costs the full document every
  time.
- **Cache-Control** — a short `max-age`. The client does not enforce it; it
  refreshes once per launch and relies on the CDN to answer cheaply.
- **Content type** — anything. The body is parsed, not sniffed.
- **HTTPS** — required on both platforms by default. A plaintext HTTP endpoint
  needs an App Transport Security exception on iOS and a network security
  configuration on Android, neither of which this app has, and neither of which
  it should acquire for this.

## What happens when it is wrong

Every failure ends the same way: the values already in effect stay in effect and
the player is shown nothing. A 404, a 500, a timeout, a malformed body, an empty
body, an expired certificate, and a wrong URL are all the same event to the app.
Failures go to the crash reporter, which is the only place an outage is visible.
