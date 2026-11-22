import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The quiet way out of an account, under the settings groups.
class SettingsSignOut extends StatelessWidget {
  const SettingsSignOut({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      child: AppButton(
        label: l10n.authSignOutAction,
        variant: AppButtonVariant.quiet,
        onPressed: onSignOut,
      ),
    );
  }
}
