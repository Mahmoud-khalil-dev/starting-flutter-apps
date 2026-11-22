import 'package:dio/dio.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_upload_state.dart';
import 'package:kit_app/core/media/avatar_uploader.dart';
import 'package:kit_app/core/media/image_crop_slot.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:kit_app/core/state/safe_cubit.dart';

/// Pick, crop, upload, with progress and a retry that keeps the photo.
///
/// The camera explains itself first: [choose] with the camera only checks
/// the permission and, short of granted, shows the state for a
/// `PermissionPrompt`; [allowCamera] is its "Allow" and asks the system.
/// The photo library needs no permission here (the system picker).
class AvatarUploadCubit extends SafeCubit<AvatarUploadState> {
  AvatarUploadCubit({
    required this._picker,
    required this._crop,
    required this._uploader,
    required this._permissions,
  }) : super(const AvatarUploadState());

  final ImagePickerService _picker;
  final ImageCropSlot _crop;
  final AvatarUploader _uploader;
  final Permissions _permissions;

  // The running upload's token. Each upload has a fresh one: a cancel from a
  // sign-out or a close ends that upload only, never a later one.
  CancelToken? _cancel;

  // True from the first await of a choice to its end: the permission
  // request, the picker and cropper UI and the upload. A second tap meanwhile
  // (a double Allow) is ignored, so no second pick starts and a state is
  // never overwritten by the answer of a call that did not need to be made.
  bool _working = false;

  bool get _busy => _working || state.status == AvatarUploadStatus.uploading;

  Future<void> _guarded(Future<void> Function() body) async {
    if (_busy) return;
    _working = true;
    try {
      await body();
    } finally {
      _working = false;
    }
  }

  Future<void> choose(ImageOrigin origin) => _guarded(() async {
    if (origin == ImageOrigin.camera) {
      final permission = await _cameraState(_permissions.check);
      if (!permission.usable) {
        _needsPermission(permission);
        return;
      }
    }
    await _pickAndUpload(origin);
  });

  /// The prompt's "Allow": asks the system for the camera, then takes the
  /// photo when it is granted.
  Future<void> allowCamera() => _guarded(() async {
    final permission = await _cameraState(_permissions.request);
    if (!permission.usable) {
      _needsPermission(permission);
      return;
    }
    await _pickAndUpload(ImageOrigin.camera);
  });

  Future<void> retry() => _guarded(() async {
    final image = state.image;
    if (state.status != AvatarUploadStatus.failed || image == null) return;
    await _upload(image);
  });

  @override
  Future<void> close() {
    // The screen is gone: a photo still on its way is not sent on.
    _cancel?.cancel('closed');
    return super.close();
  }

  Future<void> openSettings() async {
    try {
      await _permissions.openSettings();
    } on Object {
      // Nothing to show: the button stays for another try.
    }
  }

  void _needsPermission(PermissionState permission) => emit(
    AvatarUploadState(
      status: AvatarUploadStatus.needsPermission,
      permission: permission,
      // Keep the photo shown so far.
      image: state.image,
    ),
  );

  // A platform error is not the user's problem: read as "not asked", which
  // shows the prompt again.
  Future<PermissionState> _cameraState(
    Future<PermissionState> Function(AppPermission) ask,
  ) async {
    try {
      return await ask(AppPermission.camera);
    } on Object {
      return PermissionState.notAsked;
    }
  }

  Future<void> _pickAndUpload(ImageOrigin origin) async {
    final PickedImage? image;
    try {
      final picked = await _picker.pick(origin);
      image = picked == null ? null : await _crop.crop(picked);
    } on Object {
      // The picker or cropper failed (a plugin error, a photo that cannot
      // be read): quietly back to where the user was.
      emit(AvatarUploadState(image: state.image));
      return;
    }
    if (image == null) {
      emit(AvatarUploadState(image: state.image));
      return;
    }
    await _upload(image);
  }

  Future<void> _upload(PickedImage image) async {
    final token = _cancel = CancelToken();
    emit(AvatarUploadState(status: AvatarUploadStatus.uploading, image: image));
    final result = await _uploader.upload(
      image,
      cancelToken: token,
      onProgress: (fraction) {
        final percent = (fraction * 100).floor().clamp(0, 100);
        if (percent != state.percent) {
          emit(
            AvatarUploadState(
              status: AvatarUploadStatus.uploading,
              percent: percent,
              image: image,
            ),
          );
        }
      },
    );
    emit(
      result.fold(
        // Cancelled: the screen closed or the session ended. Nothing was
        // saved, so neither "failed" nor "done".
        (failure) => failure is Cancelled
            ? const AvatarUploadState()
            : AvatarUploadState(
                status: AvatarUploadStatus.failed,
                image: image,
                failure: failure,
              ),
        (_) => AvatarUploadState(status: AvatarUploadStatus.done, image: image),
      ),
    );
  }
}
