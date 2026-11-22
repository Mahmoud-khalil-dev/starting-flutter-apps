import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/app/boot/boot_retry.dart';
import 'package:kit_app/app/di/injector.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/di/service_locator.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Reporter extends Mock implements CrashReporter {}

/// AppLog's reporter is set by the graph, so a project that registers its
/// crash service gets AppLog.error lines there too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'KIT-T15: AppLog reports to the registered reporter, after the first '
    'boot and a retry',
    () async {
      final locator = GetIt.asNewInstance();
      addTearDown(locator.reset);
      addTearDown(AppLog.reset);
      final mine = _Reporter();
      locator.registerSingleton<CrashReporter>(mine);
      final step = freshDependencies(
        reset: () => resetLocator(locator: locator),
        init: () => initDependencies(locator: locator),
      );
      await step();
      expect(AppLog.reporter, same(mine));
      AppLog.reporter = const NoopCrashReporter();
      await step();
      expect(AppLog.reporter, same(mine));
      AppLog.error('Upload failed', StateError('x'));
      verify(
        () => mine.recordError(any(that: isA<LoggedError>()), null),
      ).called(1);
    },
  );

  test(
    'KIT-T15: with no project reporter AppLog reports to the no-op',
    () async {
      addTearDown(AppLog.reset);
      AppLog.reporter = _Reporter();
      final locator = GetIt.asNewInstance();
      addTearDown(locator.reset);
      await initDependencies(locator: locator);
      expect(AppLog.reporter, same(locator<CrashReporter>()));
    },
  );
}
