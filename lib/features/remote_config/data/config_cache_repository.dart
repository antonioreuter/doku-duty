import 'package:drift/drift.dart';

import 'package:doku_duty/features/persistence/data/app_database.dart';

import '../domain/remote_config.dart';

/// What was cached, and the validator to send on the next fetch.
class CachedConfig {
  const CachedConfig({required this.config, required this.validator});

  final RemoteConfig config;
  final String? validator;
}

/// Keeps the last usable config so a player who was online once stays
/// configured offline afterwards.
///
/// The document is stored as fetched and re-parsed on read, not stored
/// pre-parsed. That matters across an app upgrade: the parser is where per-key
/// fallback and clamping happen, and a build with a tighter clamp or a new key
/// must apply both to a document cached by the build before it.
class ConfigCacheRepository {
  const ConfigCacheRepository(this._db);

  final AppDatabase _db;

  /// The cached config, or null if there is none or it cannot be used.
  ///
  /// Null is not a failure to report — it means the compiled-in defaults are
  /// what runs, which is a fully working app.
  Future<CachedConfig?> read() async {
    final row = await (_db.select(
      _db.configCache,
    )..where((c) => c.id.equals(ConfigCache.singletonId))).getSingleOrNull();
    if (row == null) return null;

    final parsed = RemoteConfigParser.parse(row.document);
    if (parsed == null) return null;

    return CachedConfig(config: parsed, validator: row.validator);
  }

  /// Replace the cached document.
  ///
  /// Not player state, so this inherits none of the write-on-every-change
  /// discipline that protects notes — losing it costs nothing a player would
  /// notice.
  Future<void> write({required String document, String? validator}) {
    return _db
        .into(_db.configCache)
        .insertOnConflictUpdate(
          ConfigCacheCompanion.insert(
            id: const Value(ConfigCache.singletonId),
            document: document,
            validator: Value(validator),
            fetchedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> clear() => _db.delete(_db.configCache).go();
}
