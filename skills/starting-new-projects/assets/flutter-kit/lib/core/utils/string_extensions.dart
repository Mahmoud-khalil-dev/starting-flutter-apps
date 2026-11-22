import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:kit_app/core/l10n/digits.dart';

extension AppStringX on String {
  bool get isBlank => trim().isEmpty;

  /// The trimmed text, or null when nothing is left.
  String? get nullIfBlank {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// What the API gets from a field: Arabic-Indic and Persian digits and
  /// the Arabic decimal separator become Western.
  String get westernDigits => normalizeDigits(this);

  num? get asNumber => num.tryParse(westernDigits.trim());

  /// Up to two letters for an avatar, from the first two words.
  String get initials => trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();

  /// At most [max] characters (grapheme clusters), the last one an ellipsis.
  String ellipsize(int max) {
    final chars = characters;
    if (chars.length <= max) return this;
    return '${chars.take(max - 1)}…';
  }
}
