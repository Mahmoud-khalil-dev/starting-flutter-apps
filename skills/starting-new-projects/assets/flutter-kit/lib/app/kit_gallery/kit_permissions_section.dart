import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/permission_prompt.dart';

/// The permission prompt in every state it can show, for the camera, with
/// buttons that do nothing: the gallery never asks the system for anything.
class KitPermissionsSection extends StatelessWidget {
  const KitPermissionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final state in PermissionState.values)
          AppGroup(
            title: switch (state) {
              PermissionState.notAsked => s('Not asked', 'لم يُطلب بعد'),
              PermissionState.granted => s('Granted', 'مسموح'),
              PermissionState.limited => s('Limited', 'محدود'),
              PermissionState.denied => s('Denied', 'مرفوض'),
              PermissionState.permanentlyDenied => s(
                'Permanently denied',
                'مرفوض بصورة دائمة',
              ),
              PermissionState.revoked => s('Revoked later', 'أُلغي لاحقًا'),
              PermissionState.unavailable => s('Unavailable', 'غير متاح'),
            },
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.all(AppDimensions.md),
                child: PermissionPrompt(
                  permission: AppPermission.camera,
                  state: state,
                  onRequest: () {},
                  onOpenSettings: () {},
                ),
              ),
            ],
          ),
      ],
    );
  }
}
