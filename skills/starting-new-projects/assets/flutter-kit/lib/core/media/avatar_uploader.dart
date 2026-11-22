import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:kit_app/core/error/error_handler.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/session_user.dart';

abstract interface class AvatarUploader {
  /// [onProgress] gets the sent fraction, 0 to 1.
  Future<Either<Failure, Unit>> upload(
    PickedImage image, {
    required void Function(double fraction) onProgress,
    CancelToken? cancelToken,
  });
}

/// Posts the photo as multipart and saves the user the API returns. The
/// body factory lets the retry policy send a fresh body on a retry. A reply
/// that lands after the session ended or changed is not saved, so one
/// account's photo never reaches the next.
class DioAvatarUploader implements AvatarUploader, SessionBound {
  DioAvatarUploader(this._dio, this._session);

  final _active = <CancelToken>{};

  /// Sign-out: every upload in flight is cancelled, so no photo of the last
  /// account is sent or saved for the next.
  @override
  void reset() {
    for (final token in _active.toList()) {
      token.cancel('session ended');
    }
  }

  final Dio _dio;
  final SessionRepository _session;

  @override
  Future<Either<Failure, Unit>> upload(
    PickedImage image, {
    required void Function(double fraction) onProgress,
    CancelToken? cancelToken,
  }) async {
    final generation = _session.generation;
    final token = cancelToken ?? CancelToken();
    _active.add(token);
    FormData body() => FormData.fromMap({
      'photo': MultipartFile.fromBytes(
        image.bytes,
        filename: image.name,
        contentType: DioMediaType.parse(image.mimeType),
      ),
    });
    final result = await attempt(
      () => _dio.post<Object?>(
        ApiEndpoints.avatar,
        data: body(),
        cancelToken: token,
        options: Options(
          extra: {
            RequestPolicy.extraKey: RequestClass.upload,
            RequestPolicy.bodyFactoryKey: body,
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress(sent / total);
        },
      ),
    );
    _active.remove(token);
    return result.fold<Future<Either<Failure, Unit>>>(
      (failure) async => Left(failure),
      (response) async {
        // The session ended or changed while the photo was on its way: it
        // is not this user's to save.
        if (generation != _session.generation) return const Left(Cancelled());
        final user = SessionUser.userIn(response.data);
        if (user != null) {
          await _session.saveUser(user, generation: generation);
        }
        return const Right(unit);
      },
    );
  }
}
