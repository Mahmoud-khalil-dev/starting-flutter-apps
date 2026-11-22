import 'package:flutter/widgets.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/l10n/app_localizations.dart';

extension AppContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  AppFormats get formats => AppFormats.of(this);

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();
}
