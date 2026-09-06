# Tasks — add-remote-config

None of the load-bearing pure-logic systems named in `openspec/config.yaml` under
`rules.tasks` appears here. Two things are still written test-first, because both
are guarantees rather than features: **a value is always answerable**, and **a
remote config can only tighten the ad caps, never loosen them**.

The second is the one to get right. Nothing reads it until change 24, so a
mistake here is invisible for twenty changes and then becomes an ad volume
nobody approved.

## 1. The value set and its defaults

- [x] 1.1 Define the configurable values as a closed set with a compiled-in
      default each — the same shape as `AppSetting` in the persistence layer, for
      the same reason: defaults in one place cannot drift.
- [x] 1.2 Populate it with the D-24 ad caps only: interstitials per completed
      nodes, minimum seconds between interstitials, maximum per session.
- [x] 1.3 Test: the compiled-in defaults are exactly D-24's numbers — one per
      three nodes, ninety seconds, six per session. Assert the numbers, not a
      relationship, so a later edit has to change a test that names them.
- [x] 1.4 Test: enumerating the set contains nothing that could affect ad
      *placement* — no key about puzzles, celebrations, taps, or node types.
      This is the guard for constraint 6; write it before there is anything to
      guard, because afterwards nobody will think to.

## 2. Clamping, test-first

- [x] 2.1 Write the failing test: a config loosening any cap beyond D-24 is
      rejected and the documented limit stays in effect. Cover each of the three
      independently — a config can be wrong about one and right about the others.
- [x] 2.2 Write the failing test: a config tightening a cap is accepted.
- [x] 2.3 Implement the clamp.
- [x] 2.4 Test the boundary in both directions: exactly D-24's value is accepted,
      one step looser is rejected, one step stricter is accepted.
- [x] 2.5 Test the degenerate values a real config file will eventually contain by
      accident: zero, negative, and absurdly large. None may produce a looser
      limit than D-24, and none may crash a read.
- [x] 2.6 Prove the guard bites: temporarily remove the clamp, confirm 2.1 fails
      and names the value, then restore it.

## 3. Parsing, one key at a time

- [x] 3.1 Write the failing test: a config carrying an unknown key still applies
      every known key.
- [x] 3.2 Write the failing test: one malformed value falls back on its own and
      the rest of the config still applies.
- [x] 3.3 Implement the parser to satisfy both. Per-key, never all-or-nothing.
- [x] 3.4 Test: a config with a schema version the app does not recognise is
      still parsed per-key, and the version is recorded so it can be told apart
      from corruption.
- [x] 3.5 Test: an empty object, an array where an object was expected, and a
      truncated document each leave the previous values in effect.

## 4. Reading

- [x] 4.1 Implement the typed accessors, reading from memory so a caller never
      awaits.
- [x] 4.2 Test: every value is readable before any fetch has happened, and
      returns its compiled-in default.
- [x] 4.3 Test: reading is synchronous. Assert the accessor's return type is not
      a future — a signature test, because the day someone makes it async is the
      day an ad placement starts awaiting.
- [x] 4.4 Expose it through the existing Riverpod container.

## 5. Fetching

- [x] 5.1 Define the transport as a small injected interface. No package: a
      single GET does not justify one, and the seam is what makes every test
      here run without a network.
- [x] 5.2 Implement the real transport on `dart:io`'s `HttpClient`, with the URL
      supplied at build time by environment rather than committed.
- [x] 5.3 Send a conditional request when a previous response's validator is
      known, so the CDN's short TTL costs a round trip and not a payload.
- [x] 5.4 Test with a fake transport: a successful fetch replaces the values in
      effect.
- [x] 5.5 Test: a failure, a timeout, an error status, and an empty body each
      leave the previous values untouched.
- [x] 5.6 Test: the fetch is bounded — a transport that never answers does not
      leave anything waiting forever.
- [x] 5.7 Test: a failed fetch reports to the crash reporter and shows the player
      nothing. The second half is the requirement; the first is what makes it
      diagnosable.

## 6. Cache, and the first real migration

- [x] 6.1 Add the config cache table, bumping the database to **schema version
      2**. Read the migration steps documented on `AppDatabase` — this is the
      first real migration and the mechanism was exercised at version 1 for it.
- [x] 6.2 Run `flutter pub run drift_dev make-migrations`, wire the
      `MigrationStrategy`, and commit the version 2 snapshot alongside version 1.
- [x] 6.3 Run the generated migration test. It must pass both the schema check
      and the data-integrity check.
- [x] 6.4 Test explicitly that a puzzle in progress, its notes, statistics, and
      settings all survive the upgrade. The generated test covers the schema; this
      covers the thing D-33 exists to protect.
- [x] 6.5 Test: a fetched config is retained and is in effect on the next launch,
      read back through a separate connection rather than the one that wrote it.
- [x] 6.6 Test: an unreadable cached config falls back to the compiled-in values
      and the app continues.

## 7. Startup wiring

- [x] 7.1 Start the fetch after the first frame, not before it.
- [x] 7.2 Test: building the app shell performs no fetch and opens no transport.
      The same shape as the lazy-open test in the persistence layer, and it
      regresses the same way — one eager `watch`.
- [x] 7.3 Test: a config arriving mid-session replaces the values in effect
      without disturbing anything on screen.
- [x] 7.4 Confirm nothing was added to the first-frame path and cold start is
      unchanged.
- [x] 7.5 `flutter analyze` clean and `dart format --set-exit-if-changed` passing.

## 8. Write down what is not in the client

- [x] 8.1 Record in the code where the config is expected to live and what shape
      it has, so whoever creates the bucket has a specification rather than a
      guess: the URL's build-time variable, the JSON shape, the schema version
      field, and the cache headers the client assumes.
- [x] 8.2 Add a fixture config under test data that is byte-for-byte what the
      real file should look like, so the first upload can be checked against
      something rather than written from memory.
- [x] 8.3 Note in `openspec/BACKLOG.md` against change 24 that the caps are
      already remotely tunable and clamped, so that change consumes them rather
      than re-deciding.

## Platform checks

Verified by `integration_test/remote_config_test.dart` on an Android emulator
(Pixel 10 Pro, API 37) and an iOS simulator (iPhone 17 Pro, iOS 26.5), against a
real HTTP server on the device rather than a fake transport.

- [x] Verified on iOS: a real fetch succeeds through the platform's own
      networking stack, the document is cached and re-read, a config trying to
      loosen a cap is clamped on the device exactly as in a unit test, and an
      unreachable endpoint leaves the compiled-in values in effect with nothing
      shown
- [x] Verified on Android: the same four checks. HTTPS is the default on both
      platforms and the real endpoint will be HTTPS, so no cleartext exception
      was added — `PUBLISHING.md` records that a plaintext endpoint would need
      an ATS exception on iOS and a network security configuration on Android,
      and that it should not get either
- [x] Both platforms: the device database opens at **schema version 2** and the
      version 2 table is present and usable
- [x] Cold start is unaffected. The refresh runs from a post-frame callback, and
      `first_frame_test.dart` asserts it stays after `runApp` and is never
      awaited
- [x] Accessibility: this change renders nothing, so there is no contrast,
      dynamic type, motion, or colour cue to check. Recorded rather than
      silently skipped — the only player-visible behaviour is the absence of any
      sign that a fetch happened or failed

### The migration check, and why it could not be run the way it was written

The task asked to install the previous build, create state, install this one,
and confirm the state survived. That was run, and it produced a more useful
answer than expected: **the previous build creates no database at all.**

The committed build was checked out, built, installed, and launched, and its
`files/` directory was empty afterwards. Nothing in it ever opened the store —
`add-persistence-layer` shipped the layer, and `lazy_open_test.dart` deliberately
asserts the shell does not touch it, so until this change added a consumer there
was nothing to trigger a create. This change is the first thing that opens the
database on a device.

So there is no version 1 database in the world to migrate, and there never will
be: nothing is released, and the build that would have written one does not.

What that leaves, and it is not nothing: the v1 to v2 migration is exercised on
the host by drift's schema verifier, which builds a genuine version 1 database,
populates it with a part-solved puzzle, two notes of different kinds, lifetime
and per-technique statistics, and a non-default setting, migrates it, and
compares every row. That is in `test/drift/app_database/migration_test.dart`,
adopted from the generated template as its own TODO asks. It is a real
migration over real rows; what it is not is a real device.

The first migration a player will actually take is whichever one follows the
first release, and that one has a database to migrate.

### A finding about the schema snapshots

The version 1 snapshot was generated by `drift_dev` **2.34.0**; version 2 by
**2.31.0**, because D-77 pinned the toolchain down after v1 was committed. Both
work and the migration tests pass, but the generated helper classes differ:
v1 exposes sqlite's storage types (`String`, `int`) and v2 the mapped ones
(`DateTime`, `bool`), which is why the data-integrity test writes each side to
its own shape.

Regenerating the v1 snapshot under the pinned toolchain would make the baseline
match the tools that will read it from now on. It is free today — nothing has
shipped, so no database anywhere is described by it — and it stops being free at
the first release. Left alone here because rewriting a committed migration
baseline is a decision, not a tidy-up.
