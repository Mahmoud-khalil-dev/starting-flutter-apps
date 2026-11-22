import 'package:flutter/material.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The device language, English or Arabic. Each language is named in its
/// own script, so a reader can always find theirs.
class LanguageChoice extends StatelessWidget {
  const LanguageChoice({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Null follows the device.
  final Locale? selected;
  final ValueChanged<Locale?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppSegmented<Locale?>(
      selected: selected,
      onChanged: onChanged,
      segments: [
        AppSegment(value: null, label: l10n.settingsLanguageSystem),
        AppSegment(
          value: const Locale('en'),
          label: l10n.settingsLanguageEnglish,
        ),
        AppSegment(
          value: const Locale('ar'),
          label: l10n.settingsLanguageArabic,
        ),
      ],
    );
  }
}
