import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/platform/plugin_local_notifications.dart';
import 'package:mocktail/mocktail.dart';

class _Plugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _Android extends Mock implements AndroidFlutterLocalNotificationsPlugin {}

class _FakeSettings extends Fake implements InitializationSettings {}

class _FakeDetails extends Fake implements NotificationDetails {}

class _FakeChannel extends Fake implements AndroidNotificationChannel {}

void main() {
  late _Plugin plugin;
  late _Android android;

  setUpAll(() {
    registerFallbackValue(_FakeSettings());
    registerFallbackValue(_FakeDetails());
    registerFallbackValue(_FakeChannel());
  });

  setUp(() {
    plugin = _Plugin();
    android = _Android();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(plugin.cancelAll).thenAnswer((_) async {});
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(android);
    when(
      () => android.createNotificationChannel(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('KIT-T17: init asks for no permission and routes a tap', () async {
    String? tapped = 'unset';
    await PluginLocalNotifications(
      plugin,
    ).init(channelName: 'General', onTap: (location) => tapped = location);
    final captured = verify(
      () => plugin.initialize(
        settings: captureAny(named: 'settings'),
        onDidReceiveNotificationResponse: captureAny(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).captured;
    final settings = captured[0] as InitializationSettings;
    final ios = settings.iOS!;
    expect(ios.requestAlertPermission, isFalse);
    expect(ios.requestBadgePermission, isFalse);
    expect(ios.requestSoundPermission, isFalse);
    expect(settings.android!.defaultIcon, PluginLocalNotifications.smallIcon);
    (captured[1] as void Function(NotificationResponse))(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: '/settings',
      ),
    );
    expect(tapped, '/settings');
  });

  test(
    'KIT-T17: the small icon is the monochrome drawable, not the launcher',
    () {
      expect(PluginLocalNotifications.smallIcon, '@drawable/ic_notification');
    },
  );

  test('KIT-T17: show carries the location and the channel', () async {
    final local = PluginLocalNotifications(plugin);
    await local.init(channelName: 'General', onTap: (_) {});
    await local.show(title: 'T', body: 'B', location: '/home');
    final captured =
        verify(
              () => plugin.show(
                id: any(named: 'id'),
                title: 'T',
                body: 'B',
                notificationDetails: captureAny(named: 'notificationDetails'),
                payload: '/home',
              ),
            ).captured.single
            as NotificationDetails;
    expect(captured.android!.channelId, PluginLocalNotifications.channelId);
    expect(captured.android!.channelName, 'General');
  });

  test('KIT-T17: each notification gets its own id', () async {
    final local = PluginLocalNotifications(plugin);
    await local.init(channelName: 'General', onTap: (_) {});
    await local.show(title: 'A', body: 'a');
    await local.show(title: 'B', body: 'b');
    final ids = verify(
      () => plugin.show(
        id: captureAny(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).captured;
    expect(ids.toSet(), hasLength(2));
  });

  test('KIT-T17: cancelAll goes to the plugin', () async {
    await PluginLocalNotifications(plugin).cancelAll();
    verify(plugin.cancelAll).called(1);
  });

  test(
    'KIT-T17: a launch tap gives its location, no launch gives null',
    () async {
      final local = PluginLocalNotifications(plugin);
      when(plugin.getNotificationAppLaunchDetails).thenAnswer(
        (_) async => const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: '/settings',
          ),
        ),
      );
      expect(await local.launchLocation(), '/settings');
      when(
        plugin.getNotificationAppLaunchDetails,
      ).thenAnswer((_) async => const NotificationAppLaunchDetails(false));
      expect(await local.launchLocation(), isNull);
      when(
        plugin.getNotificationAppLaunchDetails,
      ).thenAnswer((_) async => null);
      expect(await local.launchLocation(), isNull);
    },
  );

  test(
    'KIT-T17: a new channel name re-registers the same channel id',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final local = PluginLocalNotifications(plugin);
      await local.init(channelName: 'General', onTap: (_) {});
      await local.setChannelName('عام');
      final channel =
          verify(
                () => android.createNotificationChannel(captureAny()),
              ).captured.single
              as AndroidNotificationChannel;
      expect(channel.id, PluginLocalNotifications.channelId);
      expect(channel.name, 'عام');
      await local.show(title: 'T', body: 'B');
      final details =
          verify(
                () => plugin.show(
                  id: any(named: 'id'),
                  title: any(named: 'title'),
                  body: any(named: 'body'),
                  notificationDetails: captureAny(named: 'notificationDetails'),
                  payload: any(named: 'payload'),
                ),
              ).captured.single
              as NotificationDetails;
      expect(details.android!.channelName, 'عام');
    },
  );

  test(
    'KIT-T17: off Android a new channel name only changes the name',
    () async {
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(null);
      final local = PluginLocalNotifications(plugin);
      await local.init(channelName: 'General', onTap: (_) {});
      await local.setChannelName('عام');
      verifyNever(() => android.createNotificationChannel(any()));
    },
  );
}
