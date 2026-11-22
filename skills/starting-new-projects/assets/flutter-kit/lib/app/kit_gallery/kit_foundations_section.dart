import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/contrast.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_row.dart';

/// Colour roles, type roles and the spacing scale.
class KitFoundationsSection extends StatelessWidget {
  const KitFoundationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final f = AppFormats.of(context);
    final swatches = <(String, Color)>[
      ('background', c.background),
      ('surface', c.surface),
      ('surfaceRaised', c.surfaceRaised),
      ('primary', c.primary),
      ('brand', c.brand),
      ('gold', c.gold),
      ('danger', c.danger),
    ];
    // Each label takes the ink that reads best on its own swatch, so a
    // white or gold swatch is never labelled in its own colour.
    Color inkOn(Color fill) => [c.ink, c.background].reduce(
      (a, b) => contrastRatio(a, fill) >= contrastRatio(b, fill) ? a : b,
    );
    final type = <(String, TextStyle)>[
      ('display', t.display),
      ('headline', t.headline),
      ('title', t.title),
      ('body', t.body),
      ('label', t.label),
      ('caption', t.caption),
      ('smallCaps', t.smallCaps),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.all(AppDimensions.md),
          child: Wrap(
            spacing: AppDimensions.xs,
            runSpacing: AppDimensions.xs,
            children: [
              for (final (name, fill) in swatches)
                Container(
                  width: AppDimensions.xxxl * 2,
                  height: AppDimensions.xxxl,
                  alignment: AlignmentDirectional.bottomStart,
                  padding: const EdgeInsetsDirectional.all(AppDimensions.xs),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: c.outline),
                  ),
                  child: Text(
                    name,
                    style: t.caption.copyWith(color: inkOn(fill)),
                  ),
                ),
            ],
          ),
        ),
        AppGroup(
          title: sample(context, en: 'Type', ar: 'الخطوط'),
          children: [
            for (final (name, style) in type)
              // Start-aligned, short or long: the group centres a child
              // narrower than itself.
              Padding(
                padding: const EdgeInsetsDirectional.all(AppDimensions.md),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    sample(
                      context,
                      en: '$name, a calm summary',
                      ar: '$name، ملخّص هادئ',
                    ),
                    style: style,
                  ),
                ),
              ),
          ],
        ),
        AppGroup(
          title: sample(context, en: 'Spacing', ar: 'المسافات'),
          children: [
            for (final space in const [
              AppDimensions.xxs,
              AppDimensions.xs,
              AppDimensions.sm,
              AppDimensions.md,
              AppDimensions.lg,
              AppDimensions.xl,
            ])
              AppRow.value(
                title: f.formatNumber(space),
                value: '',
                leading: SizedBox(
                  width: space,
                  height: AppDimensions.md,
                  child: ColoredBox(color: c.primary),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
