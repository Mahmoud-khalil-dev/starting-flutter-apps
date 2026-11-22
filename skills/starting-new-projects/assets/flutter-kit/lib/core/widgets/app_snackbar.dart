import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/widgets/success_check.dart';

enum SnackTone { neutral, success, danger }

class _Shown {
  _Shown(this.message, this.tone);

  final String message;
  final SnackTone tone;
  bool open = true;
}

final _last = Expando<_Shown>('last snackbar');

/// A brief message at the bottom. One at
/// a time: a new one clears the last and anything queued, and the same
/// message while it is still showing is not shown again. The
/// SnackBar is a live region, so the message is announced. The success tone
/// leads with a [SuccessCheck]: a drawn check, a short gold shimmer and the
/// success haptic.
abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    SnackTone tone = SnackTone.neutral,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final previous = _last[messenger];
    if (previous != null &&
        previous.open &&
        previous.message == message &&
        previous.tone == tone) {
      return;
    }
    final c = context.colors;
    final (fill, ink) = switch (tone) {
      SnackTone.neutral || SnackTone.success => (c.ink, c.background),
      SnackTone.danger => (c.danger, c.onDanger),
    };
    messenger.clearSnackBars();
    final shown = _Shown(message, tone);
    _last[messenger] = shown;
    messenger
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (tone == SnackTone.success) ...[
                  const SuccessCheck(),
                  const SizedBox(width: AppDimensions.xs),
                ],
                Expanded(
                  child: Text(
                    message,
                    style: context.text.label.copyWith(color: ink),
                  ),
                ),
              ],
            ),
            backgroundColor: fill,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            action: action,
          ),
        )
        .closed
        .then((_) => shown.open = false);
  }
}
