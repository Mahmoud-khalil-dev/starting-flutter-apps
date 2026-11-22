import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/notifications_sign_out_hook.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:mocktail/mocktail.dart';

class _Local extends Mock implements LocalNotifications {}

class _Push extends Mock implements PushService {}

void main() {
  test('KIT-T17: signing out clears notifications and stops push', () async {
    final local = _Local();
    final push = _Push();
    when(local.cancelAll).thenAnswer((_) async {});
    when(push.stop).thenAnswer((_) async {});
    await NotificationsSignOutHook(local, push).onSignOut(byUser: true);
    verify(local.cancelAll).called(1);
    verify(push.stop).called(1);
  });

  test('KIT-T17: push stops even when clearing notifications fails', () async {
    final local = _Local();
    final push = _Push();
    when(local.cancelAll).thenAnswer((_) async => throw StateError('plugin'));
    when(push.stop).thenAnswer((_) async {});
    await expectLater(
      NotificationsSignOutHook(local, push).onSignOut(byUser: false),
      throwsStateError,
    );
    verify(push.stop).called(1);
  });

  test('KIT-T17: notifications clear even when push fails to stop', () async {
    final local = _Local();
    final push = _Push();
    when(local.cancelAll).thenAnswer((_) async {});
    when(push.stop).thenAnswer((_) async => throw StateError('vendor'));
    await expectLater(
      NotificationsSignOutHook(local, push).onSignOut(byUser: false),
      throwsStateError,
    );
    verify(local.cancelAll).called(1);
  });
}
