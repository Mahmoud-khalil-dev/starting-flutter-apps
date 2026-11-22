import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/notifications/push_service.dart';

void main() {
  test('KIT-T17: a push carries its location in data', () {
    expect(
      const PushMessage(data: {'location': '/settings'}).location,
      '/settings',
    );
    expect(const PushMessage(data: {'location': 3}).location, isNull);
    expect(const PushMessage(data: {'location': '  '}).location, isNull);
    expect(const PushMessage().location, isNull);
  });

  test('KIT-T17: the default push service is silent', () async {
    const push = NoopPushService();
    await push.start();
    expect(await push.initialMessage(), isNull);
    expect(await push.tokens.isEmpty, isTrue);
    expect(await push.foreground.isEmpty, isTrue);
    expect(await push.opened.isEmpty, isTrue);
    await push.stop();
  });
}
