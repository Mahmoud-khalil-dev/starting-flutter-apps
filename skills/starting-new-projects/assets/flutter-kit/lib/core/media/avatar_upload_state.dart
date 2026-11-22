import 'package:equatable/equatable.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/picked_image.dart';
import 'package:kit_app/core/permissions/app_permission.dart';

enum AvatarUploadStatus { idle, needsPermission, uploading, failed, done }

class AvatarUploadState extends Equatable {
  const AvatarUploadState({
    this.status = AvatarUploadStatus.idle,
    this.percent = 0,
    this.image,
    this.failure,
    this.permission,
  });

  final AvatarUploadStatus status;

  /// Whole percent sent, 0 to 100, while uploading.
  final int percent;

  /// The photo being sent. Kept after a failure for the retry, and after
  /// success so the avatar keeps showing the new photo.
  final PickedImage? image;
  final Failure? failure;

  /// Set with [AvatarUploadStatus.needsPermission]: what the camera is now.
  final PermissionState? permission;

  @override
  List<Object?> get props => [status, percent, image, failure, permission];
}
