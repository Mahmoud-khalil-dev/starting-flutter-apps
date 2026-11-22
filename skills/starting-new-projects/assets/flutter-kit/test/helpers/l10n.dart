import 'package:flutter/widgets.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The app strings for [language] (`en` or `ar`), without a widget tree.
AppLocalizations l10nFor(String language) =>
    lookupAppLocalizations(Locale(language));
