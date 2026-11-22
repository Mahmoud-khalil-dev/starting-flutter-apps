import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/core/media/avatar_uploader.dart';
import 'package:kit_app/core/media/image_crop_slot.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/media/media_sign_out_hook.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/platform/plugin_image_picker.dart';
import 'package:kit_app/core/session/session_bound.dart';

/// Picking, cropping, the avatar upload and the image cache's sign-out
/// hook. Register after the session and notifications modules (it needs
/// `Permissions`, `Dio` and the session).
void registerMediaModule(GetIt sl) {
  sl
    ..registerLazySingleton<ImagePickerService>(PluginImagePicker.new)
    // The cropping slot: replace NoCrop with the project's cropper.
    ..registerLazySingleton<ImageCropSlot>(() => const NoCrop())
    ..registerLazySingleton<DioAvatarUploader>(
      () => DioAvatarUploader(sl(), sl()),
    )
    ..registerLazySingleton<AvatarUploader>(() => sl<DioAvatarUploader>())
    // Registered by its own type: GetIt cannot hold a nullable cache.
    ..registerLazySingleton<MediaSignOutHook>(
      () => MediaSignOutHook(
        () => sl<PlatformCapabilities>().isWeb ? null : DefaultCacheManager(),
        sl(),
      ),
    )
    ..registerFactory<AvatarUploadCubit>(
      () => AvatarUploadCubit(
        picker: sl(),
        crop: sl(),
        uploader: sl(),
        permissions: sl(),
      ),
    );
  // A sign-out cancels an upload still on its way.
  sl<SessionBoundRegistry>().add(() => sl<DioAvatarUploader>());
}
