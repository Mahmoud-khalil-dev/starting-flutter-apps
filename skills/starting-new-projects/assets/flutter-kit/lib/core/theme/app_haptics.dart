import 'package:flutter/services.dart';

/// Haptics: light on a primary press, selection on a choice, success
/// on a confirmation. Never on scroll. They fire under reduce motion too.
abstract final class AppHaptics {
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> light() => HapticFeedback.lightImpact();

  /// Flutter has no notification haptic; medium impact stands in.
  static Future<void> success() => HapticFeedback.mediumImpact();
}
