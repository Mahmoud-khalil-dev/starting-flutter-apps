import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_theme.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';
import 'package:kit_app/core/widgets/app_state_views.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// What runApp shows when the dependencies or the session could not start
///: a calm message and one Try again, in place of the launch screen.
///
/// Self-contained on purpose: it reads no preference and no Cubit, because
/// either may be what failed. The language is the system's, English or
/// Arabic; the theme follows the system brightness.
class BootFailureScreen extends StatefulWidget {
  const BootFailureScreen({required this.onRetry, super.key});

  /// Runs the start-up again. The button shows a loading state until it
  /// finishes; a failed retry shows this screen again.
  final Future<void> Function() onRetry;

  @override
  State<BootFailureScreen> createState() => _BootFailureScreenState();
}

class _BootFailureScreenState extends State<BootFailureScreen> {
  var _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  /// Through the binding, which is the platform dispatcher in the app and the
  /// test dispatcher under `flutter test`.
  static String _language() =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar'
      ? 'ar'
      : 'en';

  @override
  Widget build(BuildContext context) {
    final language = _language();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // themeMode stays at its default, ThemeMode.system.
      theme: AppTheme.cached(brightness: Brightness.light, language: language),
      darkTheme: AppTheme.cached(
        brightness: Brightness.dark,
        language: language,
      ),
      home: Scaffold(
        body: SafeArea(
          child: AppStateView(
            status: ScreenStatus.empty,
            content: (_) => const SizedBox.shrink(),
            empty: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return AppEmptyView(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.bootFailureTitle,
                  body: l10n.bootFailureBody,
                  action: AppButton(
                    label: l10n.bootFailureRetry,
                    onPressed: _retry,
                    state: _retrying
                        ? AppButtonState.loading
                        : AppButtonState.idle,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
