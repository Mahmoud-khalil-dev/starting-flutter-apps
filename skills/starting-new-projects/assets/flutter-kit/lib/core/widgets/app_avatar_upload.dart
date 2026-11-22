import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/media/avatar_upload_state.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/app_avatar.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/image_origin_sheet.dart';
import 'package:kit_app/core/widgets/inline_error.dart';
import 'package:kit_app/core/widgets/permission_prompt.dart';

/// The profile photo with its upload: tap to change, a progress ring and
/// percent while sending, a retry after a failure, and the camera's own
/// prompt (why, then Allow or Settings) when it is not on. Changes between
/// these fade; under reduce motion they are shorter.
class AppAvatarUpload extends StatelessWidget {
  const AppAvatarUpload({
    required this.name,
    required this.state,
    required this.canUseCamera,
    required this.onChoose,
    required this.onAllow,
    required this.onRetry,
    required this.onOpenSettings,
    this.photoUrl,
    this.canOpenSettings = true,
    super.key,
  });

  final String name;
  final AvatarUploadState state;

  /// Whether to offer the camera (`PlatformCapabilities.cameraCapture`).
  final bool canUseCamera;
  final void Function(ImageOrigin origin) onChoose;

  /// The camera prompt's "Allow".
  final VoidCallback onAllow;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  final String? photoUrl;

  /// `PlatformCapabilities.appSettingsPage`, for the camera prompt.
  final bool canOpenSettings;

  Future<void> _change(BuildContext context) async {
    final origin = await showImageOriginSheet(context, camera: canUseCamera);
    if (origin != null) onChoose(origin);
  }

  /// The photo just chosen, else the saved one.
  ImageProvider<Object>? get _image => switch (state.image) {
    final picked? => MemoryImage(picked.bytes),
    null when photoUrl != null && photoUrl!.isNotEmpty =>
      CachedNetworkImageProvider(photoUrl!),
    null => null,
  };

  Widget _status(BuildContext context) {
    final l10n = context.l10n;
    return switch (state.status) {
      // The screen shows every percent; a screen reader is told in tens, in
      // the screen's digits, so it is not read out a hundred times.
      AvatarUploadStatus.uploading => Semantics(
        liveRegion: true,
        excludeSemantics: true,
        label: l10n.mediaUploading(
          context.formats.formatPercent(state.percent ~/ 10 * 10),
        ),
        child: Text(
          l10n.mediaUploading(context.formats.formatPercent(state.percent)),
          style: context.text.caption,
        ),
      ),
      AvatarUploadStatus.failed => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InlineError(l10n.mediaUploadFailed),
          AppButton(
            label: l10n.kitRetry,
            variant: AppButtonVariant.quiet,
            onPressed: onRetry,
          ),
        ],
      ),
      AvatarUploadStatus.needsPermission => Padding(
        padding: const EdgeInsetsDirectional.only(top: AppDimensions.xs),
        child: PermissionPrompt(
          permission: AppPermission.camera,
          state: state.permission ?? PermissionState.notAsked,
          onRequest: onAllow,
          onOpenSettings: onOpenSettings,
          canOpenSettings: canOpenSettings,
        ),
      ),
      AvatarUploadStatus.idle || AvatarUploadStatus.done => const SizedBox(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fade = context.motion.fade(Motion.quick);
    final uploading = state.status == AvatarUploadStatus.uploading;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppDimensions.dialogMaxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            enabled: !uploading,
            label: l10n.mediaChangePhoto,
            excludeSemantics: true,
            child: InkResponse(
              onTap: uploading ? null : () => _change(context),
              radius: AppDimensions.avatarLg,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  AppAvatar(
                    name: name,
                    image: _image,
                    size: AppDimensions.avatarLg,
                  ),
                  // A quiet cue that the photo can be changed, where there is
                  // a camera to change it with. It gives way to the progress
                  // ring, so the ring never runs through it.
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: fade,
                      switchInCurve: Motion.enter,
                      switchOutCurve: Motion.exit,
                      child: canUseCamera && !uploading
                          ? ExcludeSemantics(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: context.colors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.colors.outline,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.all(
                                    AppDimensions.xxs,
                                  ),
                                  child: Icon(
                                    Icons.photo_camera_outlined,
                                    size: AppDimensions.iconSm,
                                    color: context.colors.inkMuted,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: fade,
                    switchInCurve: Motion.enter,
                    switchOutCurve: Motion.exit,
                    child: uploading
                        ? ExcludeSemantics(
                            child: SizedBox.square(
                              dimension: AppDimensions.avatarLg,
                              child: CircularProgressIndicator(
                                value: state.percent / 100,
                                strokeWidth: AppDimensions.spinnerStroke,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          AnimatedSize(
            duration: fade,
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: fade,
              switchInCurve: Motion.enter,
              switchOutCurve: Motion.exit,
              child: KeyedSubtree(
                key: ValueKey(state.status),
                child: _status(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
