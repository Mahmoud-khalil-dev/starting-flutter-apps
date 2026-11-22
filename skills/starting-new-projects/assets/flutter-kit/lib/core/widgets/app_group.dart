import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';

/// A grouped list: a small-caps title, rows on a raised
/// surface with the large radius, inset dividers between rows only.
class AppGroup extends StatelessWidget {
  const AppGroup({required this.children, this.title, this.footer, super.key});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final language = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppDimensions.md,
                bottom: AppDimensions.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  // Arabic has no case; small caps only change Latin.
                  language == 'ar' ? title! : title!.toUpperCase(),
                  style: context.text.smallCaps,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: ColoredBox(
              color: c.surfaceRaised,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: AppDimensions.hairline,
                        thickness: AppDimensions.hairline,
                        indent: AppDimensions.md,
                        color: c.divider,
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppDimensions.md,
                top: AppDimensions.xs,
              ),
              child: Text(footer!, style: context.text.caption),
            ),
        ],
      ),
    );
  }
}
