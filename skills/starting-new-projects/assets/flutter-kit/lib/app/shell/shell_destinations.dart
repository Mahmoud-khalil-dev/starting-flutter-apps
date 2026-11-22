import 'package:flutter/material.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/l10n/app_localizations.dart';

enum ShellTab { home, settings }

@immutable
class ShellDestination {
  const ShellDestination({
    required this.tab,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final ShellTab tab;
  final String path;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (tab) {
    ShellTab.home => l10n.navHome,
    ShellTab.settings => l10n.navSettings,
  };

  @override
  String toString() => 'ShellDestination($tab)';
}

const _home = ShellDestination(
  tab: ShellTab.home,
  path: RouteNames.home,
  icon: Icons.home_outlined,
  selectedIcon: Icons.home_rounded,
);
const _settings = ShellDestination(
  tab: ShellTab.settings,
  path: RouteNames.settings,
  icon: Icons.settings_outlined,
  selectedIcon: Icons.settings_rounded,
);

/// The tabs per role. The kit gives every role the same two; return another
/// list for a role that sees other tabs, and keep [RouteNames.tabs] and
/// `RouteGuard.access` in step. A visitor with no session sees the member's.
List<ShellDestination> destinationsFor(AppRole? role) => switch (role) {
  AppRole.member || AppRole.admin || null => const [_home, _settings],
};

/// A destination's icon: outline when idle, filled when selected, the two
/// cross-fading; under reduce motion it swaps at once. A badge is a
/// dot keyed `badge-<tab>`. Shared by the bar, the rail and the
/// sidebar, so each tab looks and moves alike.
class ShellIcon extends StatelessWidget {
  const ShellIcon({
    required this.destination,
    required this.selected,
    this.badge = false,
    this.color,
    this.announceBadge = false,
    super.key,
  });

  final ShellDestination destination;
  final bool selected;
  final bool badge;

  /// Null takes the ambient [IconTheme], as the rail sets it.
  final Color? color;

  /// Adds "action required" to what a screen reader says for a badged tab.
  /// The bar needs it; the rail and the sidebar say it on their own labels.
  final bool announceBadge;

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedSwitcher(
      duration: context.motion.moves ? Motion.quick : Duration.zero,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      child: Icon(
        selected ? destination.selectedIcon : destination.icon,
        key: ValueKey(selected),
        color: color,
        size: AppDimensions.iconLg,
      ),
    );
    final dot = Badge(
      key: badge ? Key('badge-${destination.tab.name}') : null,
      isLabelVisible: badge,
      smallSize: AppDimensions.badgeDot,
      backgroundColor: context.colors.danger,
      child: icon,
    );
    if (!badge || !announceBadge) return dot;
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.navActionRequired(destination.label(l10n)),
      child: dot,
    );
  }
}
