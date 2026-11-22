import 'package:kit_app/core/l10n/digits.dart';

/// Reads of the API's untyped `data` (03 section 2.3). A missing or
/// wrong-typed value is null, never a throw: a field the backend renames
/// degrades one screen, not the app.
abstract final class JsonRead {
  static String? string(Object? value) => switch (value) {
    final String s when s.trim().isNotEmpty => s,
    final num n => n.toString(),
    _ => null,
  };

  static int? integer(Object? value) => switch (value) {
    final int i => i,
    final double d when d == d.roundToDouble() => d.toInt(),
    final String s => int.tryParse(normalizeDigits(s.trim())),
    _ => null,
  };

  static bool? boolean(Object? value) => switch (value) {
    final bool b => b,
    'true' || 1 => true,
    'false' || 0 => false,
    _ => null,
  };

  static Map<String, dynamic>? map(Object? value) => switch (value) {
    final Map<String, dynamic> m => m,
    final Map<Object?, Object?> m => {
      for (final MapEntry(:key, :value) in m.entries) '$key': value,
    },
    _ => null,
  };

  /// The `data` object of a success envelope.
  static Map<String, dynamic>? data(Object? body) => map(map(body)?['data']);
}
