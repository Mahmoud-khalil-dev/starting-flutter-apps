import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/core/media/avatar_uploader.dart';
import 'package:kit_app/core/media/image_crop_slot.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:mocktail/mocktail.dart';

class _Picker extends Mock implements ImagePickerService {}

class _Uploader extends Mock implements AvatarUploader {}

class _Permissions extends Mock implements Permissions {}

/// An avatar Cubit over in-test doubles, for a screen that shows the
/// photo but does not exercise it. Nothing reaches a camera or a server.
AvatarUploadCubit testAvatarCubit() => AvatarUploadCubit(
  picker: _Picker(),
  crop: const NoCrop(),
  uploader: _Uploader(),
  permissions: _Permissions(),
);
