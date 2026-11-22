import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';

class PluginLocalNotifications implements LocalNotifications {
  PluginLocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// The Android channel id: a project setting. Pick it once, before the
  /// first release, and never change it afterwards: users' channel settings
  /// are stored under it. Keep it the same as the `channelId` a push vendor
  /// names in its payload, if the project has one.
  static const channelId = 'general';

  /// The small icon in the status bar: a monochrome drawable the kit ships in
  /// `android/app/src/main/res/drawable/ic_notification.xml`. Replace its
  /// shape with the product's mark, keeping it one flat colour. The launcher
  /// icon would show as a white square on many devices.
  static const smallIcon = '@drawable/ic_notification';

  final FlutterLocalNotificationsPlugin _plugin;
  late String _channelName;
  var _next = 0;

  @override
  Future<void> init({
    required String channelName,
    required void Function(String? location) onTap,
  }) async {
    _channelName = channelName;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(smallIcon),
        // Permission is asked through `Permissions`, never at start-up.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  @override
  Future<void> show({
    required String title,
    required String body,
    String? location,
  }) => _plugin.show(
    id: _next++,
    title: title,
    body: body,
    payload: location,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(channelId, _channelName),
      iOS: const DarwinNotificationDetails(),
    ),
  );

  @override
  Future<void> setChannelName(String channelName) async {
    _channelName = channelName;
    // Same id, new name: Android keeps the user's channel settings.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(channelId, channelName),
        );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<String?> launchLocation() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }
}
