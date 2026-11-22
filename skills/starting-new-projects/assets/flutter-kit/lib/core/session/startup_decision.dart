import 'package:kit_app/core/session/session_state.dart';

/// What start-up routing does next.
enum StartupAction { hold, retry, route }

/// How long the splash waits, once the app is resumed, before it shows the
/// retry state.
const startupGrace = Duration(seconds: 5);

/// How often the splash asks again while the session is unsettled.
const startupPoll = Duration(seconds: 1);

/// While the OS has not let the app read the token (a locked phone) the
/// session is `unknown`. Until it settles the splash must not pick a screen:
/// it holds while the app is not resumed (nobody sees it, so no cap), waits
/// [startupGrace] once resumed, then offers a retry. It never routes to
/// sign-in for an unsettled session.
StartupAction startupDecision({
  required SessionStatus status,
  required bool resumed,
  required Duration sinceResume,
}) {
  if (status != SessionStatus.unknown) return StartupAction.route;
  if (!resumed || sinceResume < startupGrace) return StartupAction.hold;
  return StartupAction.retry;
}
