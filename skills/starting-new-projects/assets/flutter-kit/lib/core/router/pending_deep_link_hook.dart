import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/session/sign_out_service.dart';

/// Drops a held link when a session ends, so a notification tap or link
/// held for one account is never opened for the next.
class PendingDeepLinkHook implements SignOutHook {
  const PendingDeepLinkHook(this._links);

  final PendingDeepLink _links;

  @override
  Future<void> onSignOut({required bool byUser}) async => _links.clear();
}
