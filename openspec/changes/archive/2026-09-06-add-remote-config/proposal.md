# add-remote-config

## Why

The ad caps in D-24 have to be tunable against retention data without shipping a
release, and `add-ads-integration` is change 24 — every placement it writes will
read those numbers from somewhere. Deciding where now costs one small change;
deciding it afterwards means touching every placement. Nothing else in the app
needs remote values yet, which is exactly why this is the cheap moment.

## What changes

- **Typed accessors** for remotely tunable values. Callers ask for a named value
  and get a typed answer; they never see JSON, a network state, or a null.
- **A baked-in fallback compiled into the binary.** It is the source of truth
  until a fetch succeeds, and it is a complete config rather than a partial one,
  so the app is fully configured on a fresh install with no network.
- **A fetch of versioned JSON from a URL**, with the response cached locally so
  the last good config survives a restart. The fetch happens after the first
  frame and never on the way to it.
- **Per-key fallback.** The config carries a schema version; unknown keys are
  ignored so a newer config cannot break an older app, and any key that is
  missing or unparseable falls back to its baked-in value on its own. One bad
  value can never cost the whole config.
- **The D-24 ad caps as the first payload**: one interstitial per three completed
  nodes, ninety seconds minimum between them, six per session. Nothing reads them
  until change 24; they exist so that change does not have to invent a mechanism
  while it is also writing placement logic.
- **Remote values are clamped.** See below — this is the part worth arguing
  about.

## Constraints

**Capabilities:** `remote-config`

**Constraint 5 (full offline play)** is the one this change is most able to
break, so the fallback is not a degraded mode: it is the normal mode until a
fetch happens to succeed. There is no state in which the app waits for, retries
visibly, or complains about a config.

**Constraints 6 and 7 (ads)** — this change decides how much of the ad rules can
move at all, and the answer is deliberately narrow. **The placement rules are not
configurable.** That an interstitial fires only after a node completes, after the
celebration, and after an explicit tap, and never on a chest, boss, or daily
node, is compiled in and unreachable from any config. Only the volume numbers are
tunable, and only within limits — see the open item.

**Constraint 2 (latency, first frame)** — the fetch is started after the first
frame and its result is applied when it arrives. No screen waits for it and no
value changes under the player mid-interaction.

**Constraint 1 (non-punitive)** — a config that fails to fetch, fails to parse,
or arrives empty produces no dialog, no banner, and no retry prompt.

**Constraints 3, 4, 8, 9, 10** are untouched: no notes, no colour, no puzzle
generation, no player state, no currency.

## Technical notes

**Grid performance:** Nothing draws. The one rule that matters later is that a
value must be readable synchronously at the point of use — an ad placement
deciding whether it may fire cannot await a future — so accessors read from
memory, and the network only ever replaces what is already in memory.

**Offline, cold start, app kill:** No network on the first-frame path. On a fresh
install with no network the baked-in fallback answers every accessor. The cached
config is read on next launch, so a player who was online once stays configured
offline afterwards. App kill loses at most an in-flight fetch, which is not state
anyone can miss.

**New dependency:** None. A single GET does not justify a package: `dart:io`'s
`HttpClient` is already available, and it sits behind a small injected transport
so tests never touch the network. `package:http` would add a dependency to
replace three lines and would still need the same seam for testing.

**Storage:** The cached config goes in the existing database rather than a file.
The backlog already makes this change depend on `add-persistence-layer`, and that
is the reason — there is one durable store and adding a second place data lives
is a cost of its own. It means this change ships **schema version 2**, which is
the first real migration. The mechanism was exercised at version 1 for exactly
this moment (D-77 records how, and the code documents the steps).

Config is not player state, though, and the difference matters: losing it is
harmless because the fallback exists, so it inherits none of constraint 9's
write-on-every-change discipline.

## Open item: how far a remote value may move

D-24 states its numbers as **"Hard limits"**. This change reads that literally:
**a remote config may make the ad caps stricter, never looser.** A config may say
four interstitials per session; it may not say ten. A config may say one hundred
and twenty seconds between them; it may not say thirty.

That is a real restriction on what the business can do without a release, and it
is worth stating plainly rather than discovering later. Loosening beyond D-24
remains possible — it just requires amending D-24 and shipping a build, which is
the same bar every other product constraint has.

The alternative, letting the server set any number, would mean the volume half of
constraint 6 could be removed by an S3 upload with no review. The caps are the
feature, not the default.

## Not doing

- **No AWS infrastructure.** Creating the bucket, the distribution, the cache
  policy, and the publish path are developer actions outside this change, as
  store registration was for change 1. The client is complete and testable
  against a local fixture without any of it; the URL is a build-time value.
- **No ad SDK, no placements, no impressions.** Change 24 owns all of it. This
  change carries numbers nothing reads yet.
- **No season definitions.** A 42-node structure with node types and reward
  pacing is `add-season-map`'s design (change 15) and would be guesswork here.
  The config format leaves room for it.
- **No A/B testing, no cohorts, no per-user targeting.** One config for everyone.
  Anything else needs an identity to target, which is change 28.
- **No remote kill switches over gameplay.** Nothing in the ten constraints, the
  rank ladder, the note model, or the puzzle rules is reachable from a config.
- **No forced update, no minimum-version gate.** A config that could stop an
  installed app from running is a failure state, and this product has none.
- **No settings UI.** Nothing here is player-visible.
