import 'package:flutter/widgets.dart';
import 'package:kit_app/core/widgets/app_dialog.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Asks whether to try a timed-out request again: a calm dialog with Try
/// again and Not now, on the app's own navigator. Dismissing it, or having no
/// screen to ask on, means no, and the request fails with its own message.
Future<bool> askRetryWithDialog(GlobalKey<NavigatorState> navigatorKey) async {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return false;
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return false;
  final again = await showAppDialog<bool>(
    context,
    title: l10n.kitSlowConnection,
    message: l10n.errorTimeout,
    actions: [
      AppDialogAction(label: l10n.kitNotNow, value: false),
      AppDialogAction(label: l10n.kitRetry, value: true, isDefault: true),
    ],
  );
  return again ?? false;
}
