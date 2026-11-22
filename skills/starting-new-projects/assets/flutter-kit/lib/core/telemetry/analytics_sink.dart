import 'package:kit_app/core/session/sign_out_service.dart';

/// Where analytics events go. The kit ships [NoopAnalyticsSink]; a project
/// writes an implementation for its analytics service and registers it in
/// place of the no-op. Event names are the project's own constants: once an
/// event is live, its name must not change.
abstract interface class AnalyticsSink {
  void event(String name, {Map<String, Object>? params});

  /// Called when the signed-in user is known or changes.
  void applyUser({String? userId});

  /// Called on sign-out, after the logout event, to drop the identity.
  void onLogout();
}

/// The default: drops every event.
class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();

  @override
  void event(String name, {Map<String, Object>? params}) {}

  @override
  void applyUser({String? userId}) {}

  @override
  void onLogout() {}
}

/// Drops the analytics identity when a session ends, user or expiry alike.
/// A project that logs a logout event sends it before this runs, from its own
/// hook.
class AnalyticsSignOutHook implements SignOutHook {
  const AnalyticsSignOutHook(this._sink);

  final AnalyticsSink _sink;

  @override
  Future<void> onSignOut({required bool byUser}) async => _sink.onLogout();
}
