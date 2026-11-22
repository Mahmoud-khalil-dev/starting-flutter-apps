import 'package:flutter/widgets.dart';

/// Sample copy for the gallery, in the app's two languages. Written here
/// as constructor arguments: the gallery never reads data.
String sample(BuildContext context, {required String en, required String ar}) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
