import 'package:kit_app/core/error/step_guard.dart';
import 'package:kit_app/core/storage/app_preferences.dart';

/// Keeps a stamp of the storage layout and runs the migrations a layout
/// change needs.
class SchemaVersion {
  const SchemaVersion();

  /// The layout this build writes. Raise it when a persisted key changes,
  /// and add the migration that moves old data.
  static const current = 1;

  /// Runs each migration keyed above the stored version, lowest first. A
  /// migration keyed N moves the data to layout N, and the stamp follows
  /// each one that succeeds, so a retry resumes where the last run stopped:
  /// write each migration to be safe to run twice. After the last one the
  /// stamp is [current], or the highest key if that is higher. A stamp from
  /// a newer build is never lowered. Never throws: a failure stops the
  /// run, is logged by type only, and leaves the stamp where it was.
  Future<void> ensure(
    AppPreferences prefs, {
    Map<int, Future<void> Function()> migrations = const {},
  }) async {
    try {
      final stored = prefs.storageSchema;
      final pending = migrations.keys.where((v) => v > stored).toList()..sort();
      for (final version in pending) {
        await migrations[version]!();
        await prefs.setStorageSchema(version);
      }
      final target = pending.isEmpty || pending.last < current
          ? current
          : pending.last;
      if (target > prefs.storageSchema) await prefs.setStorageSchema(target);
    } on Object catch (error) {
      logStepFailure('schema migration', error);
    }
  }
}
