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
