import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/core/media/avatar_upload_state.dart';
import 'package:kit_app/core/media/avatar_uploader.dart';
import 'package:kit_app/core/media/image_crop_slot.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:mocktail/mocktail.dart';

class _Picker extends Mock implements ImagePickerService {}

class _Crop extends Mock implements ImageCropSlot {}

class _Uploader extends Mock implements AvatarUploader {}

class _Permissions extends Mock implements Permissions {}

final _image = PickedImage(
  bytes: Uint8List.fromList([1]),
  name: 'me.jpg',
  mimeType: 'image/jpeg',
);

void main() {
  late _Picker picker;
  late _Crop crop;
  late _Uploader uploader;
  late _Permissions permissions;
  late AvatarUploadCubit cubit;

  setUpAll(() {
    registerFallbackValue(_image);
    registerFallbackValue(ImageOrigin.gallery);
    registerFallbackValue(AppPermission.camera);
  });

  setUp(() {
    picker = _Picker();
    crop = _Crop();
    uploader = _Uploader();
    permissions = _Permissions();
    when(() => crop.crop(any())).thenAnswer(
      (call) async => call.positionalArguments.single as PickedImage,
    );
    cubit = AvatarUploadCubit(
      picker: picker,
      crop: crop,
      uploader: uploader,
      permissions: permissions,
    );
  });
  tearDown(() => cubit.close());

  void uploads(
    Either<Failure, Unit> answer, {
    List<double> progress = const [],
  }) =>
      when(
        () => uploader.upload(
          any(),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        final report =
            call.namedArguments[#onProgress] as void Function(double);
        progress.forEach(report);
        return answer;
      });

  void camera(PermissionState checked, {PermissionState? asked}) {
    when(
      () => permissions.check(AppPermission.camera),
    ).thenAnswer((_) async => checked);
    if (asked != null) {
      when(
        () => permissions.request(AppPermission.camera),
      ).thenAnswer((_) async => asked);
    }
  }

  test('KIT-T18: the camera explains itself before the system asks', () async {
    camera(PermissionState.notAsked);
    await cubit.choose(ImageOrigin.camera);
    expect(cubit.state.status, AvatarUploadStatus.needsPermission);
    expect(cubit.state.permission, PermissionState.notAsked);
    verifyNever(() => permissions.request(any()));
    verifyNever(() => picker.pick(any()));
  });

  test('KIT-T18: a refused camera never opens the picker', () async {
    camera(PermissionState.notAsked, asked: PermissionState.permanentlyDenied);
    await cubit.allowCamera();
    expect(cubit.state.status, AvatarUploadStatus.needsPermission);
    expect(cubit.state.permission, PermissionState.permanentlyDenied);
    verifyNever(() => picker.pick(any()));
  });

  test('KIT-T18: a camera turned off in Settings shows that state', () async {
    camera(PermissionState.revoked);
    await cubit.choose(ImageOrigin.camera);
    expect(cubit.state.permission, PermissionState.revoked);
    verifyNever(() => picker.pick(any()));
  });

  test('KIT-T18: an allowed camera goes on to take the photo', () async {
    camera(PermissionState.notAsked, asked: PermissionState.granted);
    when(() => picker.pick(ImageOrigin.camera)).thenAnswer((_) async => _image);
    uploads(const Right(unit));
    await cubit.allowCamera();
    expect(cubit.state.status, AvatarUploadStatus.done);
  });

  test('KIT-T18: a granted camera needs no second step', () async {
    camera(PermissionState.granted);
    when(() => picker.pick(ImageOrigin.camera)).thenAnswer((_) async => _image);
    uploads(const Right(unit));
    await cubit.choose(ImageOrigin.camera);
    expect(cubit.state.status, AvatarUploadStatus.done);
    verifyNever(() => permissions.request(any()));
  });

  test('KIT-T18: a failing permission check is not an error', () async {
    when(
      () => permissions.check(AppPermission.camera),
    ).thenThrow(PlatformException(code: 'x'));
    await cubit.choose(ImageOrigin.camera);
    expect(cubit.state.status, AvatarUploadStatus.needsPermission);
    expect(cubit.state.permission, PermissionState.notAsked);
  });

  test('KIT-T18: a cancelled pick goes back to idle', () async {
    when(() => picker.pick(ImageOrigin.gallery)).thenAnswer((_) async => null);
    await cubit.choose(ImageOrigin.gallery);
    expect(cubit.state.status, AvatarUploadStatus.idle);
    verifyNever(
      () => uploader.upload(
        any(),
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    );
  });

  test('KIT-T18: a picker that throws goes back to idle', () async {
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenThrow(PlatformException(code: 'photo_access_denied'));
    await cubit.choose(ImageOrigin.gallery);
    expect(cubit.state.status, AvatarUploadStatus.idle);
  });

  test('KIT-T18: progress shows in whole percents, each once', () async {
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    uploads(const Right(unit), progress: [0.001, 0.004, 0.42, 0.425, 1]);
    final percents = <int>[];
    final sub = cubit.stream
        .where((s) => s.status == AvatarUploadStatus.uploading)
        .listen((s) => percents.add(s.percent));
    addTearDown(sub.cancel);
    await cubit.choose(ImageOrigin.gallery);
    await pumpEventQueue();
    expect(percents, [0, 42, 100]);
    expect(cubit.state.status, AvatarUploadStatus.done);
  });

  test('KIT-T18: retry uploads the same photo without picking again', () async {
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    uploads(const Left(NoConnection()));
    await cubit.choose(ImageOrigin.gallery);
    expect(cubit.state.status, AvatarUploadStatus.failed);
    expect(cubit.state.failure, const NoConnection());
    uploads(const Right(unit));
    await cubit.retry();
    expect(cubit.state.status, AvatarUploadStatus.done);
    verify(() => picker.pick(ImageOrigin.gallery)).called(1);
    verify(
      () => uploader.upload(
        _image,
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(2);
  });

  test('KIT-T18: a cancelled crop uploads nothing', () async {
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    when(() => crop.crop(any())).thenAnswer((_) async => null);
    await cubit.choose(ImageOrigin.gallery);
    expect(cubit.state.status, AvatarUploadStatus.idle);
  });

  test('KIT-T18: a second choice while uploading is ignored', () async {
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    when(
      () => uploader.upload(
        any(),
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async {
      await cubit.choose(ImageOrigin.gallery);
      return const Right(unit);
    });
    await cubit.choose(ImageOrigin.gallery);
    verify(() => picker.pick(ImageOrigin.gallery)).called(1);
  });

  test('KIT-T18: a double Allow starts one pick', () async {
    final asked = Completer<PermissionState>();
    when(
      () => permissions.request(AppPermission.camera),
    ).thenAnswer((_) => asked.future);
    when(() => picker.pick(ImageOrigin.camera)).thenAnswer((_) async => _image);
    uploads(const Right(unit));
    final first = cubit.allowCamera();
    final second = cubit.allowCamera();
    asked.complete(PermissionState.granted);
    await Future.wait([first, second]);
    verify(() => picker.pick(ImageOrigin.camera)).called(1);
    verify(() => permissions.request(AppPermission.camera)).called(1);
    expect(cubit.state.status, AvatarUploadStatus.done);
  });

  test('KIT-T18: a choice while one is being picked is ignored', () async {
    final picking = Completer<PickedImage?>();
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) => picking.future);
    uploads(const Right(unit));
    final first = cubit.choose(ImageOrigin.gallery);
    await cubit.choose(ImageOrigin.gallery);
    await cubit.retry();
    picking.complete(_image);
    await first;
    verify(() => picker.pick(ImageOrigin.gallery)).called(1);
    expect(cubit.state.status, AvatarUploadStatus.done);
  });

  test('KIT-T18: a double tap never turns uploading into idle', () async {
    final sent = Completer<Either<Failure, Unit>>();
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    when(
      () => uploader.upload(
        any(),
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) => sent.future);
    final first = cubit.choose(ImageOrigin.gallery);
    await pumpEventQueue();
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenThrow(PlatformException(code: 'already_active'));
    await cubit.choose(ImageOrigin.gallery);
    expect(cubit.state.status, AvatarUploadStatus.uploading);
    sent.complete(const Right(unit));
    await first;
  });

  test('KIT-T18: a reply after the screen closed changes nothing', () async {
    final sent = Completer<Either<Failure, Unit>>();
    CancelToken? token;
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    when(
      () => uploader.upload(
        any(),
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) {
      token = call.namedArguments[#cancelToken] as CancelToken;
      return sent.future;
    });
    final states = <AvatarUploadStatus>[];
    final sub = cubit.stream.listen((s) => states.add(s.status));
    final run = cubit.choose(ImageOrigin.gallery);
    await pumpEventQueue();
    await cubit.close();
    expect(token!.isCancelled, isTrue);
    sent.complete(const Right(unit));
    await run;
    await sub.cancel();
    expect(states, isNot(contains(AvatarUploadStatus.done)));
  });

  test('KIT-T18: a reply for an ended session is not done', () async {
    when(
      () => picker.pick(ImageOrigin.gallery),
    ).thenAnswer((_) async => _image);
    uploads(const Left(Cancelled()));
    await cubit.choose(ImageOrigin.gallery);
    expect(cubit.state.status, AvatarUploadStatus.idle);
    expect(cubit.state.failure, isNull);
  });

  test(
    'KIT-T18: an upload after a sign-out cancel gets a fresh token',
    () async {
      final tokens = <CancelToken>[];
      when(
        () => picker.pick(ImageOrigin.gallery),
      ).thenAnswer((_) async => _image);
      when(
        () => uploader.upload(
          any(),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((call) async {
        final token = call.namedArguments[#cancelToken] as CancelToken;
        tokens.add(token);
        if (tokens.length == 1) token.cancel('session ended');
        return token.isCancelled ? const Left(Cancelled()) : const Right(unit);
      });
      await cubit.choose(ImageOrigin.gallery);
      expect(cubit.state.status, AvatarUploadStatus.idle);
      await cubit.choose(ImageOrigin.gallery);
      expect(tokens[1].isCancelled, isFalse);
      expect(cubit.state.status, AvatarUploadStatus.done);
    },
  );
}
