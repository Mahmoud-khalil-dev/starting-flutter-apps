import 'package:get_it/get_it.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_state.dart';

/// What the app does when the OS lets it read the token it refused before (a
/// wake-up on a locked phone). The session settles first; when it is signed
/// in, the profile refreshes. A failing refresh is logged and never escapes.
class SessionRecovery {
  SessionRecovery({required this._session});

  final SessionCubit _session;

  Future<void> onResume() async {
    if (!await _session.retryRestore()) return;
    await _settle();
  }

  /// The splash's Try again. Unlike [onResume] it also finishes a session
  /// that already signed in. A read that finds no token in the foreground
  /// signs the user out, and routing goes on normally.
  Future<void> tryAgain() async {
    await _session.retryRestore();
    await _settle();
  }

  Future<void> _settle() async {
    if (_session.state.status != SessionStatus.authenticated) return;
    await _guard('refresh', _session.refresh);
  }

  /// A failing step is logged by type only and never stops the next one.
  static Future<void> _guard(
    String what,
    Future<Object?> Function() step,
  ) async {
    try {
      await step();
    } on Object catch (error) {
      AppLog.error('Session recovery ($what) failed', error);
    }
  }
}

/// Builds the [SessionRecovery] and registers it in [locator], where the
/// splash's Try again reaches it.
SessionRecovery registerSessionRecovery(
  GetIt locator, {
  required SessionCubit session,
}) {
  final recovery = SessionRecovery(session: session);
  locator.registerSingleton<SessionRecovery>(recovery);
  return recovery;
}
