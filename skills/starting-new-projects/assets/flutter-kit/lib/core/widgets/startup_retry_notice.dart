import 'package:flutter/widgets.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_entrance.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Shown on the splash when the saved session is slow to open: one quiet line
/// and Try again. It rises and fades in
/// through [AppEntrance], which fades alone under reduce motion.
class StartupRetryNotice extends StatelessWidget {
  const StartupRetryNotice({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppEntrance(
      index: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.startupRetryBody,
            textAlign: TextAlign.center,
            style: context.text.body.copyWith(color: context.colors.inkMuted),
          ),
          const SizedBox(height: AppDimensions.md),
          AppButton(
            label: l10n.startupRetryAction,
            onPressed: onRetry,
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
