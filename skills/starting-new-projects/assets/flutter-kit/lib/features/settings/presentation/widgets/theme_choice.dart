import 'package:flutter/material.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Automatic, light or dark.
class ThemeChoice extends StatelessWidget {
  const ThemeChoice({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSegmented<ThemeMode>(
      selected: selected,
      onChanged: onChanged,
      segments: [
        AppSegment(value: ThemeMode.system, label: l10n.settingsThemeSystem),
        AppSegment(value: ThemeMode.light, label: l10n.settingsThemeLight),
        AppSegment(value: ThemeMode.dark, label: l10n.settingsThemeDark),
      ],
    );
  }
}
