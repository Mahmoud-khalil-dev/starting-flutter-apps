import 'package:flutter/material.dart';
import 'package:kit_app/core/media/image_picker_service.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';

/// Camera or photos. [camera] false (web, desktop) offers photos only.
Future<ImageOrigin?> showImageOriginSheet(
  BuildContext context, {
  required bool camera,
}) => showAppSheet<ImageOrigin>(
  context,
  title: context.l10n.mediaChangePhoto,
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (camera)
        AppButton(
          label: context.l10n.mediaTakePhoto,
          icon: Icons.photo_camera_outlined,
          variant: AppButtonVariant.quiet,
          onPressed: () => Navigator.of(context).pop(ImageOrigin.camera),
        ),
      AppButton(
        label: context.l10n.mediaChoosePhoto,
        icon: Icons.photo_library_outlined,
        variant: AppButtonVariant.quiet,
        onPressed: () => Navigator.of(context).pop(ImageOrigin.gallery),
      ),
    ],
  ),
);
