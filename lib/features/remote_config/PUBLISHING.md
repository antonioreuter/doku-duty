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

Whole numbers may be written as `3`, `3.0`, or `"3"` — all three are accepted,
because a hand-edited file will eventually contain each of them. A fractional
number is rejected in favour of the default rather than rounded.

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
