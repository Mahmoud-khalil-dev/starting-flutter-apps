import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/platform_style.dart';
import 'package:kit_app/core/time/app_clock.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/l10n/app_localizations.dart';

typedef TimePick =
    Future<TimeOfDay?> Function(BuildContext context, TimeOfDay initial);

/// The platform's time picker: a time wheel with Done on iOS, the Material
/// dial elsewhere.
Future<TimeOfDay?> pickPlatformTime(BuildContext context, TimeOfDay initial) {
  if (!context.isCupertino) {
    return openOnce(
      context,
      () => showTimePicker(
        context: context,
        initialTime: initial,
        // One interaction model; typed digits are not parsed here.
        initialEntryMode: TimePickerEntryMode.dialOnly,
      ),
    );
  }
  var chosen = initial;
  return showAppSheet<TimeOfDay>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppDimensions.xxxl * 3,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            initialDateTime: DateTime(2000, 1, 1, initial.hour, initial.minute),
            onDateTimeChanged: (d) => chosen = TimeOfDay.fromDateTime(d),
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

/// On today, a time at or before the current minute is
/// past.
bool isPastToday(TimeOfDay picked, DateTime now) =>
    picked.hour * 60 + picked.minute <= now.hour * 60 + now.minute;

/// A read-only field that opens the platform time picker (ports
/// TimePickerField). On today a past time is rejected: the value clears,
/// the field shows kitPastTime and shakes once.
class AppTimePicker extends StatefulWidget {
  const AppTimePicker({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isToday = false,
    this.clock = const SystemClock(),
    this.pick = pickPlatformTime,
    super.key,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final bool isToday;
  final AppClock clock;
  final TimePick pick;

  @override
  State<AppTimePicker> createState() => _AppTimePickerState();
}

class _AppTimePickerState extends State<AppTimePicker> {
  final _text = TextEditingController();
  bool _pastError = false;
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncText();
  }

  @override
  void didUpdateWidget(AppTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncText();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _syncText() {
    final value = widget.value;
    _text.text = value == null
        ? ''
        : AppFormats.of(
            context,
          ).formatTime(DateTime(2000, 1, 1, value.hour, value.minute));
  }

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    try {
      final now = widget.clock.now();
      final picked = await widget.pick(
        context,
        widget.value ?? TimeOfDay.fromDateTime(now),
      );
      if (!mounted || picked == null) return;
      if (widget.isToday && isPastToday(picked, widget.clock.now())) {
        setState(() => _pastError = true);
        widget.onChanged(null);
        return;
      }
      setState(() => _pastError = false);
      widget.onChanged(picked);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: widget.label,
    controller: _text,
    readOnly: true,
    onTap: _open,
    errorText: _pastError ? AppLocalizations.of(context)!.kitPastTime : null,
    suffix: const Icon(Icons.schedule_rounded),
  );
}
