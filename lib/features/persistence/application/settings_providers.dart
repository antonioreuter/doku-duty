import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/application/motion_settings.dart';
import '../../mistake_model/application/strict_mode.dart';
import '../data/settings_repository.dart';
import '../domain/app_setting.dart';
import 'database_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// The **reduce effects** switch, backed by storage.
///
/// `add-design-system` deliberately shipped this as an in-memory flag and left
/// the storage to this change. It is wired here rather than in either feature
/// so that neither has to import the other: the design system knows nothing
/// about a database, and persistence knows nothing about motion.
///
/// **Hydrates after the first frame, never before it.** `build` returns the
/// documented default synchronously and the stored value arrives a moment
/// later. Blocking on a database read to decide whether to animate would put a
/// disk read on the cold-start path, and the accessibility case is already
/// covered without it — the OS reduce-motion setting is read separately and
/// synchronously, and either switch alone silences motion.
class PersistedReduceEffects extends ReduceEffects {
  @override
  bool build() {
    // Read the repository synchronously, while the provider is certainly
    // alive, then let the disk read finish on its own time.
    final repository = ref.read(settingsRepositoryProvider);
    _hydrated = _hydrate(repository);
    return super.build();
  }

  Future<void> _hydrate(SettingsRepository repository) async {
    final stored = await repository.read(AppSetting.reduceEffects);
    // The container can be gone by now — a test that finished, or a scope that
    // was torn down while the read was in flight.
    if (!ref.mounted) return;
    if (_playerHasChosen) return;
    if (stored != state) state = stored;
  }

  Future<void> _lastWrite = Future<void>.value();

  late final Future<void> _hydrated;

  /// Completes when the stored value has been read and applied, or discarded
  /// because the player got there first.
  ///
  /// Nothing in the app waits on this — that is the point of hydrating after
  /// the first frame. It exists so tests can await the read instead of guessing
  /// how long a disk takes.
  @visibleForTesting
  Future<void> get hydrated => _hydrated;

  /// Whether the player has changed the switch since this notifier was built.
  ///
  /// Hydration and a player's tap race: the disk read is in flight while the
  /// app is already interactive, and a player who flips the switch immediately
  /// would otherwise have their choice overwritten a moment later by the value
  /// that was on disk before they touched it. Whoever the player is, they are
  /// right and the disk is stale.
  bool _playerHasChosen = false;

  /// The most recent write to storage.
  ///
  /// [set] deliberately does not wait for the disk — flipping a switch must not
  /// stall on it. The future is kept so that callers who genuinely need to know
  /// the write landed, and tests that would otherwise have to guess at timing,
  /// can await it instead.
  @visibleForTesting
  Future<void> get lastWrite => _lastWrite;

  @override
  void set(bool value) {
    _playerHasChosen = true;
    super.set(value);
    _lastWrite = ref
        .read(settingsRepositoryProvider)
        .write(AppSetting.reduceEffects, value: value);
  }

  @override
  void toggle() => set(!state);
}

/// Applied at the composition root so the switch is persisted in the real app
/// and stays in memory in tests that do not want a database.
final persistedReduceEffectsOverride = reduceEffectsProvider.overrideWith(
  PersistedReduceEffects.new,
);

/// **Strict mode**, backed by storage.
///
/// The same shape as [PersistedReduceEffects] and for the same reasons — wired
/// here so that neither the mistake model nor persistence imports the other,
/// and hydrated *after* the first frame so a disk read never reaches the
/// cold-start path (D-85).
///
/// The default it returns synchronously is the safe one. A player whose stored
/// choice has not arrived yet is briefly in the non-punitive mode, which is the
/// only direction this race is allowed to go: guessing *on* for a moment would
/// flag a digit for a player who never asked (constraint 1).
class PersistedStrictMode extends StrictMode {
  @override
  bool build() {
    final repository = ref.read(settingsRepositoryProvider);
    _hydrated = _hydrate(repository);
    return super.build();
  }

  Future<void> _hydrate(SettingsRepository repository) async {
    final stored = await repository.read(AppSetting.strictMode);
    if (!ref.mounted) return;
    if (_playerHasChosen) return;
    if (stored != state) state = stored;
  }

  Future<void> _lastWrite = Future<void>.value();

  late final Future<void> _hydrated;

  /// Completes when the stored value has been read and applied, or discarded
  /// because the player got there first. Nothing in the app waits on it.
  @visibleForTesting
  Future<void> get hydrated => _hydrated;

  /// Whether the player has changed the switch since this notifier was built.
  ///
  /// Hydration and a player's tap race, and the player wins: their choice is
  /// current and the disk is stale.
  bool _playerHasChosen = false;

  /// The most recent write to storage, kept for tests and for callers that
  /// genuinely need to know it landed.
  @visibleForTesting
  Future<void> get lastWrite => _lastWrite;

  @override
  void set(bool value) {
    _playerHasChosen = true;
    super.set(value);
    _lastWrite = ref
        .read(settingsRepositoryProvider)
        .write(AppSetting.strictMode, value: value);
  }

  @override
  void toggle() => set(!state);
}

/// Applied at the composition root beside [persistedReduceEffectsOverride].
final persistedStrictModeOverride = strictModeProvider.overrideWith(
  PersistedStrictMode.new,
);
