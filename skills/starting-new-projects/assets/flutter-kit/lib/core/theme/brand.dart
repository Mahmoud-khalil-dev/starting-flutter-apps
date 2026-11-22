// Fill this file first.
//
// It is the one place a project's identity enters the kit. The palette
// (`app_palette.dart`) and the font roles (`app_fonts.dart`) read it and
// nothing else, so a new brand is one edit here. The defaults are neutral
// slate and indigo; replace them before any screen is shown to anyone.
//
// After editing, run `flutter test test/core/theme`: the palette test checks
// that every text colour reaches WCAG AA (4.5:1) on every surface in both
// themes, and names the colour that does not.
import 'package:flutter/painting.dart';

abstract final class Brand {
  /// The brand colour in the light theme: filled buttons, links and the
  /// selected tab. The text on it is picked to read (`readableOn`: white or
  /// near-black, pushed further when neither reaches 4.5:1), so any colour
  /// works; links use a reading of it darkened until it reads on the
  /// surfaces. It is also `AppColors.brand`, the identity colour (the app
  /// name in the sidebar). In the dark theme that brand is this seed
  /// lightened until it reaches 4.5:1 on every dark surface, not [darkSeed],
  /// so it is safe as text or an icon in both themes.
  static const lightSeed = Color(0xFF3730A3);

  /// The brand colour in the dark theme. The fill is this seed lightened,
  /// the least it takes, until it reaches 3:1 on every dark surface, so a
  /// filled button stands out by its shape alone; a seed that already does
  /// is used unchanged. Its lighter reading, for text and icons on the dark
  /// surfaces, reaches 4.5:1 the same way.
  static const darkSeed = Color(0xFF4F46E5);

  /// A second colour for marks and quiet highlights. It is lightened or
  /// darkened as needed so it always reads on the surface it sits on.
  static const accent = Color(0xFF52627A);

  /// Font family of body text, in every language. Null is the system font,
  /// which draws Latin and Arabic alike. A family named here must be bundled
  /// in `pubspec.yaml`; never fetch fonts at run time.
  static const String? bodyFamily = null;

  /// Font family of display and headline text. Null is the system font.
  static const String? displayFamily = null;
}
