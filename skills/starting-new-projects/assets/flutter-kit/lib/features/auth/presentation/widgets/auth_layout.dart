import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/utils/responsive.dart';
import 'package:kit_app/core/widgets/app_entrance.dart';

/// The frame of every auth screen. Phone: one scrolling column. Tablet: the
/// column centred at dialog width. Web and wide tablets: the app name on a
/// quiet panel at the start, the form at the end. Items enter one after
/// another through `AppEntrance` (which already has its reduce-motion path).
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.title,
    required this.children,
    this.body,
    this.footer,
    super.key,
  });

  static const ValueKey<String> brandPanelKey = ValueKey('auth-brand-panel');

  final String title;
  final String? body;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AdaptiveLayout(
        compact: _form,
        medium: (context) => Center(child: _narrow(_form(context))),
        expanded: (context) => Row(
          children: [
            Expanded(
              child: ColoredBox(
                key: brandPanelKey,
                color: context.colors.surfaceRaised,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: Text(
                      context.l10n.appName,
                      textAlign: TextAlign.center,
                      style: context.text.display,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: Center(child: _narrow(_form(context)))),
          ],
        ),
      ),
    ),
  );

  static Widget _narrow(Widget child) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppDimensions.dialogMaxWidth),
    child: child,
  );

  Widget _form(BuildContext context) {
    final items = <Widget>[
      Semantics(header: true, child: Text(title, style: context.text.headline)),
      if (body case final text?)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppDimensions.xs),
          child: Text(
            text,
            style: context.text.body.copyWith(color: context.colors.inkMuted),
          ),
        ),
      const SizedBox(height: AppDimensions.lg),
      ...children,
      if (footer case final footer?)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppDimensions.md),
          child: footer,
        ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, item) in items.indexed)
              AppEntrance(index: index, child: item),
          ],
        ),
      ),
    );
  }
}
