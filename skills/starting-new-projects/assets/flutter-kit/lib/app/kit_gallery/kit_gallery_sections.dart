import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_actions_section.dart';
import 'package:kit_app/app/kit_gallery/kit_feedback_section.dart';
import 'package:kit_app/app/kit_gallery/kit_foundations_section.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/app/kit_gallery/kit_lists_section.dart';
import 'package:kit_app/app/kit_gallery/kit_loading_section.dart';
import 'package:kit_app/app/kit_gallery/kit_media_section.dart';
import 'package:kit_app/app/kit_gallery/kit_permissions_section.dart';
import 'package:kit_app/app/kit_gallery/kit_shell_sample.dart';
import 'package:kit_app/app/kit_gallery/kit_states_section.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/time/app_clock.dart';

enum KitSection {
  foundations,
  actions,
  lists,
  feedback,
  states,
  loading,
  permissions,
  media,
  shell,
}

extension KitSectionX on KitSection {
  String title(BuildContext context) => switch (this) {
    KitSection.foundations => sample(context, en: 'Foundations', ar: 'الأسس'),
    KitSection.actions => sample(context, en: 'Actions', ar: 'الإجراءات'),
    KitSection.lists => sample(context, en: 'Lists', ar: 'القوائم'),
    KitSection.feedback => sample(context, en: 'Feedback', ar: 'التنبيهات'),
    KitSection.states => sample(
      context,
      en: 'Screen states',
      ar: 'حالات الشاشة',
    ),
    KitSection.loading => sample(context, en: 'Loading', ar: 'التحميل'),
    KitSection.permissions => sample(
      context,
      en: 'Permissions',
      ar: 'الأذونات',
    ),
    KitSection.media => sample(context, en: 'Media', ar: 'الوسائط'),
    KitSection.shell => sample(context, en: 'Shell', ar: 'الإطار'),
  };

  /// The section's widget type, for tests.
  Type get type => switch (this) {
    KitSection.foundations => KitFoundationsSection,
    KitSection.actions => KitActionsSection,
    KitSection.lists => KitListsSection,
    KitSection.feedback => KitFeedbackSection,
    KitSection.states => KitStatesSection,
    KitSection.loading => KitLoadingSection,
    KitSection.permissions => KitPermissionsSection,
    KitSection.media => KitMediaSection,
    KitSection.shell => KitShellSample,
  };

  Widget build({required AppClock clock}) => switch (this) {
    KitSection.foundations => const KitFoundationsSection(),
    KitSection.actions => const KitActionsSection(),
    KitSection.lists => const KitListsSection(),
    KitSection.feedback => KitFeedbackSection(clock: clock),
    KitSection.states => const KitStatesSection(),
    KitSection.loading => const KitLoadingSection(),
    KitSection.permissions => const KitPermissionsSection(),
    KitSection.media => const KitMediaSection(),
    // A fixed-height frame: the shell expects a whole screen.
    KitSection.shell => const SizedBox(
      height: AppDimensions.xxxl * 10,
      child: KitShellSample(role: AppRole.member),
    ),
  };
}
