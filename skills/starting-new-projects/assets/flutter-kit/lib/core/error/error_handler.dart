import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/network/api_endpoints.dart';

/// The only place a thrown error becomes a [Failure].
Failure mapDioError(Object error) {
  if (error is! DioException) return const UnknownFailure();
  switch (error.type) {
    case DioExceptionType.connectionError:
      return const NoConnection();
    case DioExceptionType.connectionTimeout:
      return const TimeoutFailure(outcomeKnown: true);
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure(outcomeKnown: false);
    case DioExceptionType.cancel:
      return const Cancelled();
    case DioExceptionType.badResponse:
      return _fromResponse(error.response);
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}

Failure _fromResponse(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final messages = backendMessages(response?.data);
  final text = messages.isEmpty ? null : messages.join('\n');
  return switch (status) {
    400 || 422 => ValidationFailure(messages),
    401 => Unauthorized(text),
    403 => Forbidden(text),
    404 => NotFound(text),
    409 => Conflict(text),
    410 when _isCodeEndpoint(response) => const CodeExpired(),
    429 => TooManyRequests(retryAfter: _retryAfter(response)),
    >= 500 => ServerFailure(status),
    _ => const UnknownFailure(),
  };
}

/// Only the code endpoints answer 410 for an expired code; elsewhere 410 keeps
/// the generic mapping.
bool _isCodeEndpoint(Response<dynamic>? response) {
  final path = response?.requestOptions.path ?? '';
  return path.endsWith(ApiEndpoints.verifyCode) ||
      path.endsWith(ApiEndpoints.resetPassword);
}

/// The seconds in `Retry-After`, or null when it is missing, a date or not
/// positive.
Duration? _retryAfter(Response<dynamic>? response) {
  final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
  return seconds == null || seconds <= 0 ? null : Duration(seconds: seconds);
}

/// The backend's `message` field, a string or a list of strings, as the
/// first client read it.
List<String> backendMessages(Object? data) {
  if (data is! Map<String, dynamic>) return const [];
  final message = data['message'];
  if (message is String) return [message];
  if (message is List) {
    return [
      for (final m in message)
        if (m is String) m,
    ];
  }
  return const [];
}

/// Runs [call] and maps any error. Repositories wrap every request in it.
Future<Either<Failure, T>> attempt<T>(Future<T> Function() call) async {
  try {
    return Right(await call());
  } on Object catch (error) {
    return Left(mapDioError(error));
  }
}
