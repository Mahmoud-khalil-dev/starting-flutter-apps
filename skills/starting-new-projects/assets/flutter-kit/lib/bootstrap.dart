import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/app.dart';
import 'package:kit_app/app/boot/background_boot.dart';
import 'package:kit_app/app/boot/boot_failure_screen.dart';
import 'package:kit_app/app/boot/boot_retry.dart';
import 'package:kit_app/app/boot/boot_steps.dart';
import 'package:kit_app/app/di/injector.dart';
import 'package:kit_app/app/di/modules/network_module.dart';
import 'package:kit_app/app/lifecycle_wiring.dart';
import 'package:kit_app/app/notifications_wiring.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/config/env.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/di/service_locator.dart';
import 'package:kit_app/core/error/step_guard.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/schema_version.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';

/// The composition root: validates the build's configuration, installs the
/// error handlers, then runs the boot steps in order. Anything the app needs
/// natively before its first frame (push, calls) is a step of its own, added
/// to `BootSteps`.
Future<void> bootstrap() async {
  // Outside the zone, so a bad env file stops the app loudly.
  Env.validateCurrent(isRelease: kReleaseMode);
  var reporter = bootReporter();
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      installErrorHandlers(() => reporter, ignore: (_) => false);
      final logFailure = stepFailureReporter(() => reporter);
      await runBootSteps(
        BootSteps(
          dependencies: freshDependencies(
            reset: resetLocator,
            init: initDependencies,
          ),
          session: () async {
            // The project's reporter, now that the graph is built.
            reporter = sl<CrashReporter>();
            await const SchemaVersion().ensure(sl<AppPreferences>());
            // Before the first frame, so the app opens in the user's theme,
            // language and text size.
            await sl<SettingsCubit>().load();
            await sl<SessionCubit>().restore();
          },
          runApp: () => runApp(
            App(
              router: sl<GoRouter>(),
              settings: sl<SettingsCubit>(),
              masker: sl<RecordingMasker>(),
            ),
          ),
          runFailure: (retry) =>
              runApp(BootFailureScreen(onRetry: singleFlight(retry))),
          background: () {
            late SessionRecovery recovery;
            return runBackgroundBoot(
              // The splash's Try again reaches it through the locator.
              registerRecovery: () => recovery = registerSessionRecovery(
                sl,
                session: sl<SessionCubit>(),
              ),
              wireLifecycle: () =>
                  sl<ConnectivityLifecycle>().listener = wireSessionLifecycle(
                    connectivity: sl<ConnectivityService>(),
                    recovery: recovery,
                  ),
              work: () async {
                await sl<ConnectivityService>().start();
                // After the router exists. A failure is logged by the guard
                // and never stops the app.
                final settings = sl<SettingsCubit>();
                final system = systemLanguage();
                await guardStep('notifications', () async {
                  await wireNotifications(
                    local: sl(),
                    push: sl(),
                    router: sl(),
                    channelName: channelNameFor(
                      settings.state.settings.locale,
                      system,
                    ),
                  );
                  // The channel's name follows the app's language.
                  keepChannelNameInStep(
                    local: sl(),
                    languages: settings.stream
                        .map((s) => channelLanguage(s.settings.locale, system))
                        .distinct(),
                  );
                }, log: logFailure);
              },
              refresh: () => sl<SessionCubit>().refresh(),
              log: logFailure,
            );
          },
        ),
        log: logFailure,
      );
    },
    (error, stack) =>
        unawaited(reporter.recordError(error, stack, fatal: true)),
  );
}
