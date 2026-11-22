import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/platform_style.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The platform's date picker: a wheel in a sheet with Done on iOS, the
/// Material calendar elsewhere. Returns null when dismissed.
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) {
  final min = DateUtils.dateOnly(first);
  final max = DateUtils.dateOnly(last);
  final start = DateUtils.dateOnly(initial);
  final clamped = start.isBefore(min)
      ? min
      : start.isAfter(max)
      ? max
      : start;
  if (!context.isCupertino) {
    return openOnce(
      context,
      () => showDatePicker(
        context: context,
        initialDate: clamped,
        firstDate: min,
        lastDate: max,
        // One interaction model; typed digits are not parsed here.
        initialEntryMode: DatePickerEntryMode.calendarOnly,
      ),
    );
  }
  var chosen = clamped;
  return showAppSheet<DateTime>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppDimensions.xxxl * 3,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: clamped,
            minimumDate: min,
            maximumDate: max,
            onDateTimeChanged: (d) => chosen = DateUtils.dateOnly(d),
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        AppButton(
          label: AppLocalizations.of(context)!.kitDone,
          expand: true,
          onPressed: () => Navigator.pop(context, chosen),
        ),
      ],
    ),
  );
}
