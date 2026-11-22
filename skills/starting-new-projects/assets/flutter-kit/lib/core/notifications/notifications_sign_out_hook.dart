import 'package:kit_app/core/notifications/local_notifications.dart';
import 'package:kit_app/core/notifications/push_service.dart';
import 'package:kit_app/core/session/sign_out_service.dart';

/// The next account must not see the last one's notifications or receive
/// its pushes. Each part runs even when the other fails; the first error
/// is rethrown for the sign-out service to swallow.
class NotificationsSignOutHook implements SignOutHook {
  const NotificationsSignOutHook(this._local, this._push);

  final LocalNotifications _local;
  final PushService _push;

  @override
  Future<void> onSignOut({required bool byUser}) async {
    try {
      await _local.cancelAll();
    } finally {
      await _push.stop();
    }
  }
}
