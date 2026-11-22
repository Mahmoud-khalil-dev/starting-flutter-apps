import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';

/// A short error under a field or a list footer. It eases in from just above
/// and is announced as it appears.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: motion.fade(Motion.quick),
        curve: Motion.enter,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, motion.moves ? (t - 1) * AppDimensions.xxs : 0),
            child: child,
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: AppDimensions.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconSm,
                color: c.danger,
              ),
              const SizedBox(width: AppDimensions.xxs),
              Expanded(
                child: Text(
                  message,
                  style: context.text.caption.copyWith(color: c.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
