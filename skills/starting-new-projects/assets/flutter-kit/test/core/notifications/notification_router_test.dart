import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/notifications/notification_router.dart';
import 'package:mocktail/mocktail.dart';

class _GoRouter extends Mock implements GoRouter {}

void main() {
  test('KIT-T17: only an in-app path is a safe location', () {
    expect(NotificationRouter.safeLocation('/settings'), '/settings');
    expect(NotificationRouter.safeLocation('/home?tab=2'), '/home?tab=2');
    for (final unsafe in [
      null,
      '',
      'settings',
      '//evil.example/x',
      'https://evil.example/x',
      'javascript:alert(1)',
      r'/\evil.example',
    ]) {
      expect(NotificationRouter.safeLocation(unsafe), isNull, reason: unsafe);
    }
  });

  test('KIT-T17: a tap goes to the router only when its location is safe', () {
    final router = _GoRouter();
    when(() => router.go(any())).thenReturn(null);
    NotificationRouter(router)
      ..open('/settings')
      ..open('https://evil.example/x')
      ..open(null);
    verify(() => router.go('/settings')).called(1);
    verifyNoMoreInteractions(router);
  });
}
