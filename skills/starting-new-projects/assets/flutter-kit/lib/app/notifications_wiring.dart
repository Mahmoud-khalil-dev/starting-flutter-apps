import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kit_app/core/l10n/app_language.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/notification_router.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Connects taps and pushes to the router. Runs once at boot, after the
/// router exists. Returns the subscriptions so a test can cancel them.
Future<List<StreamSubscription<Object?>>> wireNotifications({
  required LocalNotifications local,
  required PushService push,
  required NotificationRouter router,
  required String channelName,
}) async {
  await local.init(channelName: channelName, onTap: router.open);
  await push.start();
  final subscriptions = <StreamSubscription<Object?>>[
    push.opened.listen((message) => router.open(message.location)),
    push.foreground.listen(
      (message) => local.show(
        title: message.title ?? '',
        body: message.body ?? '',
        location: message.location,
      ),
    ),
  ];
  final launch =
      await local.launchLocation() ?? (await push.initialMessage())?.location;
  router.open(launch);
  return subscriptions;
}

/// The language the app shows: the chosen one if the app has it, else the
/// device's ([system], `ar` or `en`).
String channelLanguage(Locale? chosen, String system) =>
    appLanguage(chosen: chosen?.languageCode, device: system);

String _channelName(String language) =>
    lookupAppLocalizations(Locale(language)).notificationChannelGeneral;

/// The channel name at start-up, in the language the app shows.
String channelNameFor(Locale? chosen, String system) =>
    _channelName(channelLanguage(chosen, system));

/// Renames the Android channel each time the app language changes. A failed
/// rename is dropped: it must never reach the zone.
StreamSubscription<String> keepChannelNameInStep({
  required LocalNotifications local,
  required Stream<String> languages,
}) => languages.listen(
  (language) => unawaited(
    local.setChannelName(_channelName(language)).catchError((Object _) {}),
  ),
);
