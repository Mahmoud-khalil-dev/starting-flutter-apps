import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_logo_loader.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';

/// Skeletons in sync, and the logo loader with a way to end and replay it.
class KitLoadingSection extends StatefulWidget {
  const KitLoadingSection({super.key});

  @override
  State<KitLoadingSection> createState() => _KitLoadingSectionState();
}

class _KitLoadingSectionState extends State<KitLoadingSection> {
  int _run = 0;
  bool _done = false;
  bool _gone = false;

  @override
  Widget build(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppShimmer(child: AppSkeletonHeader()),
        const SizedBox(height: AppDimensions.lg),
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppDimensions.lg,
          ),
          // One region, one "Loading": the header's shimmer says it.
          child: AppShimmer(
            announce: false,
            child: AppSkeletonCard(image: true),
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        const AppSkeletonList(rows: 3, announce: false),
        const SizedBox(height: AppDimensions.xl),
        AppGroup(
          title: s('Logo loader', 'مؤشر الشعار'),
          children: [
            if (!_gone)
              Padding(
                padding: const EdgeInsetsDirectional.all(AppDimensions.lg),
                child: AppLogoLoader(
                  logo: const AssetImage('assets/images/logo.png'),
                  key: ValueKey(_run),
                  fullScreen: false,
                  done: _done,
                  onExited: () => setState(() => _gone = true),
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.all(AppDimensions.lg),
              child: _gone
                  ? AppButton(
                      label: s('Replay', 'إعادة'),
                      variant: AppButtonVariant.quiet,
                      onPressed: _restart,
                    )
                  : AppButton(
                      label: s('Finish waiting', 'إنهاء الانتظار'),
                      variant: AppButtonVariant.quiet,
                      onPressed: _done
                          ? null
                          : () => setState(() => _done = true),
                    ),
            ),
            AppRow.action(
              title: s('Start the wait again', 'ابدأ الانتظار من جديد'),
              onTap: _restart,
            ),
          ],
        ),
      ],
    );
  }

  void _restart() => setState(() {
    _run++;
    _done = false;
    _gone = false;
  });
}
