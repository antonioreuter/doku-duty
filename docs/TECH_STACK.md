# Technology stack

Decided stack for Doku Duty, iOS and Android. Rationale for the framework choice
is D-31 in `docs/DECISIONS.md`; the rest is argued below.

This supersedes the stack table in `openspec/project.md` where the two disagree —
three entries changed. See §6.

---

## 1. Client

| Layer | Choice | Notes |
|---|---|---|
| Framework | Flutter, stable channel | Single codebase, iOS 15+ and Android 8.0 (API 26)+ |
| Language | Dart | |
| Grid rendering | `CustomPainter` on canvas | Not widget-per-cell — 81 widgets will not hold the latency budget |
| State | Riverpod | Lower boilerplate than Bloc for a small team |
| Routing | go_router | Deep links needed later for daily challenge |
| Character animation | Rive | Runtime state machines driven by gameplay events |
| Local storage | Drift over SQLite | Changed from Isar — see §6 |

**Why Flutter.** Rive's Flutter runtime is its most mature, and character
animation is the product (D-36). `CustomPainter` gives direct Skia access with
predictable frame timing, which is what the sub-100ms input budget and the
60-particle cap actually depend on. Binary lands around 10–15MB with cold start
well inside the 2-second budget.

**Why not Unity.** Unity has the better monetisation stack — LevelPlay
mediation, Remote Config, and A/B testing as first-class platform features — and
an easier hiring pool. But sudoku is a typography application wearing a game's
clothes: a 9×9 grid of dynamically styled text with per-cell state, plus notes at
11px in fixed sub-positions. That is exactly what uGUI and TextMeshPro are worst
at. Unity also adds 20MB+ of binary and a second or more of cold start, in a
category where sessions run four minutes and cold start correlates with day-one
retention.

The trade is honest: **Flutter gives a better product, Unity gives a better
monetisation stack.** The decision is to take the product and buy mediation
separately (§3).

**The closest alternative** is React Native with `react-native-skia` — same Skia
renderer, better ad-mediation library ecosystem, larger hiring pool. Flutter
still wins on Rive integration and frame control, but this is not a landslide.
If the team already knows React well, the productivity gain may outweigh it.

**Rejected:** Godot (weak mobile ads and IAP plugin story, which is precisely
where revenue lives). Native Swift + Kotlin (two codebases on a UI-heavy app is
close to double the work for a solo developer).

**What would change this decision:** if seasons come to carry genuinely animated
scenes rather than illustrated maps with props. That crosses into engine
territory and Unity starts winning. Nothing in the current spec goes there.

---

## 2. Backend — AWS

The backend is small: puzzle pack distribution, one daily puzzle, cloud save for
subscribers, and remote config. No realtime, no multiplayer, no user content, no
social graph. RevenueCat holds subscription state, so there is no subscription
backend at all.

Most of it is static files, which is why AWS suits it.

| Need | Service | Notes |
|---|---|---|
| Puzzle packs, daily puzzle | S3 + CloudFront | Immutable versioned JSON on a CDN. Cheap, cacheable, offline-friendly by design |
| Remote config | S3 JSON behind CloudFront, short TTL | Not glamorous; beats AppConfig for client-facing use |
| Season definitions | Same S3 JSON | A new territory without an app release |
| Cloud save | API Gateway + Lambda + DynamoDB | Small documents, key-value access, single-digit-ms reads |
| Auth | Cognito user pools with Apple, Google, and Meta federation | See §2a |

**Skip Amplify DataStore.** Its offline sync is rougher than the alternatives and
the sync need here is simple: last-write-wins on a small blob.

**Auth is optional, not gated.** See §2a for the tier model. Cognito user pools
with federated identity providers, and a guest tier that requires no account and
loses nothing locally.

**Cost.** Nearly free at this scale. A few megabytes of JSON per user per season
is pennies on S3 and CloudFront; DynamoDB on-demand for subscriber saves is
pennies. Watch CloudFront egress if packs grow — keep them small and versioned so
clients fetch deltas rather than whole packs.

---

## 2a. Authentication and the guest tier

Cognito user pools with three federated providers: Sign in with Apple, Google,
and Meta. Guest play requires no account.

### What each tier gets

| | Guest | Signed in |
|---|---|---|
| Play, all six ranks, every puzzle | Yes | Yes |
| Local save, streaks, season progress, cabinet | Yes | Yes |
| Cross-device sync | No | Yes |
| Recovery after reinstall or lost device | No | Yes |
| Purchase restore | Via store account | Via store account |

**Guests keep their progress.** Everything saves locally through Drift, exactly
as it does for signed-in players. What an account buys is cloud sync — playing
on a second device, and recovering after a reinstall or a lost phone.

This is deliberate and worth defending in review. Most players never create an
account; if a guest's streak vanished on restart, the majority of the funnel
would churn within two sessions to protect a feature few of them wanted. It also
contradicts the onboarding requirement of a first puzzle inside 15 seconds with
no account, and it would be punishment for a choice the game itself invited —
which sits badly against the non-punitive principle in D-03. Every major
competitor saves locally without an account.

The motivation to sign in is real without any of that: losing a 200-day streak
to a broken phone is a genuinely persuasive fear, and it is stated honestly at
the point of sign-in rather than enforced by withholding.

### Sign-in prompts

Offered, never blocking. Three moments:

1. After the first season completes — there is now something worth protecting
2. When a subscription is purchased — entitlement then follows the account across platforms (§3a) rather than the store account
3. In settings, permanently available

Never on first open. Never as a modal that must be dismissed to keep playing.

### Guest-to-account migration

**The local save migrates into the account on first sign-in.** This is the
classic bug in this pattern and it must be handled explicitly: a player who
signs in after three weeks of guest play must not find an empty cabinet.

Rules:

- On first sign-in, local state is uploaded and becomes the account's state
- If the account already holds state — the player signed in on a second device —
  present a choice rather than resolving silently. Show both saves with their
  rank, streak, and season progress, and let the player pick
- Never merge automatically. Merged streaks and duplicated trophies are worse
  than either save alone
- Never delete local state until the upload is confirmed

### Provider notes

**Sign in with Apple is mandatory on iOS** if any other third-party sign-in is
offered. This is an App Store review requirement, not a preference, and
submissions are rejected for missing it.

**Meta login is the weakest of the three.** Declining usage, meaningful SDK
weight, and a data-use review process to maintain. Ship Apple and Google first
and add Meta only if the numbers justify it — this is a defensible cut.

**Cognito and RevenueCat must be linked.** On sign-in, call RevenueCat's login
with the Cognito subject as the app user ID so entitlements follow the account
rather than the device. Without this, a subscriber who signs in on a new device
gets no entitlement until they manually restore.

### Age and family audience

The app targets a 4+ rating (see the firearms exclusion in `docs/DESIGN.md` §6).
Social sign-in for younger users carries consent obligations under COPPA and
GDPR-K. Guest play being fully functional is what keeps this simple: a child
never needs an account, and the account flow can carry an age gate without
affecting gameplay.

---

## 3. Third party

| Need | Choice | Notes |
|---|---|---|
| Ad mediation | AppLovin MAX | Changed from AdMob — see §6 |
| Ad demand source | AdMob, inside MAX | Plus other networks as mediation allows |
| Purchases | RevenueCat | Wraps StoreKit 2 and Google Play Billing; handles entitlement state and restore. See §3a |
| Product analytics | GameAnalytics or Amplitude | GameAnalytics gives free-to-play benchmarks against the category |
| Attribution | AppsFlyer or Adjust | Required once paid acquisition starts, not before |
| Crash reporting | Sentry | Better Flutter support and release-health tracking than Crashlytics |
| CI/CD | GitHub Actions | Free for public repos, generous minutes for private. Fastlane for both stores; signing material in repository secrets. macOS runners are billed at a higher rate — cache Pods and Gradle aggressively |

**Analytics does not run on AWS.** Pinpoint is weak for product analytics and
much weaker for mobile attribution, and attribution is not optional once you are
buying installs — you need to know which install came from which campaign.
These tools are third-party regardless of cloud, so the AWS choice costs nothing
here.

Firebase Analytics is free, good, and commonly run alongside AWS. Using it is a
perfectly normal arrangement if avoiding Google entirely is not a requirement.

---

## 3a. Purchases and subscriptions

Native store billing on both platforms, wrapped by RevenueCat.

| Platform | API | Not this |
|---|---|---|
| iOS | In-App Purchase via StoreKit 2 | **Not Apple Pay** |
| Android | Google Play Billing | **Not Google Pay** |

**Apple Pay and Google Pay are the wrong APIs for this product.** They are for
physical goods and services consumed outside the app — tickets, deliveries,
rides. Digital content and subscriptions must go through In-App Purchase and
Play Billing respectively. A digital subscription submitted behind Apple Pay is
rejected under the App Store payments guidelines.

### Products

| Product | Type | Price |
|---|---|---|
| Deputy Badge, monthly | Auto-renewing subscription | $4.99 |
| Deputy Badge, annual | Auto-renewing subscription | $29.99 |
| Remove ads forever | Non-consumable | $9.99 |
| Season pass | Non-consumable, per season | $4.99 |
| Cosmetic bundles | Non-consumable | $1.99–$4.99 |

No consumable *products* and no purchasable currency (D-23, refined by D-66),
which keeps the catalogue simple and avoids the restore-purchases ambiguity
consumables create. Stamps (D-66) are earned in play and never sold, so they add
no SKU to this table and no restore obligation.

### Commission

Model at **15%, not 30%.**

- Apple Small Business Program: 15% under $1M annual proceeds, requires enrolment
- Google Play: 15% on the first $1M of annual earnings
- Apple: subscriptions drop to 15% after a subscriber's first year regardless

Enrol in both programs before launch. The difference materially changes what the
annual plan is worth.

### Cross-platform entitlement

**Entitlement follows the store account unless the player signs in.**

| | Guest | Signed in |
|---|---|---|
| Purchase restores on same platform | Yes, via store account | Yes |
| Purchase carries across iOS ↔ Android | **No** | Yes |

Link the Cognito subject to RevenueCat as the app user ID on sign-in (§2a). This
is the second real reason to create an account, alongside streak recovery, and
it should be stated on the Deputy Badge screen rather than discovered.

### Requirements that are commonly missed

- **Restore purchases** must be reachable without signing in — an App Store
  review requirement, and the first thing a returning player looks for
- **Free trial handling:** seven days, and the subscription screen must state
  the price after the trial and how to cancel, in the required wording
- **Billing grace period and retry** should be enabled in both consoles, or
  failed renewals churn subscribers who would have paid
- **Entitlement must survive offline.** Cache the entitlement locally with a
  reasonable TTL; a subscriber on a plane must not see ads (D-29)
- **Price localisation** through store price tiers rather than converted USD

### External payment links

Regulatory positions on linking to external payment in the US and EU have
changed repeatedly and continue to move. Do not plan around them. Ship with
standard in-app purchase, and revisit only with current legal advice — the
commission saving is not worth an app removal.

---

## 3b. Offline and sync

Full offline play is mandatory and is not negotiable. (It is stated in the
platform paragraph of `openspec/config.yaml`, not in the numbered ten —
constraint 9 is *note state is written on every change, never on a timer*, which
this section also depends on.) Network is needed only
for ads, pack top-ups, cloud sync, and remote config, and every one degrades
gracefully.

### What is available offline

| | Offline |
|---|---|
| Every puzzle in the installed packs, all six ranks | Yes |
| Notes, hints, auto-notes, undo | Yes |
| Season map, node completion, chests, bosses | Yes |
| Daily challenge, if the pack is prefetched | Yes |
| Streak and calendar | Yes, reconciled on reconnect |
| Trophy cabinet and statistics | Yes |
| Ads | No — and their absence never blocks progression |
| Purchases | No — cached entitlement continues to apply |

**Prefetch on Wi-Fi.** Pull the next pack and the coming week of daily puzzles
whenever the device is on unmetered network. A player who flies without having
opened the app for a week should still have puzzles.

**Never block on network.** No spinner gates the grid. If a sync fails, it
retries silently and the player is not told unless they ask.

### Sync triggers

Debounced, never on every move:

1. App foreground
2. Network regained
3. App backgrounded, best effort
4. Node or daily completion, debounced to at most one call every 30 seconds

### Merge semantics

Last-write-wins is the wrong default. Progress is mostly monotonic, and shaping
the data correctly removes nearly all conflicts.

| Data | Rule |
|---|---|
| Counters — puzzles solved, total time, mistakes | Take the maximum |
| Sets — trophies, completed nodes, unlocked techniques, daily calendar | Union |
| Per-technique personal bests | Best value per key |
| Streak | **Recompute from the unioned calendar** — never sync the number |
| Stamps | **Union the earnings, recompute the balance** — never sync the number (D-133) |
| Rank | Derive from unlocked techniques |
| Settings and preferences | Last-write-wins |
| Cosmetics owned | Union |
| In-progress puzzle state | Device-local, never synced |

Deriving the streak from the calendar rather than syncing it is the single
change that prevents most conflicts: sync the days, compute the number, and two
devices cannot disagree.

**Only first sign-in on a device with existing account state needs a prompt**
(§2a). Everything after that merges silently.

### Clock trust

The daily challenge and the streak depend on the date, and device clocks are
user-editable.

- Store the server-time offset returned by each sync; derive dates from it
- Offline, trust the local clock but mark entries as unverified
- On reconnect, reconcile — accept anything consistent, discard entries that a
  changed clock could have manufactured
- **Never punish a wrong clock.** A player whose timezone shifted keeps their
  streak; the rule exists to stop fabrication, not to catch travellers

### Client authority

The client is authoritative. This is a solo puzzle game with no opponent and
nothing to gain by cheating, so server-side validation would cost real
engineering to protect nothing.

This changes if tournaments or leaderboards ship — those need server-verified
solve times. Neither is in v1 (see the exclusions in `openspec/BACKLOG.md`).

### Resolved — who gets cloud sync

**Sync is free for any signed-in player (D-68).** It is not a Deputy Badge
benefit.

`docs/SPEC.md` previously listed cloud save as a subscriber benefit while §2a
granted sync to any signed-in player. That contradiction is closed: D-68 removes
it from the subscription list and §2a stands as written.

The reasoning is recorded in full in D-68 — it costs pennies at this scale, it is
the main reason to sign in for the majority who will never subscribe, and gating
*backup* behind a subscription reads as punitive in a product built on not being
punitive. The daily archive and per-technique statistics remain the
serious-solver benefits; D-27's rationale already named the season pass as the
load-bearing one, so nothing that carried the price was removed.

---

## 4. Build-time tooling

Not shipped in the app.

**Puzzle generation and grading** run offline in any language — Python or Rust
is fine. Only the pack format matters. Each puzzle carries its solution, its
required-technique grade, and a seed (D-32). On-device generation of a graded
expert puzzle is too slow to be felt, and grading requires running a full solver.

**AI is used in the content pipeline only.** Drafting candidate character lines
and telegram copy, and first-pass localisation. Every string is reviewed by a
human before it ships — unreviewed generated comedy in a language nobody on the
team speaks is exactly how a screenshot ends up on social media.

**No model runs at runtime.** Generation, grading, solving, and hint selection
are deterministic, verifiable, and fast. An LLM guessing that a puzzle needs an
X-wing is worthless next to a solver that knows, and the technique-grading system
in D-07 depends on being provably correct. Adaptive difficulty is specifically
rejected: secretly softening puzzles when a player struggles makes the rank
meaningless, and serious solvers notice.

---

## 5. Gap in the backlog

**Remote Config is load-bearing and was missing from the backlog.** Now closed:
`add-remote-config` is change 4, in Milestone 0, ahead of `add-ads-integration`
at 24.

The ad caps in D-24 — one interstitial per three nodes, six per session, ninety
seconds apart — must be server-controlled rather than compiled in, so they can be
tuned against retention data without shipping a release. The same applies to
season definitions.

This needs a new change in Milestone 0 or 1, before `add-ads-integration`.
Retrofitting it after the ad logic ships means touching every placement.

---

## 6. Changes from `openspec/project.md`

Three entries differ. **Done:** `openspec/project.md` now defers to this file
rather than restating the table, so the two cannot disagree again.

**Isar → Drift.** Isar's maintenance status has been unstable. An unmaintained
database for a game that must never lose a saved puzzle is a bad risk. Drift over
SQLite is boring, maintained, and comfortably fast enough for these volumes.

**AdMob → AppLovin MAX as mediator.** Mediation is where meaningful eCPM lives,
and MAX is the stronger platform for casual puzzle. AdMob stays as a demand
source inside it. This is the single change that most closes the gap with Unity's
monetisation advantage.

**Firebase → AWS.** Better fit for a backend that is mostly immutable JSON on a
CDN. Analytics and attribution move to dedicated third parties as a consequence.

**Auth added.** `project.md` predates the decision. Cognito with Apple, Google,
and Meta federation, plus a fully functional guest tier — see §2a.

**CI/CD confirmed as GitHub Actions**, with Fastlane for both stores. (This
previously cited `changes/setup-mobile-foundation/tasks.md` §7; that change was
removed from `openspec/changes/` and will be regenerated, so the citation is to
the backlog entry rather than to a change directory.)

---

## 7. Verify before committing

Three of these move, and this document has a knowledge cutoff:

- **Isar's current maintenance status** — the reason for the change may have
  resolved
- **Ad mediation platform standings** — MAX versus LevelPlay versus AdMob
  shifts, and the right answer is whichever currently fills best for casual
  puzzle
- **Rive's Flutter runtime** — confirm current version support and the state
  machine API
- **Apple's login-services review requirement** — confirm the current wording
  before submission, since it has been revised more than once

An hour of checking against current sources before writing any of this into a
proposal is worth it. The framework choice in particular is the most expensive
decision in the stack to reverse.