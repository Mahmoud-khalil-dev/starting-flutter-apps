/// Notifications the app shows itself (a foreground push, a reminder).
abstract interface class LocalNotifications {
  /// [channelName] is the Android channel's visible name, localized.
  Future<void> init({
    required String channelName,
    required void Function(String? location) onTap,
  });

  Future<void> show({
    required String title,
    required String body,
    String? location,
  });

  /// Renames the Android channel in the app's language, keeping its id (the
  /// user's channel settings stay). Nothing elsewhere.
  Future<void> setChannelName(String channelName);

  Future<void> cancelAll();

  /// The location of the notification that launched the app, if any.
  Future<String?> launchLocation();
}

/// The web build and tests.
class NoopLocalNotifications implements LocalNotifications {
  const NoopLocalNotifications();

  @override
  Future<void> init({
    required String channelName,
    required void Function(String? location) onTap,
  }) async {}

  @override
  Future<void> show({
    required String title,
    required String body,
    String? location,
  }) async {}

  @override
  Future<void> setChannelName(String channelName) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<String?> launchLocation() async => null;
}
