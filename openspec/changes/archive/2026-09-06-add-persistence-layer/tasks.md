# Tasks — add-persistence-layer

Note storage is part of the notes logic that `openspec/config.yaml` names under
`rules.tasks`, so it is written test-first — not as a preference, but because
constraint 9 has no visible symptom when it breaks. A batched write looks
identical to a correct one until a player loses a board.

Two guarantees are worth stating before the list, because everything else is
arranged around them: **a note write completes inside the action that caused it**,
and **a failure to read storage never stops the app being playable**.

## 1. The database exists

- [x] 1.1 Add `drift` and `drift_flutter` to dependencies and `drift_dev` and
      `build_runner` to dev dependencies. Versions confirmed against pub.dev at
      implementation time, not copied from the proposal — `docs/TECH_STACK.md` §7
      is explicit that this document has a knowledge cutoff.
- [x] 1.2 Configure `build.yaml` with the database path so `drift_dev` can find
      it, which `make-migrations` needs later.
- [x] 1.3 Create the database class opened through `driftDatabase(name:)`, with a
      second constructor taking an in-memory connection for tests.
- [x] 1.4 Test: an in-memory database opens, reports schema version 1, and closes.
- [x] 1.5 Expose it through the existing Riverpod container, opened lazily on
      first read rather than during `bootstrap`.
- [x] 1.6 Test: building the app shell does not open the database. This is the
      cold-start guarantee, and it is easy to lose by adding one eager `watch`.

## 2. The note model, test-first

- [x] 2.1 Write the failing test for the note row: a candidate is identified by
      its digit and its cell, carries its kind (**settled** or **provisional**),
      and carries whether it was entered by the player or generated (D-15, D-11).
- [x] 2.2 Implement the note table to satisfy it.
- [x] 2.3 Write the failing test that a removed candidate leaves the others'
      identities untouched — no list index, no compaction, nothing that could
      make a reload reflow the board (D-10, constraint 3).
- [x] 2.4 Make it pass.
- [x] 2.5 Test: clearing all provisional marks in one action removes every
      **provisional note** and no **settled note** (D-11).
- [x] 2.6 Test: manual and generated notes in the same cell remain
      distinguishable in storage.

## 3. Write on every change — constraint 9

- [x] 3.1 Write the failing test: after a single note change, the value is
      readable from a *separate* connection to the same database. Reading back
      through the same object would pass on a cache and prove nothing.
- [x] 3.2 Implement the write path to satisfy it.
- [x] 3.3 Write the guard against the failure mode: a test that fails if any
      debounce, batch, periodic flush, or lifecycle hook sits between a note
      change and its write. Assert the shape, not the timing — a timing test that
      passes on a fast machine is how this regresses.
- [x] 3.4 Test: a burst of note changes in quick succession all land, none is
      coalesced, and the last is as durable as the first.
- [x] 3.5 Test: the caller is not made to wait for the write to be acknowledged
      before the next input is accepted (constraint 2).
- [x] 3.6 Prove the guard bites: temporarily batch the writes, confirm 3.3 and
      3.4 fail and name the problem, then revert. A guard nobody has seen fail is
      not yet a guard.

## 4. Save state and resume

- [x] 4.1 Test-first: a puzzle save holds placed values, both note kinds, and
      elapsed time, keyed so exactly one save exists per puzzle.
- [x] 4.2 Implement it.
- [x] 4.3 Test: elapsed time resumes from where it stopped, and time with the app
      closed is not counted (D-06 — it is display-only, so it must at least be
      honest).
- [x] 4.4 Test: completing a puzzle stops it being offered for resume.
- [x] 4.5 Test: a value placed over a cell that had notes leaves storage in the
      state D-16 assumes — a cell holds a value or notes, never both.

## 5. Packs

- [x] 5.1 Test-first: a pack row carries its identity and version, and a puzzle
      row carries clues, solution, **rank**, and seed (D-32).
- [x] 5.2 Implement the pack and puzzle tables.
- [x] 5.3 Test: requesting a puzzle of a **rank** with none available reports
      absence as a normal result, not an error. Change 5 has to top up on this
      signal, and an exception is the wrong shape for a routine condition.
- [x] 5.4 Test: installing a newer pack version preserves which puzzles the
      player has already solved.
- [x] 5.5 Seed one small fixture pack for tests. Not real content — real packs
      are generated offline and are change 5's business.

## 6. Statistics

- [x] 6.1 Test-first: lifetime counters and per-technique counters, using the
      technique names from D-57's table rather than an invented list.
- [x] 6.2 Implement them.
- [x] 6.3 Test: statistics survive a **season** rotating out (D-17).
- [x] 6.4 Test: counters are updated durably as part of completing a puzzle.

## 7. Settings

- [x] 7.1 Implement the settings store with typed accessors and documented
      defaults.
- [x] 7.2 Test: an unset setting returns its default, and for **strict mode** and
      auto-check that default is **off** (D-04, constraint 1). This is the single
      most important default in the product; assert it rather than assume it.
- [x] 7.3 Wire **reduce effects** to this store, replacing the in-memory
      default that `add-design-system` deliberately left unpersisted.
- [x] 7.4 Test: the reduce-effects switch survives a restart, and the OS
      reduce-motion setting is still independent of it.

## 8. Sync metadata

- [x] 8.1 Test-first: writing any syncable row updates its last-modified stamp
      and marks it pending upload.
- [x] 8.2 Implement it, and record the device a save originated on.
- [x] 8.3 Test: with no account and no network, the metadata is maintained and
      nothing attempts to send it, prompt for sign-in, or behave differently.
- [x] 8.4 Write down, in the persistence code, that the §2a rules — never merge
      automatically, never delete local until upload confirms — are what these
      fields exist for. The sync change is far enough away that the reason will
      not be obvious from the columns.

## 9. Failing safely

- [x] 9.1 Test: a corrupt database file results in an empty database and a
      playable app — no dialog, no error screen, no failure state (D-03).
- [x] 9.2 Test: a failed migration takes the same path rather than leaving the
      app unable to start.
- [x] 9.3 Test: after a reset, no stale puzzle is offered for resume.
- [x] 9.4 Report the reset to the crash reporter the shell already installed, so
      it is diagnosable, and confirm the player is shown nothing.

## 10. Migrations, exercised at version 1

- [x] 10.1 Run `dart run drift_dev make-migrations` to produce the schema
      snapshot for version 1 and the generated migration test scaffolding.
- [x] 10.2 Commit the snapshot. It is the baseline every later migration test
      compares against, and it cannot be reconstructed after the schema moves.
- [x] 10.3 Add a throwaway version 2 — one nullable column — generate its
      migration and test, confirm the test passes and that saved state survives,
      then revert it. The mechanism is proven once here so that the first real
      migration is not also the first attempt.
- [x] 10.4 Document in the database class that a schema change requires a new
      snapshot and a migration test, and that shipping without one risks the
      saved games D-33 exists to protect.

## 11. Correct the stale backlog line

- [x] 11.1 `openspec/BACKLOG.md` item 3 still says "Isar schemas".
      `docs/TECH_STACK.md` §6 replaced Isar with Drift and is canonical for the
      stack. Correct the line and its "Watch for" note.
- [x] 11.2 Confirm no other document still names Isar as the local store:
      `grep -rn "Isar" docs openspec CLAUDE.md`. Leave `docs/TECH_STACK.md` §6
      and §7 alone — they are the record of the change and must keep the name.

## Platform checks

Verified by `integration_test/persistence_test.dart` running on an Android
emulator (Pixel 10 Pro, API 37) and an iOS simulator (iPhone 17 Pro, iOS 26.5).
Both were run **twice**, with the app process killed in between, because a write
surviving a dead process cannot be tested any other way — the process that dies
has to be a real one.

The simulator is honest for this particular check, unlike the haptics in change
2: database path resolution and native sqlite are the same code on an emulator
as on hardware.

- [x] Verified on iOS: the database is created in the application-support
      directory, a note and a save round-trip through a closed and reopened
      database, and both are still there in a new process. The directory had to
      be set explicitly — `drift_flutter` defaults to Documents, which on iOS is
      iCloud-backed user-facing space (D-78)
- [x] Verified on Android: the same three checks, with `adb shell am force-stop`
      between the two runs — a real process kill, not an orderly shutdown
- [x] Both platforms: the app launches on a fresh install with no database
      present, because nothing on the first-frame path opens one. Confirmed by
      inspecting the Android app's `files/` directory after launch, and by the
      emulator being in airplane mode throughout
- [x] Cold start is unaffected: the shell reaches its first frame without
      constructing the database at all, which `lazy_open_test.dart` asserts and
      the on-device launch confirms
- [x] Accessibility: this change renders nothing, so there is no contrast,
      dynamic type, motion, or colour cue to check. Recorded rather than
      silently skipped. The one player-visible behaviour is the absence of an
      error screen when storage fails, which task 9.1 covers

### What the on-device test found that no host test could

Every host test passed while the app was completely unable to open its database
on Android: `dlopen failed: library "libsqlite3.so" not found`. The test host
links the OS's own sqlite, so the missing Android library is invisible there.

Fixed by holding drift on the 2.31.x line, which bundles through
`sqlite3_flutter_libs` rather than through Dart build hooks (D-77). The
one-command check, worth repeating before any drift upgrade:

    flutter build apk --flavor dev -t lib/main_dev.dart --debug
    unzip -l build/app/outputs/flutter-apk/app-dev-debug.apk | grep libsqlite3
