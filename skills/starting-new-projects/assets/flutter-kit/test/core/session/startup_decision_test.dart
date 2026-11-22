import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:kit_app/core/session/startup_decision.dart';

void main() {
  const justBefore = Duration(seconds: 4);
  const after = startupGrace;

  group('KIT-T10: the start-up decision never routes an unsettled session', () {
    // status, resumed, time since resume, expected
    final table = <(SessionStatus, bool, Duration, StartupAction)>[
      // Unknown and not resumed: hold with no cap, however long.
      (SessionStatus.unknown, false, Duration.zero, StartupAction.hold),
      (
        SessionStatus.unknown,
        false,
        const Duration(hours: 1),
        StartupAction.hold,
      ),
      // Unknown and resumed: hold for the grace, then the retry state.
      (SessionStatus.unknown, true, Duration.zero, StartupAction.hold),
      (SessionStatus.unknown, true, justBefore, StartupAction.hold),
      (SessionStatus.unknown, true, after, StartupAction.retry),
      (
        SessionStatus.unknown,
        true,
        const Duration(minutes: 5),
        StartupAction.retry,
      ),
      // Settled: route.
      (SessionStatus.authenticated, true, Duration.zero, StartupAction.route),
      (SessionStatus.authenticated, false, Duration.zero, StartupAction.route),
      (SessionStatus.unauthenticated, true, Duration.zero, StartupAction.route),
      (
        SessionStatus.unauthenticated,
        false,
        Duration.zero,
        StartupAction.route,
      ),
    ];

    for (final (status, resumed, since, expected) in table) {
      test('KIT-T10: $status, resumed $resumed, ${since.inSeconds}s gives '
          '$expected', () {
        expect(
          startupDecision(status: status, resumed: resumed, sinceResume: since),
          expected,
        );
      });
    }
  });
}
