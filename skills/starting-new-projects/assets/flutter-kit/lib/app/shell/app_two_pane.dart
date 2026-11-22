import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/responsive.dart';

/// List and detail (06 section A): the list alone on a phone, where the
/// detail is pushed; side by side from medium, the list at 360 and the
/// detail capped at the content width.
class AppTwoPane extends StatelessWidget {
  const AppTwoPane({
    required this.list,
    this.detail,
    this.emptyDetail,
    super.key,
  });

  final Widget list;
  final Widget? detail;
  final Widget? emptyDetail;

  @override
  Widget build(BuildContext context) {
    if (context.windowClass == WindowClass.compact) return list;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: AppDimensions.listPaneWidth, child: list),
        VerticalDivider(
          width: AppDimensions.hairline,
          color: context.colors.divider,
        ),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.contentMaxWidth,
              ),
              child: detail ?? emptyDetail ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
