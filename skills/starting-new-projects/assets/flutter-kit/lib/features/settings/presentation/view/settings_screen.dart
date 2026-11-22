import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kit_app/core/error/failure_messages.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/responsive.dart';
import 'package:kit_app/core/widgets/app_scaffold.dart';
import 'package:kit_app/core/widgets/app_snackbar.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_state.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_section_group.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_sign_out.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_two_pane.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Theme, language and text size. The phone stacks the three groups; from
/// 600 wide (a tablet, the web) the sections sit on the left and the open
/// one on the right. It reads the app-wide [SettingsCubit], which `App`
/// provides above the router. [onSignOut] ends the session; the router
/// passes the session's sign-out, and with none Settings offers no way out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.onSignOut, super.key});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => current.failure != null,
      listener: (context, state) {
        final message = failureMessage(l10n, state.failure!);
        if (message != null) {
          AppSnackbar.show(context, message, tone: SnackTone.danger);
        }
        context.read<SettingsCubit>().failureShown();
      },
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        Widget group(SettingsSection section) => SettingsSectionGroup(
          section: section,
          settings: state.settings,
          onThemeMode: cubit.setThemeMode,
          onLocale: cubit.setLocale,
          onTextScale: cubit.setTextScale,
        );
        final signOut = onSignOut;
        return AppScaffold(
          title: l10n.navSettings,
          wide: true,
          body: AdaptiveLayout(
            compact: (_) => ListView(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppDimensions.md,
              ),
              children: [
                for (final s in SettingsSection.values) group(s),
                if (signOut != null) SettingsSignOut(onSignOut: signOut),
              ],
            ),
            medium: (_) => SettingsTwoPane(detail: group, onSignOut: signOut),
          ),
        );
      },
    );
  }
}
