import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/core/platform/link_actions.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:kit_app/core/time/app_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device services: platform, links, clock, preferences and secure storage.
Future<void> registerCoreModule(GetIt sl) async {
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerSingleton<PlatformCapabilities>(PlatformCapabilities.current())
    ..registerLazySingleton<LinkActions>(() => LinkActions(capabilities: sl()))
    ..registerSingleton<AppClock>(const SystemClock())
    ..registerSingleton<AppPreferences>(AppPreferences(prefs))
    // Default options only: a token written with other options cannot be
    // read back with these.
    ..registerSingleton<SecureStorage>(
      const SecureStorage(FlutterSecureStorage()),
    );
}
