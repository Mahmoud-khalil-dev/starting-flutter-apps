import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/core/widgets/app_time_picker.dart';

/// Buttons in every variant and state, fields, the segmented control and
/// the time picker.
class KitActionsSection extends StatefulWidget {
  const KitActionsSection({super.key});

  @override
  State<KitActionsSection> createState() => _KitActionsSectionState();
}

class _KitActionsSectionState extends State<KitActionsSection> {
  int _segment = 0;
  TimeOfDay? _time;

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: [
              for (final variant in AppButtonVariant.values)
                AppButton(
                  label: s('Confirm', 'تأكيد'),
                  variant: variant,
                  onPressed: () {},
                ),
              AppButton(
                label: s('Call', 'اتصال'),
                icon: Icons.call_rounded,
                onPressed: () {},
              ),
              AppButton(label: s('Confirm', 'تأكيد'), onPressed: null),
              AppButton(
                label: s('Confirm', 'تأكيد'),
                state: AppButtonState.loading,
                onPressed: () {},
              ),
              AppButton(
                label: s('Confirm', 'تأكيد'),
                state: AppButtonState.success,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: s('Confirm the plan', 'تأكيد الخطة'),
            expand: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppDimensions.lg),
          AppTextField(label: s('Full name', 'الاسم الكامل')),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: s('Email', 'البريد الإلكتروني'),
            leftToRight: true,
            errorText: s(
              'Please check the email address.',
              'يرجى التحقق من البريد الإلكتروني.',
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          AppTimePicker(
            label: s('Time', 'الوقت'),
            value: _time,
            onChanged: (t) => setState(() => _time = t),
          ),
          const SizedBox(height: AppDimensions.lg),
          AppSegmented<int>(
            segments: [
              AppSegment(value: 0, label: s('Upcoming', 'القادمة')),
              AppSegment(value: 1, label: s('Past', 'السابقة')),
            ],
            selected: _segment,
            onChanged: (v) => setState(() => _segment = v),
          ),
        ],
      ),
    );
  }
}
