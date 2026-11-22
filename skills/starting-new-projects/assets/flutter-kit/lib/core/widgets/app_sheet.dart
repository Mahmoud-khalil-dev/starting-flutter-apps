import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/theme/platform_style.dart';
import 'package:kit_app/core/utils/responsive.dart';

/// A bottom sheet whose barrier blurs what is behind it as it dims.
/// It rises on [Motion.enter] over [Motion.standard] and
/// leaves on [Motion.exit]; under reduce motion it fades in place over
/// [Motion.quick]. The blur rises with the route animation.
class AppSheetRoute<T> extends ModalBottomSheetRoute<T> {
  AppSheetRoute({
    required super.builder,
    required AppColors colors,
    required bool reduced,
    required this._blur,
  }) : _reduced = reduced,
       _scrim = colors.scrim,
       super(
         isScrollControlled: true,
         useSafeArea: true,
         showDragHandle: false,
         backgroundColor: colors.surface,
         shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(
             top: Radius.circular(AppDimensions.radiusXl),
           ),
         ),
         clipBehavior: Clip.antiAlias,
         // The stock route reads its controller and curves from here only.
         sheetAnimationStyle: AnimationStyle(
           duration: reduced ? Motion.quick : Motion.standard,
           reverseDuration: Motion.quick,
           // Not the spring: the route does not clamp the sheet, so an
           // overshoot would open a gap under it for a few frames.
           curve: reduced ? Motion.jump : Motion.enter,
           reverseCurve: reduced ? Motion.jump : Motion.exit,
         ),
       );

  final bool _reduced;
  final bool _blur;
  final Color _scrim;

  @override
  Color get barrierColor => _scrim;

  /// Under reduce motion the sheet does not slide: it fades in place.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _reduced ? FadeTransition(opacity: animation, child: child) : child;

  /// The blur rises with the route animation; under reduce motion it is
  /// constant. Without the blur (`context.blursBackdrop`, false on the web)
  /// only the scrim shows.
  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    if (!_blur) return barrier;
    ImageFilter filter(double sigma) =>
        ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    if (_reduced) {
      return BackdropFilter(
        filter: filter(AppDimensions.backdropBlur),
        child: barrier,
      );
    }
    return AnimatedBuilder(
      animation: animation!,
      builder: (context, child) => BackdropFilter(
        filter: filter(AppDimensions.backdropBlur * animation!.value),
        child: child,
      ),
      child: barrier,
    );
  }
}

/// Makes the kit's sheets, pickers and dialogs open on the nearest
/// [Navigator] under it instead of the root one, so they inherit what sits
/// between the two: a theme, a text scale or a language set for one part of
/// the app. The component gallery uses it so its switches govern what opens.
/// Put a [Navigator] below it (the gallery's page is a route of its own).
class AppNestedOverlays extends InheritedWidget {
  const AppNestedOverlays({required super.child, super.key});

  /// Whether a sheet or dialog opened from [context] stays on the nearest
  /// navigator. Reads without subscribing: it is asked when one opens.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppNestedOverlays>() != null;

  @override
  bool updateShouldNotify(AppNestedOverlays old) => false;
}

final _open = Expando<bool>('open app route');

/// Runs [open] unless another sheet, dialog or picker opened through the kit
/// from the same route is still showing; then it returns null at once, so a
/// double tap opens one route. The flag belongs to the caller's route, not to
/// the navigator, so a picker or a confirm opened from inside a sheet (its
/// own route) opens, while a double tap on one button still opens one.
Future<T?> openOnce<T>(BuildContext context, Future<T?> Function() open) async {
  final key = ModalRoute.of(context) ?? Navigator.of(context);
  if (_open[key] ?? false) return null;
  _open[key] = true;
  try {
    return await open();
  } finally {
    _open[key] = false;
  }
}

/// A sheet on a phone; a centred dialog (at most 480 wide) from the medium
/// width class up, where a bottom sheet would stretch across a tablet.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
}) => openOnce(context, () => _show<T>(context, builder, title));

Future<T?> _show<T>(
  BuildContext context,
  WidgetBuilder builder,
  String? title,
) {
  final colors = context.colors;
  final dialog = context.windowClass != WindowClass.compact;
  Widget body(BuildContext context) => _SheetBody(
    title: title,
    // A dialog already makes room for the keyboard itself.
    clearKeyboard: !dialog,
    child: builder(context),
  );
  if (dialog) {
    return showDialog<T>(
      context: context,
      useRootNavigator: !AppNestedOverlays.of(context),
      barrierColor: colors.scrim,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppDimensions.dialogMaxWidth,
          ),
          child: Dialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: body(context),
          ),
        ),
      ),
    );
  }
  return Navigator.of(context).push(
    AppSheetRoute<T>(
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(child: _Handle()),
          Flexible(child: body(context)),
        ],
      ),
      colors: colors,
      reduced: context.motion.reduced,
      blur: context.blursBackdrop,
    ),
  );
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('sheet-handle'),
    padding: const EdgeInsetsDirectional.only(top: AppDimensions.xs),
    child: SizedBox(
      width: AppDimensions.xl,
      height: AppDimensions.xxs,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.outline,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
      ),
    ),
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.child,
    required this.clearKeyboard,
  });

  final String? title;
  final Widget child;
  final bool clearKeyboard;

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.lg +
            (clearKeyboard ? MediaQuery.viewInsetsOf(context).bottom : 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Semantics(
              header: true,
              child: Text(title!, style: context.text.title),
            ),
            const SizedBox(height: AppDimensions.md),
          ],
          child,
        ],
      ),
    );
    if (title == null) return content;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: content,
    );
  }
}
