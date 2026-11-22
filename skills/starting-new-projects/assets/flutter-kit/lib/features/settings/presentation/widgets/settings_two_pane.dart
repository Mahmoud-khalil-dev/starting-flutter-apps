import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:kit_app/features/settings/presentation/widgets/settings_sign_out.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The tablet and web layout: the sections on the left, the open one on the
/// right. The right pane cross-fades over `Motion.quick`; under reduce motion
/// it switches at once.
class SettingsTwoPane extends StatefulWidget {
  const SettingsTwoPane({required this.detail, this.onSignOut, super.key});

  /// The controls of the open section.
  final Widget Function(SettingsSection section) detail;

  /// Shown under the sections when set.
  final VoidCallback? onSignOut;

  @override
  State<SettingsTwoPane> createState() => _SettingsTwoPaneState();
}

class _SettingsTwoPaneState extends State<SettingsTwoPane> {
  SettingsSection _open = SettingsSection.appearance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final signOut = widget.onSignOut;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: const ValueKey('settings-list'),
          width: AppDimensions.listPaneWidth,
          child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppDimensions.md,
            ),
            children: [
              AppGroup(
                children: [
                  for (final section in SettingsSection.values)
                    Semantics(
                      selected: section == _open,
                      child: AppRow.navigation(
                        title: section.title(l10n),
                        leading: Icon(
                          section.icon,
                          color: section == _open ? c.primaryInk : c.inkMuted,
                        ),
                        onTap: () => setState(() => _open = section),
                      ),
                    ),
                ],
              ),
              if (signOut != null) SettingsSignOut(onSignOut: signOut),
            ],
          ),
        ),
        VerticalDivider(width: AppDimensions.hairline, color: c.divider),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.contentMaxWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppDimensions.md,
                ),
                child: AnimatedSwitcher(
                  duration: context.motion.moves ? Motion.quick : Duration.zero,
                  child: KeyedSubtree(
                    key: ValueKey(_open),
                    child: widget.detail(_open),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
