import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/platform_style.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The platform spinner, centred, announced as "Loading". Prefer a skeleton
/// (AppShimmer) where the shape of the content is known.
class AppLoading extends StatelessWidget {
  const AppLoading({this.size = AppDimensions.iconXl, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: AppLocalizations.of(context)!.loaderLabel,
      child: SizedBox.square(
        dimension: size,
        child: context.isCupertino
            // The Cupertino default tick fades into dark raised surfaces.
            ? CupertinoActivityIndicator(color: context.colors.inkMuted)
            : CircularProgressIndicator(
                strokeWidth: AppDimensions.spinnerStroke,
                color: context.colors.primaryInk,
              ),
      ),
    ),
  );
}
