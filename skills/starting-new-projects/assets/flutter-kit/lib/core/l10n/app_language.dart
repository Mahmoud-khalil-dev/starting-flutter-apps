import 'package:kit_app/l10n/app_localizations.dart';

/// The languages the app ships: one per ARB file.
final Set<String> appLanguages = {
  for (final locale in AppLocalizations.supportedLocales) locale.languageCode,
};

/// The language the app shows, the API is asked in and the notification
/// channel is named in: [chosen] (Settings) when the app has it, else the
/// [device] language when the app has it, else English. The one place a
/// locale becomes a language.
String appLanguage({required String? chosen, required String? device}) {
  if (appLanguages.contains(chosen)) return chosen!;
  if (appLanguages.contains(device)) return device!;
  return 'en';
}
