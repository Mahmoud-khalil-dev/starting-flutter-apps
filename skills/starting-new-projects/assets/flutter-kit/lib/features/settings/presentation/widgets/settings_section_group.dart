import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/presentation/widgets/language_choice.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:kit_app/features/settings/presentation/widgets/text_size_control.dart';
import 'package:kit_app/features/settings/presentation/widgets/theme_choice.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// One section's group: its title and its control. The phone stacks all
/// three; a tablet shows the open one.
class SettingsSectionGroup extends StatelessWidget {
  const SettingsSectionGroup({
    required this.section,
    required this.settings,
    required this.onThemeMode,
    required this.onLocale,
    required this.onTextScale,
    super.key,
  });

  final SettingsSection section;
  final AppSettings settings;
  final ValueChanged<ThemeMode> onThemeMode;
  final ValueChanged<Locale?> onLocale;
  final Future<void> Function(double scale) onTextScale;

  @override
  Widget build(BuildContext context) {
    final control = switch (section) {
      SettingsSection.appearance => ThemeChoice(
        selected: settings.themeMode,
        onChanged: onThemeMode,
      ),
      SettingsSection.language => LanguageChoice(
        selected: settings.locale,
        onChanged: onLocale,
      ),
      SettingsSection.textSize => TextSizeControl(
        value: settings.textScale,
        onChanged: onTextScale,
      ),
    };
    return AppGroup(
      title: section.title(AppLocalizations.of(context)!),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.all(AppDimensions.md),
          child: control,
        ),
      ],
    );
  }
}
