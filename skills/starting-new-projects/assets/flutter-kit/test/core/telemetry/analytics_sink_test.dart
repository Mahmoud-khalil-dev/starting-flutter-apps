import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/telemetry/analytics_sink.dart';
import 'package:mocktail/mocktail.dart';

class _MockSink extends Mock implements AnalyticsSink {}

void main() {
  test('KIT-T9: the no-op sink accepts every call', () {
    const AnalyticsSink sink = NoopAnalyticsSink();
    expect(() {
      sink
        ..event('opened', params: {'a': 1})
        ..applyUser(userId: 'u1')
        ..onLogout();
    }, returnsNormally);
  });

  test(
    'KIT-T10: a sign-out drops the analytics identity, by user or not',
    () async {
      final sink = _MockSink();
      await AnalyticsSignOutHook(sink).onSignOut(byUser: true);
      await AnalyticsSignOutHook(sink).onSignOut(byUser: false);
      verify(sink.onLogout).called(2);
      verifyNever(() => sink.event(any(), params: any(named: 'params')));
    },
  );
}
