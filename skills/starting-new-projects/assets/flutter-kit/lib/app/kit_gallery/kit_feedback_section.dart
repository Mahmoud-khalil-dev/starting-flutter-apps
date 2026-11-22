import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/time/app_clock.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_date_picker.dart';
import 'package:kit_app/core/widgets/app_dialog.dart';
import 'package:kit_app/core/widgets/app_picker.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';
import 'package:kit_app/core/widgets/app_snackbar.dart';
import 'package:kit_app/core/widgets/app_update_banner.dart';
import 'package:kit_app/core/widgets/connection_banner.dart';
import 'package:kit_app/core/widgets/inline_error.dart';

/// The connection banners, the update banner, an inline error, and
/// launchers for sheets, pickers, dialogs and snackbars.
class KitFeedbackSection extends StatelessWidget {
  const KitFeedbackSection({required this.clock, super.key});

  /// Today for the date launcher, so the gallery never reads the wall clock.
  final AppClock clock;

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final status in const [
          ConnectionStatus.offline,
          ConnectionStatus.unstable,
        ])
          ConnectionBanner(statuses: const Stream.empty(), initial: status),
        AppUpdateBanner(onRestart: () {}, onLater: () {}),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppDimensions.md),
          child: InlineError(s('Wrong code', 'الرمز غير صحيح')),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppDimensions.md),
          child: Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: [
              AppButton(
                label: s('Sheet', 'لوحة'),
                variant: AppButtonVariant.secondary,
                onPressed: () => showAppSheet<void>(
                  context,
                  title: s('Weekly plan', 'خطة الأسبوع'),
                  builder: (context) => Text(
                    s(
                      'Review it before the meeting.',
                      'يُرجى مراجعتها قبل الاجتماع.',
                    ),
                  ),
                ),
              ),
              AppButton(
                label: s('Picker', 'اختيار'),
                variant: AppButtonVariant.secondary,
                onPressed: () => showAppPicker<String>(
                  context,
                  title: s('Language', 'اللغة'),
                  selected: 'en',
                  options: const [
                    AppPickerOption(value: 'en', label: 'English'),
                    AppPickerOption(value: 'ar', label: 'العربية'),
                  ],
                ),
              ),
              AppButton(
                label: s('Date', 'التاريخ'),
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  final today = DateUtils.dateOnly(clock.now());
                  showAppDatePicker(
                    context,
                    initial: today,
                    first: today,
                    last: DateTime(today.year + 1, today.month, today.day),
                  );
                },
              ),
              AppButton(
                label: s('Dialog', 'حوار'),
                variant: AppButtonVariant.secondary,
                onPressed: () => showAppDialog<bool>(
                  context,
                  title: s('Delete this draft?', 'حذف هذه المسودة؟'),
                  message: s('It is removed for everyone.', 'ستُزال للجميع.'),
                  actions: [
                    AppDialogAction(
                      label: s('Keep', 'الإبقاء'),
                      value: false,
                      isDefault: true,
                    ),
                    AppDialogAction(
                      label: s('Delete draft', 'حذف المسودة'),
                      value: true,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              AppButton(
                label: s('Snackbar', 'إشعار'),
                variant: AppButtonVariant.secondary,
                onPressed: () => AppSnackbar.show(
                  context,
                  s('Saved', 'تم الحفظ'),
                  tone: SnackTone.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
