import 'package:flutter/material.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Why the app wants a permission and the one step that helps now: ask,
/// or open Settings. Shown before the system dialog, never instead of it.
/// A change of state fades the copy; under reduce motion it just changes.
class PermissionPrompt extends StatelessWidget {
  const PermissionPrompt({
    required this.permission,
    required this.state,
    required this.onRequest,
    required this.onOpenSettings,
    this.canOpenSettings = true,
    super.key,
  });

  final AppPermission permission;
  final PermissionState state;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  /// Whether the app can open the system's settings for itself
  /// (`PlatformCapabilities.appSettingsPage`). On the web it cannot: the
  /// prompt then asks for the browser's site settings and shows no button.
  final bool canOpenSettings;

  (String, String) _why(AppLocalizations l10n) => switch (permission) {
    AppPermission.notifications => (
      l10n.permissionNotificationsTitle,
      l10n.permissionNotificationsBody,
    ),
    AppPermission.camera => (
      l10n.permissionCameraTitle,
      l10n.permissionCameraBody,
    ),
    AppPermission.photos => (
      l10n.permissionPhotosTitle,
      l10n.permissionPhotosBody,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, why) = _why(l10n);
    // On the web a refusal is changed in the browser's site settings: one
    // quiet line, no button that does nothing.
    final browserOnly =
        !canOpenSettings &&
        state != PermissionState.notAsked &&
        state != PermissionState.granted &&
        state != PermissionState.unavailable;
    final (body, action) = browserOnly
        ? (l10n.permissionBrowserBody, null)
        : switch (state) {
            PermissionState.notAsked => (
              why,
              AppButton(label: l10n.permissionAllow, onPressed: onRequest),
            ),
            PermissionState.denied => (
              l10n.permissionDeniedBody,
              AppButton(label: l10n.permissionAllow, onPressed: onRequest),
            ),
            PermissionState.permanentlyDenied => (
              l10n.permissionDeniedBody,
              AppButton(
                label: l10n.permissionOpenSettings,
                variant: AppButtonVariant.secondary,
                onPressed: onOpenSettings,
              ),
            ),
            PermissionState.revoked => (
              l10n.permissionRevokedBody,
              AppButton(
                label: l10n.permissionOpenSettings,
                variant: AppButtonVariant.secondary,
                onPressed: onOpenSettings,
              ),
            ),
            PermissionState.limited => (
              l10n.permissionLimitedBody,
              AppButton(
                label: l10n.permissionOpenSettings,
                variant: AppButtonVariant.quiet,
                onPressed: onOpenSettings,
              ),
            ),
            PermissionState.granted => (l10n.permissionGranted, null),
            PermissionState.unavailable => (l10n.permissionUnavailable, null),
          };
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: context.text.title)),
        const SizedBox(height: AppDimensions.xs),
        AnimatedSwitcher(
          duration: context.motion.fade(Motion.quick),
          switchInCurve: Motion.enter,
          switchOutCurve: Motion.exit,
          child: KeyedSubtree(
            key: ValueKey(state),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  body,
                  style: context.text.body.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppDimensions.md),
                  action,
                ],
              ],
            ),
          ),
        ),
      ],
    );
    // On a wide screen the copy and the button keep a readable width at the
    // start edge instead of stretching across it.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.dialogMaxWidth,
        ),
        child: column,
      ),
    );
  }
}
