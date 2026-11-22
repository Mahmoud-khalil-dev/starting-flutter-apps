import 'package:flutter/foundation.dart';
import 'package:kit_app/core/theme/brand.dart';

/// The font family of each role, read from [Brand]. A null family is the
/// system font, which draws Latin and Arabic alike, so the kit bundles no
/// font files and ships no font licences. A project that names a family in
/// `brand.dart` bundles its files in `pubspec.yaml` and adds their licence
/// texts to the licence page; fonts are never fetched at run time.
abstract final class AppFonts {
  /// Families a test swaps in for [Brand]'s (`Brand` is `const`), so the
  /// path that names fonts is covered however the defaults are filled in.
  /// Null reads `Brand`. Reset it in `tearDown`.
  @visibleForTesting
  static ({String? body, String? display})? override;

  /// Fallback families a test swaps in for every role and language, so a
  /// golden can draw a script the body face lacks. Null names none. Reset it
  /// in `tearDown`.
  @visibleForTesting
  static List<String>? fallbackOverride;

  /// The face that sets the text of [language].
  static String? primaryFor(String language) =>
      override != null ? override!.body : Brand.bodyFamily;

  /// Faces for glyphs the primary face lacks: Arabic names in English, Latin
  /// words in Arabic. Empty for the system font, which has them all; name
  /// the partner face here when `brand.dart` names a single-script family.
  static List<String> fallbackFor(String language) =>
      fallbackOverride ?? const [];

  /// The display face of [language].
  static String? displayFor(String language) =>
      override != null ? override!.display : Brand.displayFamily;

  /// The other script's display face, for the same glyph gaps.
  static List<String> displayFallbackFor(String language) =>
      fallbackOverride ?? const [];
}
