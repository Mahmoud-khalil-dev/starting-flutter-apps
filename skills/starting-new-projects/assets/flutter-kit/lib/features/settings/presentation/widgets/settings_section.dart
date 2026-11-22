import 'package:flutter/material.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The three groups of the Settings screen. A phone lists them all; a
/// tablet lists them on the left and opens one on the right.
enum SettingsSection {
  appearance(Icons.palette_outlined),
  language(Icons.language_rounded),
  textSize(Icons.text_fields_rounded);

  const SettingsSection(this.icon);

  final IconData icon;

  String title(AppLocalizations l10n) => switch (this) {
    appearance => l10n.settingsAppearanceTitle,
    language => l10n.settingsLanguageTitle,
    textSize => l10n.settingsTextSizeTitle,
  };
}
