import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/theme/platform_style.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';
import 'package:kit_app/l10n/app_localizations.dart';

class AppDialogAction<T> {
  const AppDialogAction({
    required this.label,
    this.value,
    this.isDefault = false,
    this.isDestructive = false,
  });

  final String label;
  final T? value;
  final bool isDefault;
  final bool isDestructive;
}

/// Whether a popup that is not the caller's own route is on top: a dialog or
/// sheet opened without the kit, which the kit's guard does not see. A sheet
/// the caller sits inside is its own route, so a confirm may open from it.
bool _popupOnTop(BuildContext context) {
  final own = ModalRoute.of(context);
  var onTop = false;
  Navigator.of(context, rootNavigator: !AppNestedOverlays.of(context)).popUntil(
    (route) {
      onTop = route is PopupRoute && route != own;
      return true;
    },
  );
  return onTop;
}

/// A confirmation: the Cupertino alert on iOS; elsewhere a
/// card that springs from 0.96 over a blurred scrim. One at a time: while a
/// dialog or sheet is on top, this returns null without showing.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required List<AppDialogAction<T>> actions,
  String? message,
}) => openOnce(context, () {
  // A dialog or sheet opened without the kit is not in the kit's guard, so
  // the top route is checked as well.
  if (_popupOnTop(context)) return Future<T?>.value();
  return _show<T>(context, title: title, message: message, actions: actions);
});

Future<T?> _show<T>(
  BuildContext context, {
  required String title,
  required String? message,
  required List<AppDialogAction<T>> actions,
}) {
  final hint = AppLocalizations.of(context)?.kitDestructiveHint;
  if (context.isCupertino) {
    return showCupertinoDialog<T>(
      context: context,
      useRootNavigator: !AppNestedOverlays.of(context),
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          for (final a in actions)
            Semantics(
              hint: a.isDestructive ? hint : null,
              child: CupertinoDialogAction(
                isDefaultAction: a.isDefault,
                isDestructiveAction: a.isDestructive,
                onPressed: () => Navigator.pop(context, a.value),
                child: Text(a.label),
              ),
            ),
        ],
      ),
    );
  }
  final reduced = context.motion.reduced;
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: !AppNestedOverlays.of(context),
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: context.colors.scrim,
    transitionDuration: reduced ? Motion.quick : Motion.standard,
    pageBuilder: (context, _, _) => _MaterialAlert<T>(
      title: title,
      message: message,
      actions: actions,
      destructiveHint: hint,
    ),
    transitionBuilder: (context, animation, _, child) => _DialogTransition(
      animation: animation,
      reduced: reduced,
      blur: context.blursBackdrop,
      child: child,
    ),
  );
}

/// The blur rises and the card springs in from [Motion.dialogScale]; it
/// leaves on [Motion.exit]. Under reduce motion: a steady blur and a fade, no
/// scale. Without [blur] (the web) only the card moves over the scrim.
class _DialogTransition extends StatefulWidget {
  const _DialogTransition({
    required this.animation,
    required this.reduced,
    required this.blur,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduced;
  final bool blur;
  final Widget child;

  @override
  State<_DialogTransition> createState() => _DialogTransitionState();
}

class _DialogTransitionState extends State<_DialogTransition> {
  late final CurvedAnimation _fade = CurvedAnimation(
    parent: widget.animation,
    curve: Motion.enter,
    reverseCurve: Motion.exit,
  );
  late final CurvedAnimation _spring = CurvedAnimation(
    parent: widget.animation,
    curve: Motion.spring,
    reverseCurve: Motion.exit,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: Motion.dialogScale,
    end: 1,
  ).animate(_spring);

  @override
  void dispose() {
    _fade.dispose();
    _spring.dispose();
    super.dispose();
  }

  ImageFilter _blur(double sigma) =>
      ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  @override
  Widget build(BuildContext context) {
    final card = FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: widget.reduced ? const AlwaysStoppedAnimation(1) : _scale,
        child: widget.child,
      ),
    );
    if (!widget.blur) return card;
    if (widget.reduced) {
      return BackdropFilter(
        filter: _blur(AppDimensions.backdropBlur),
        child: card,
      );
    }
    return AnimatedBuilder(
      animation: widget.animation,
      child: card,
      builder: (context, child) => BackdropFilter(
        filter: _blur(AppDimensions.backdropBlur * widget.animation.value),
        child: child,
      ),
    );
  }
}

class _MaterialAlert<T> extends StatelessWidget {
  const _MaterialAlert({
    required this.title,
    required this.message,
    required this.actions,
    required this.destructiveHint,
  });

  final String title;
  final String? message;
  final List<AppDialogAction<T>> actions;
  final String? destructiveHint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: title,
        explicitChildNodes: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.dialogMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: context.text.title),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    message!,
                    style: context.text.body.copyWith(color: c.inkMuted),
                  ),
                ],
                const SizedBox(height: AppDimensions.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppDimensions.xs,
                  runSpacing: AppDimensions.xs,
                  children: [
                    for (final a in actions)
                      Semantics(
                        hint: a.isDestructive ? destructiveHint : null,
                        child: AppButton(
                          label: a.label,
                          onPressed: () => Navigator.pop(context, a.value),
                          variant: a.isDestructive
                              ? AppButtonVariant.destructive
                              : a.isDefault
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.quiet,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
