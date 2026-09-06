import 'package:drift/drift.dart';

import '../domain/app_setting.dart';
import 'app_database.dart';

/// Reads and writes player settings.
///
/// Every read falls back to [AppSetting.defaultValue], so a fresh install and a
/// player who has never opened settings behave identically — and both get the
/// non-punitive defaults constraint 1 requires.
class SettingsRepository {
  const SettingsRepository(this._db);

  final AppDatabase _db;

  Future<bool> read(AppSetting setting) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(setting.key))).getSingleOrNull();
    return row?.boolValue ?? setting.defaultValue;
  }

  Future<void> write(AppSetting setting, {required bool value}) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: setting.key,
            boolValue: value,
            updatedAt: Value(DateTime.now()),
            pendingUpload: const Value(true),
          ),
        );
  }

  /// Forget a choice, returning the setting to its default.
  Future<void> reset(AppSetting setting) {
    return (_db.delete(
      _db.settings,
    )..where((s) => s.key.equals(setting.key))).go();
  }

  Future<Map<AppSetting, bool>> readAll() async {
    final rows = await _db.select(_db.settings).get();
    final stored = <String, bool>{
      for (final row in rows) row.key: row.boolValue,
    };
    return <AppSetting, bool>{
      for (final setting in AppSetting.values)
        setting: stored[setting.key] ?? setting.defaultValue,
    };
  }
}
