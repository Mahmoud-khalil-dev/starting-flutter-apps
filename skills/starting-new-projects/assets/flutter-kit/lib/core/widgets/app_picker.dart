import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_haptics.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';

class AppPickerOption<T> {
  const AppPickerOption({required this.value, required this.label});

  final T value;
  final String label;
}

void choose<T>(BuildContext context, T value) {
  AppHaptics.selection();
  Navigator.pop(context, value);
}

/// Choose one of a few options in a sheet (a dialog on wide screens). The
/// selected option carries a check; a tap returns it with a selection
/// haptic.
Future<T?> showAppPicker<T>(
  BuildContext context, {
  required String title,
  required List<AppPickerOption<T>> options,
  T? selected,
}) => showAppSheet<T>(
  context,
  title: title,
  builder: (context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in options)
          Semantics(
            label: option.label,
            selected: option.value == selected,
            button: true,
            excludeSemantics: true,
            onTap: () => choose(context, option.value),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              onTap: () => choose(context, option.value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.touchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppDimensions.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(option.label, style: context.text.body),
                      ),
                      if (option.value == selected)
                        Icon(
                          Icons.check_rounded,
                          color: c.primaryInk,
                          size: AppDimensions.iconLg,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  },
);
