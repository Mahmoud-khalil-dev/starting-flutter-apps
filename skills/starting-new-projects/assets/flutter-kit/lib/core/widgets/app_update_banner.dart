import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_shadows.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// "An update is ready": a raised card that slides from the top, with
/// Restart and Later. Announced as it appears; under reduce motion it fades
/// in place. It is only the component: the update check is the app's own.
class AppUpdateBanner extends StatefulWidget {
  const AppUpdateBanner({
    required this.onRestart,
    required this.onLater,
    super.key,
  });

  final VoidCallback onRestart;
  final VoidCallback onLater;

  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _show = AnimationController(vsync: this);
  late final CurvedAnimation _reveal = CurvedAnimation(
    parent: _show,
    curve: Motion.enter,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(_reveal);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _show.duration = context.motion.move(Motion.standard);
    _show.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _show.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final card = Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppDimensions.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: AppShadows.high(c),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.kitUpdateTitle,
                  style: context.text.title.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppDimensions.xxs),
                Text(
                  l10n.kitUpdateBody,
                  style: context.text.body.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppDimensions.md),
                Wrap(
                  spacing: AppDimensions.xs,
                  runSpacing: AppDimensions.xs,
                  children: [
                    AppButton(
                      label: l10n.kitUpdateRestart,
                      onPressed: widget.onRestart,
                    ),
                    AppButton(
                      label: l10n.kitUpdateLater,
                      onPressed: widget.onLater,
                      variant: AppButtonVariant.quiet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return SlideTransition(
      position: context.motion.moves
          ? _slide
          : const AlwaysStoppedAnimation(Offset.zero),
      child: FadeTransition(opacity: _reveal, child: card),
    );
  }
}
