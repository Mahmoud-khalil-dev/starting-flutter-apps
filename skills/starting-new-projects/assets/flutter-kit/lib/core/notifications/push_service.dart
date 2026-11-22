import 'package:equatable/equatable.dart';

/// A remote notification. The app routes on `data['location']`, an in-app
/// path checked by `NotificationRouter.safeLocation`.
class PushMessage extends Equatable {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, Object?> data;

  /// Only a non-empty string is a location: a number a backend sends by
  /// mistake is no path.
  String? get location => switch (data['location']) {
    final String s when s.trim().isNotEmpty => s,
    _ => null,
  };

  @override
  List<Object?> get props => [title, body, data];
}

/// Remote push. The kit ships no vendor: [NoopPushService] is registered.
///
/// The vendor slot: implement this interface in
/// `lib/core/platform/<vendor>_push_service.dart`, register it in
/// `registerNotificationsModule` in place of the no-op, and send [tokens]
/// to the backend from the session feature. Never log a token or a
/// message's text.
abstract interface class PushService {
  /// Asks nothing by itself; ask through `Permissions` first.
  Future<void> start();

  Stream<String> get tokens;

  /// Messages that arrive while the app is open.
  Stream<PushMessage> get foreground;

  /// Messages the user tapped while the app was in the background.
  Stream<PushMessage> get opened;

  /// The message that launched the app, if any.
  Future<PushMessage?> initialMessage();

  /// Unregisters this device (sign-out). The session token is already gone
  /// when this runs: a backend call that needs it belongs in the logout
  /// request. It gets a few seconds before the sign-out moves on.
  Future<void> stop();
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> start() async {}

  @override
  Stream<String> get tokens => const Stream.empty();

  @override
  Stream<PushMessage> get foreground => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;

  @override
  Future<void> stop() async {}
}
