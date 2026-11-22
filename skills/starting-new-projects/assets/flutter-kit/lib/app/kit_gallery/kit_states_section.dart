import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';
import 'package:kit_app/core/widgets/app_state_view.dart';

/// The five screen states, each in a frame that grows with the text size,
/// and a skeleton list.
class KitStatesSection extends StatelessWidget {
  const KitStatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final status in ScreenStatus.values)
          AppGroup(
            title: switch (status) {
              ScreenStatus.loading => s('Loading', 'التحميل'),
              ScreenStatus.content => s('Content', 'المحتوى'),
              ScreenStatus.empty => s('Empty', 'لا محتوى'),
              ScreenStatus.error => s('Error', 'خطأ'),
              ScreenStatus.offline => s('Offline', 'دون اتصال'),
            },
            children: [
              SizedBox(
                // Grows with the text size (to 2x) so the copy never clips.
                height:
                    AppDimensions.xxxl *
                    4 *
                    math.min(MediaQuery.textScalerOf(context).scale(1), 2),
                // The state views scroll their copy on a full screen; in
                // this short frame that scroll would take the gallery's
                // drags, so the frame never scrolls on its own.
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(physics: const NeverScrollableScrollPhysics()),
                  child: AppStateView(
                    status: status,
                    failure: const ServerFailure(500),
                    onRetry: () {},
                    content: (context) =>
                        Center(child: Text(s('Your orders', 'طلباتك'))),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(
          height: AppDimensions.xxxl * 3,
          child: AppSkeletonList(),
        ),
      ],
    );
  }
}
