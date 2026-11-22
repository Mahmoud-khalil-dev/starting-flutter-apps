import 'package:equatable/equatable.dart';

/// Every way a backend call can fail. Repositories return these through
/// Either; nothing above the data layer sees a DioException.
sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

/// Offline before sending: nothing reached the server, so a retry is safe.
final class NoConnection extends Failure {
  const NoConnection();
}

/// The request timed out. A connect timeout reached nothing
/// ([outcomeKnown] is true). A send or receive timeout may have reached the
/// server, so an order or transfer re-reads server state before a retry.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({required this.outcomeKnown});

  final bool outcomeKnown;

  @override
  List<Object?> get props => [outcomeKnown];
}

final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode);

  final int statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// 401. The API has no refresh token, so the session ends.
final class Unauthorized extends Failure {
  const Unauthorized([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

final class Forbidden extends Failure {
  const Forbidden([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

final class NotFound extends Failure {
  const NotFound([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// 400 or 422, with the backend's messages, localized by Accept-Language.
final class ValidationFailure extends Failure {
  const ValidationFailure(this.messages);

  final List<String> messages;

  @override
  List<Object?> get props => [messages];
}

/// 409. The thing changed under the user: a taken name, a slot someone else
/// took.
final class Conflict extends Failure {
  const Conflict([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// 429. [retryAfter] is the wait the server asked for (the `Retry-After`
/// header in seconds), or null when it gave none.
final class TooManyRequests extends Failure {
  const TooManyRequests({this.retryAfter});

  final Duration? retryAfter;

  @override
  List<Object?> get props => [retryAfter];
}

/// 410. The kit reads it as "this one-time code has expired"; a project whose
/// API signals that another way remaps it in its remote source.
final class CodeExpired extends Failure {
  const CodeExpired();
}

final class Cancelled extends Failure {
  const Cancelled();
}

final class UnknownFailure extends Failure {
  const UnknownFailure();
}
