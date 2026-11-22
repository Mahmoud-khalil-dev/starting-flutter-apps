import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/notifications_wiring.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/notification_router.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:mocktail/mocktail.dart';

class _Local extends Mock implements LocalNotifications {}

class _Push extends Mock implements PushService {}

class _Router extends Mock implements NotificationRouter {}

void main() {
  late _Local local;
  late _Push push;
  late _Router router;
  late StreamController<PushMessage> foreground;
  late StreamController<PushMessage> opened;
  void Function(String?)? onTap;

  setUp(() {
    local = _Local();
    push = _Push();
    router = _Router();
    foreground = StreamController<PushMessage>();
    opened = StreamController<PushMessage>();
    when(
      () => local.init(
        channelName: any(named: 'channelName'),
        onTap: any(named: 'onTap'),
      ),
    ).thenAnswer((call) async {
      onTap = call.namedArguments[#onTap] as void Function(String?);
    });
    when(local.launchLocation).thenAnswer((_) async => null);
    when(
      () => local.show(
        title: any(named: 'title'),
        body: any(named: 'body'),
        location: any(named: 'location'),
      ),
    ).thenAnswer((_) async {});
    when(push.start).thenAnswer((_) async {});
    when(push.initialMessage).thenAnswer((_) async => null);
    when(() => push.foreground).thenAnswer((_) => foreground.stream);
    when(() => push.opened).thenAnswer((_) => opened.stream);
  });

  Future<void> wire() async {
    final subscriptions = await wireNotifications(
      local: local,
      push: push,
      router: router,
      channelName: 'General',
    );
    addTearDown(() async {
      for (final s in subscriptions) {
        await s.cancel();
      }
    });
  }

  test('KIT-T17: a tap on a local notification opens its location', () async {
    await wire();
    onTap!('/settings');
    verify(() => router.open('/settings')).called(1);
  });

  test('KIT-T17: a push in the foreground shows as a local one', () async {
    await wire();
    foreground.add(
      const PushMessage(title: 'T', body: 'B', data: {'location': '/home'}),
    );
    await pumpEventQueue();
    verify(
      () => local.show(title: 'T', body: 'B', location: '/home'),
    ).called(1);
  });

  test('KIT-T17: an opened push and a launch tap both route', () async {
    when(local.launchLocation).thenAnswer((_) async => '/settings');
    await wire();
    verify(() => router.open('/settings')).called(1);
    opened.add(const PushMessage(data: {'location': '/home'}));
    await pumpEventQueue();
    verify(() => router.open('/home')).called(1);
  });

  test('KIT-T17: a push that launched the app routes once', () async {
    when(
      push.initialMessage,
    ).thenAnswer((_) async => const PushMessage(data: {'location': '/home'}));
    await wire();
    verify(() => router.open('/home')).called(1);
  });

  test(
    'KIT-T17: with nothing to open at launch the router gets null',
    () async {
      await wire();
      verify(() => router.open(null)).called(1);
    },
  );

  test('KIT-T17: a push with no text still shows as a quiet one', () async {
    await wire();
    foreground.add(const PushMessage());
    await pumpEventQueue();
    verify(() => local.show(title: '', body: '')).called(1);
  });

  test('KIT-T17: the channel is named in the language the app shows', () {
    expect(channelLanguage(const Locale('ar'), 'en'), 'ar');
    expect(channelLanguage(const Locale('en'), 'ar'), 'en');
    // No choice: the device language.
    expect(channelLanguage(null, 'ar'), 'ar');
    expect(channelLanguage(null, 'en'), 'en');
    // A language the app lacks follows the device.
    expect(channelLanguage(const Locale('fr'), 'ar'), 'ar');
  });

  test('KIT-T17: a change of app language renames the channel', () async {
    when(() => local.setChannelName(any())).thenAnswer((_) async {});
    final languages = StreamController<String>();
    addTearDown(languages.close);
    final subscription = keepChannelNameInStep(
      local: local,
      languages: languages.stream,
    );
    addTearDown(subscription.cancel);
    languages.add('ar');
    await pumpEventQueue();
    verify(() => local.setChannelName('عام')).called(1);
    languages.add('en');
    await pumpEventQueue();
    verify(() => local.setChannelName('General')).called(1);
  });

  test('KIT-T17: a failed rename never reaches the zone', () async {
    when(
      () => local.setChannelName(any()),
    ).thenAnswer((_) async => throw StateError('plugin'));
    final languages = StreamController<String>();
    addTearDown(languages.close);
    final uncaught = <Object>[];
    await runZonedGuarded(() async {
      final subscription = keepChannelNameInStep(
        local: local,
        languages: languages.stream,
      );
      addTearDown(subscription.cancel);
      languages.add('ar');
      await pumpEventQueue();
    }, (error, _) => uncaught.add(error));
    expect(uncaught, isEmpty);
  });
}
