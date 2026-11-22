import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_uploader.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/network/api_endpoints.dart';
import 'package:kit_app/core/network/request_policy.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/stub_adapter.dart';

class _Session extends Mock implements SessionRepository {}

final _image = PickedImage(
  bytes: Uint8List.fromList([1, 2, 3]),
  name: 'me.png',
  mimeType: 'image/png',
);

void main() {
  late _Session session;

  setUp(() {
    session = _Session();
    when(() => session.generation).thenReturn(3);
    when(
      () => session.saveUser(any(), generation: any(named: 'generation')),
    ).thenAnswer((_) async {});
  });

  DioAvatarUploader uploader(StubAdapter adapter) => DioAvatarUploader(
    Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter,
    session,
  );

  test('KIT-T18: the photo goes up as a retryable upload', () async {
    final adapter = StubAdapter(
      (_) async => jsonBody({
        'data': {
          'user': {'id': 1, 'photo': 'p.png'},
        },
      }),
    );
    final result = await uploader(adapter).upload(_image, onProgress: (_) {});
    expect(result, const Right<Failure, Unit>(unit));
    final request = adapter.requests.single;
    expect(request.path, ApiEndpoints.avatar);
    expect(request.data, isA<FormData>());
    expect(request.extra[RequestPolicy.extraKey], RequestClass.upload);
    expect(
      request.extra[RequestPolicy.bodyFactoryKey],
      isA<FormData Function()>(),
    );
    verify(
      () => session.saveUser({'id': 1, 'photo': 'p.png'}, generation: 3),
    ).called(1);
  });

  test('KIT-T18: a server error is a failure and saves nothing', () async {
    final adapter = StubAdapter((_) async => jsonBody({}, status: 500));
    final result = await uploader(adapter).upload(_image, onProgress: (_) {});
    expect(result.isLeft(), isTrue);
    verifyNever(
      () => session.saveUser(any(), generation: any(named: 'generation')),
    );
  });

  test('KIT-T18: a reply after the session changed saves nothing', () async {
    final generations = [3, 4];
    when(() => session.generation).thenAnswer(
      (_) => generations.length > 1 ? generations.removeAt(0) : generations[0],
    );
    final adapter = StubAdapter(
      (_) async => jsonBody({
        'data': {
          'user': {'id': 1},
        },
      }),
    );
    final result = await uploader(adapter).upload(_image, onProgress: (_) {});
    expect(result, const Left<Failure, Unit>(Cancelled()));
    verifyNever(
      () => session.saveUser(any(), generation: any(named: 'generation')),
    );
  });

  test('KIT-T18: sign-out cancels an upload in flight', () async {
    final reply = Completer<ResponseBody>();
    final adapter = StubAdapter((_) => reply.future);
    final media = uploader(adapter);
    final token = CancelToken();
    final result = media.upload(
      _image,
      onProgress: (_) {},
      cancelToken: token,
    );
    await pumpEventQueue();
    media.reset();
    expect(token.isCancelled, isTrue);
    expect(await result, const Left<Failure, Unit>(Cancelled()));
    verifyNever(
      () => session.saveUser(any(), generation: any(named: 'generation')),
    );
  });
}
