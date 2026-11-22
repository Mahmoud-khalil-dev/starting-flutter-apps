import 'package:flutter/material.dart';
import 'package:kit_app/core/error/failure_messages.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The error state of a screen: a calm title, the failure's message, and
/// Try again when the caller can retry. Offline gets its own title.
///
/// The caller owns guarding a double tap on Try again (for example by moving
/// its Cubit to loading); the view does not debounce [onRetry].
class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.failure, this.onRetry, super.key});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offline = failure is NoConnection;
    return _StateLayout(
      icon: offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      title: offline ? l10n.kitOfflineTitle : l10n.kitErrorTitle,
      body: failureMessage(l10n, failure),
      action: onRetry == null
          ? null
          : AppButton(
              label: l10n.kitRetry,
              onPressed: onRetry,
              variant: AppButtonVariant.secondary,
            ),
    );
  }
}

/// The empty state of a screen. Copy is the feature's; the default title
/// is a quiet fallback.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    this.title,
    this.body,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String? title;
  final String? body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _StateLayout(
    icon: icon,
    title: title ?? AppLocalizations.of(context)!.kitEmptyTitle,
    body: body,
    action: action,
  );
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: AppDimensions.iconXl, color: c.hint),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(title, textAlign: TextAlign.center, style: context.text.title),
            if (body != null) ...[
              const SizedBox(height: AppDimensions.xs),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: context.text.body.copyWith(color: c.inkMuted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppDimensions.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
