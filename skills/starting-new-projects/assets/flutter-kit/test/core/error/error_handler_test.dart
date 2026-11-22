import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/error_handler.dart';
import 'package:kit_app/core/error/failures.dart';

DioException _type(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

DioException _status(int status, [Object? data, String path = '/x']) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('KIT-T9: mapDioError', () {
    test('offline before sending is NoConnection', () {
      expect(
        mapDioError(_type(DioExceptionType.connectionError)),
        const NoConnection(),
      );
    });

    test(
      'a connect timeout is safe; send and receive timeouts are unknown',
      () {
        expect(
          mapDioError(_type(DioExceptionType.connectionTimeout)),
          const TimeoutFailure(outcomeKnown: true),
        );
        for (final type in [
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.transformTimeout,
        ]) {
          expect(
            mapDioError(_type(type)),
            const TimeoutFailure(outcomeKnown: false),
          );
        }
      },
    );

    test('cancel, bad certificate and unknown', () {
      expect(mapDioError(_type(DioExceptionType.cancel)), const Cancelled());
      expect(
        mapDioError(_type(DioExceptionType.badCertificate)),
        const UnknownFailure(),
      );
      expect(
        mapDioError(_type(DioExceptionType.unknown)),
        const UnknownFailure(),
      );
      expect(mapDioError(StateError('x')), const UnknownFailure());
    });

    test('statuses map to their failures', () {
      expect(
        mapDioError(
          _status(400, {
            'message': ['a', 'b'],
          }),
        ),
        const ValidationFailure(['a', 'b']),
      );
      expect(
        mapDioError(_status(422, {'message': 'c'})),
        const ValidationFailure(['c']),
      );
      expect(
        mapDioError(_status(401, {'message': 'expired'})),
        const Unauthorized('expired'),
      );
      expect(mapDioError(_status(403)), const Forbidden());
      expect(
        mapDioError(_status(404, {'message': 'gone'})),
        const NotFound('gone'),
      );
      expect(
        mapDioError(_status(409, {'message': 'taken'})),
        const Conflict('taken'),
      );
      expect(mapDioError(_status(500)), const ServerFailure(500));
      expect(mapDioError(_status(503)), const ServerFailure(503));
      expect(mapDioError(_status(418)), const UnknownFailure());
    });

    test('backend messages are read from the message field', () {
      expect(backendMessages('<html>'), isEmpty);
      expect(backendMessages({'message': 3}), isEmpty);
      expect(
        backendMessages({
          'message': ['a', 2],
        }),
        ['a'],
      );
      expect(backendMessages({'message': 'b'}), ['b']);
    });

    test('attempt wraps success in Right and errors in Left', () async {
      expect(await attempt(() async => 1), const Right<Failure, int>(1));
      expect(
        await attempt<int>(
          () async => throw _type(DioExceptionType.connectionError),
        ),
        const Left<Failure, int>(NoConnection()),
      );
    });
  });

  group('KIT-T16: mapDioError rate limit and expiry', () {
    DioException withHeader(int status, String? retryAfter) {
      final options = RequestOptions(path: '/x');
      return DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: status,
          headers: Headers.fromMap({
            if (retryAfter != null) 'retry-after': [retryAfter],
          }),
        ),
      );
    }

    test('KIT-T16: 429 is TooManyRequests and reads Retry-After', () {
      expect(
        mapDioError(withHeader(429, '90')),
        const TooManyRequests(retryAfter: Duration(seconds: 90)),
      );
    });

    test('KIT-T16: 429 without a usable Retry-After has no wait', () {
      for (final header in [null, 'soon', '-5', '0']) {
        expect(
          mapDioError(withHeader(429, header)),
          const TooManyRequests(),
          reason: '$header',
        );
      }
    });

    test('KIT-T16: 410 on a code endpoint is an expired code', () {
      for (final path in ['/verify-code', '/reset-password']) {
        expect(mapDioError(_status(410, null, path)), const CodeExpired());
      }
    });

    test('KIT-T16: 410 elsewhere keeps the generic mapping', () {
      expect(mapDioError(_status(410)), const UnknownFailure());
      expect(
        mapDioError(_status(410, null, '/resend-code')),
        const UnknownFailure(),
      );
    });
  });
}
