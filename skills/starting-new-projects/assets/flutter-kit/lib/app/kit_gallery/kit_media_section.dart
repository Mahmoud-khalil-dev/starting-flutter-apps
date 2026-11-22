import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/media/avatar_upload_state.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_avatar_upload.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_network_image.dart';

/// The cached image in its unavailable state (no address, so no request)
/// and the avatar upload in each state it shows, with callbacks that do
/// nothing and no photo: the gallery never reaches a camera or a server.
class KitMediaSection extends StatelessWidget {
  const KitMediaSection({super.key});

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    final name = s('Sara Ali', 'سارة علي');
    Widget upload(AvatarUploadState state) => AppAvatarUpload(
      name: name,
      state: state,
      canUseCamera: true,
      onChoose: (_) {},
      onAllow: () {},
      onRetry: () {},
      onOpenSettings: () {},
    );
    // On the surface colour, not the card's own: the avatar's disc is the
    // card colour and would vanish into it.
    Widget padded(Widget child) => ColoredBox(
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDimensions.md),
        child: Center(child: child),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGroup(
          title: s('Image unavailable', 'الصورة غير متاحة'),
          children: [
            padded(
              const AppNetworkImage(
                url: '',
                width: AppDimensions.avatarLg,
                height: AppDimensions.avatarLg,
              ),
            ),
          ],
        ),
        AppGroup(
          title: s('Photo, idle', 'الصورة، جاهزة'),
          children: [padded(upload(const AvatarUploadState()))],
        ),
        AppGroup(
          title: s('Photo, uploading', 'الصورة، قيد الرفع'),
          children: [
            padded(
              upload(
                const AvatarUploadState(
                  status: AvatarUploadStatus.uploading,
                  percent: 40,
                ),
              ),
            ),
          ],
        ),
        AppGroup(
          title: s(
            'Photo, camera permission needed',
            'الصورة، الكاميرا تحتاج إذنًا',
          ),
          children: [
            padded(
              upload(
                const AvatarUploadState(
                  status: AvatarUploadStatus.needsPermission,
                  permission: PermissionState.notAsked,
                ),
              ),
            ),
          ],
        ),
        AppGroup(
          title: s('Photo, upload failed', 'الصورة، تعذّر الرفع'),
          children: [
            padded(
              upload(
                const AvatarUploadState(
                  status: AvatarUploadStatus.failed,
                  failure: NoConnection(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
