import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/utils/string_extensions.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// A form rule: null when the value is fine, else the message to show.
typedef Validator = String? Function(String? value);

/// Form rules with English and Arabic messages. Every rule but [required]
/// passes an empty value, so an optional field stays optional; combine
/// with [all] for a required one. Lengths count characters as a reader sees
/// them (grapheme clusters), not code units.
class Validators {
  const Validators(this._l10n);

  final AppLocalizations _l10n;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _phone = RegExp(r'^\+?[0-9]{7,15}$');
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _digit = RegExp('[0-9]');

  String _shown(int n) => AppFormats(_l10n.localeName).formatNumber(n);

  static bool _empty(String? value) => value == null || value.isBlank;

  Validator required() =>
      (value) => _empty(value) ? _l10n.validationRequired : null;

  Validator email() => (value) {
    if (_empty(value)) return null;
    return _email.hasMatch(value!.trim()) ? null : _l10n.validationEmail;
  };

  Validator phone() => (value) {
    if (_empty(value)) return null;
    final compact = value!.westernDigits.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phone.hasMatch(compact) ? null : _l10n.validationPhone;
  };

  Validator password({int minLength = 8}) => (value) {
    if (_empty(value)) return null;
    final ok =
        value!.characters.length >= minLength &&
        _letter.hasMatch(value) &&
        _digit.hasMatch(value.westernDigits);
    return ok ? null : _l10n.validationPassword(minLength, _shown(minLength));
  };

  Validator length({int? min, int? max}) => (value) {
    if (_empty(value)) return null;
    final n = value!.trim().characters.length;
    if (min != null && n < min) {
      return _l10n.validationTooShort(min, _shown(min));
    }
    if (max != null && n > max) {
      return _l10n.validationTooLong(max, _shown(max));
    }
    return null;
  };

  /// For a confirmation field: [other] reads the first field when checked.
  Validator matches(String Function() other) =>
      (value) => value == other() ? null : _l10n.validationMismatch;

  static Validator all(List<Validator> rules) => (value) {
    for (final rule in rules) {
      final message = rule(value);
      if (message != null) return message;
    }
    return null;
  };
}
