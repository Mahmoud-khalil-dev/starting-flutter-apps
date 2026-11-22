import 'package:flutter/material.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_directional_icon.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The expanded-width sidebar: the app name at the top, one row per
/// destination, collapsible to the rail width.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.destinations,
    required this.selected,
    required this.onTap,
    required this.collapsed,
    required this.onToggle,
    this.badges = const {},
    super.key,
  });

  final List<ShellDestination> destinations;
  final int selected;
  final ValueChanged<int> onTap;
  final bool collapsed;
  final VoidCallback onToggle;
  final Set<ShellTab> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final tabs = MaterialLocalizations.of(context);
    // The width snaps (no per-frame layout); the labels fade in instead.
    return Container(
      width: collapsed ? AppDimensions.railWidth : AppDimensions.sidebarWidth,
      decoration: BoxDecoration(
        color: c.surface,
        border: BorderDirectional(end: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!collapsed)
              Padding(
                padding: const EdgeInsetsDirectional.all(AppDimensions.md),
                child: _FadeIn(
                  child: Text(
                    l10n.appName,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: context.text.title.copyWith(color: c.brand),
                  ),
                ),
              )
            else
              const SizedBox(height: AppDimensions.md),
            for (var i = 0; i < destinations.length; i++)
              _SidebarRow(
                destination: destinations[i],
                label: destinations[i].label(l10n),
                selected: i == selected,
                collapsed: collapsed,
                badge: badges.contains(destinations[i].tab),
                position: tabs.tabLabel(
                  tabIndex: i + 1,
                  tabCount: destinations.length,
                ),
                onTap: () => onTap(i),
              ),
            const Spacer(),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.all(AppDimensions.xs),
                child: IconButton(
                  tooltip: collapsed ? l10n.navExpand : l10n.navCollapse,
                  onPressed: onToggle,
                  icon: AppDirectionalIcon(
                    collapsed
                        ? Icons.keyboard_double_arrow_right_rounded
                        : Icons.keyboard_double_arrow_left_rounded,
                    color: c.inkMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.destination,
    required this.label,
    required this.position,
    required this.selected,
    required this.collapsed,
    required this.badge,
    required this.onTap,
  });

  final ShellDestination destination;
  final String label;

  /// "Tab n of m", localized.
  final String position;
  final bool selected;
  final bool collapsed;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final ink = selected ? c.primaryInk : c.inkMuted;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimensions.xs,
        vertical: AppDimensions.xxs,
      ),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${badge ? l10n.navActionRequired(label) : label}\n$position',
        // excludeSemantics drops the InkWell's tap; the row names it here.
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: selected ? c.navIndicator : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppDimensions.touchTarget,
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimensions.sm,
                ),
                child: Row(
                  children: [
                    ShellIcon(
                      destination: destination,
                      selected: selected,
                      badge: badge,
                      color: ink,
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: _FadeIn(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: context.text.label.copyWith(color: ink),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades a sidebar label in when the sidebar expands; under reduce motion
/// the fade is short ([AppMotion.fade]). Opacity only, no layout per frame.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      _controller
        ..duration = context.motion.fade(Motion.standard)
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
