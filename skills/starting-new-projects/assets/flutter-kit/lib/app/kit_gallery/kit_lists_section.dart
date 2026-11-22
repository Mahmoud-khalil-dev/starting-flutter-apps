import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_avatar.dart';
import 'package:kit_app/core/widgets/app_entrance.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/core/widgets/auto_direction_text.dart';

/// Groups and every row kind, avatars, mixed-direction text and the
/// staggered entrance.
class KitListsSection extends StatefulWidget {
  const KitListsSection({super.key});

  @override
  State<KitListsSection> createState() => _KitListsSectionState();
}

class _KitListsSectionState extends State<KitListsSection> {
  bool _reminders = true;

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    final name = s('Alex Morgan', 'أليكس مورغان');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGroup(
          title: s('Account', 'الحساب'),
          footer: s(
            'Changes apply on this device.',
            'تُطبَّق التغييرات على هذا الجهاز.',
          ),
          children: [
            AppRow.navigation(
              title: s('Language', 'اللغة'),
              value: s('English', 'العربية'),
              leading: const Icon(Icons.translate_rounded),
              onTap: () {},
            ),
            AppRow.value(
              title: s('Email', 'البريد الإلكتروني'),
              value: 'alex.morgan@example.com',
            ),
            AppRow.toggle(
              title: s('Reminders', 'التذكيرات'),
              subtitle: s('Before each meeting', 'قبل كل اجتماع'),
              value: _reminders,
              onChanged: (v) => setState(() => _reminders = v),
            ),
            AppRow.info(title: s('Signed in', 'تم تسجيل الدخول')),
            AppRow.action(
              title: s('Sign out', 'تسجيل الخروج'),
              tone: AppRowTone.destructive,
              onTap: () {},
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.all(AppDimensions.md),
          child: Row(
            children: [
              AppAvatar(name: name, size: AppDimensions.avatarSm),
              const SizedBox(width: AppDimensions.sm),
              AppAvatar(name: name),
              const SizedBox(width: AppDimensions.sm),
              AppAvatar(name: name, size: AppDimensions.avatarLg),
              const SizedBox(width: AppDimensions.sm),
              const Expanded(child: AutoDirectionText('Alex Morgan')),
            ],
          ),
        ),
        AppGroup(
          title: s('Entrance', 'الظهور'),
          children: [
            for (var i = 0; i < 4; i++)
              AppEntrance(
                index: i,
                child: AppRow.info(title: s('Task', 'مهمة')),
              ),
          ],
        ),
      ],
    );
  }
}
