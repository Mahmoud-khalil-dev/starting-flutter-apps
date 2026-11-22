import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kit_app/app/shell/app_sidebar.dart';
import 'package:kit_app/app/shell/fit_label.dart';
import 'package:kit_app/app/shell/frosted_nav_bar.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_haptics.dart';
import 'package:kit_app/core/utils/responsive.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The app shell: a frosted bar at compact width on every platform, a rail
/// at medium, the sidebar at expanded. It knows paths, not screens: the
/// router passes [location] and the current page as [child].
class AppShell extends StatefulWidget {
  const AppShell({
    required this.role,
    required this.location,
    required this.child,
    required this.onSelect,
    this.onReselect,
    this.badges = const {},
    this.aboveBar,
    super.key,
  });

  /// The signed-in role; null for a visitor with no session.
  final AppRole? role;
  final String location;
  final Widget child;
  final ValueChanged<String> onSelect;

  /// Tapping the current tab: scroll to top or pop to the tab's root.
  final ValueChanged<String>? onReselect;
  final Set<ShellTab> badges;

  /// A slot directly above the bar, such as an ongoing-activity banner.
  final Widget? aboveBar;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _collapsed = false;

  /// Keeps the page's State when the window crosses a width class and the
  /// shell swaps its layout around it.
  final GlobalKey _childKey = GlobalKey();

  Widget get _page => KeyedSubtree(key: _childKey, child: widget.child);

  List<ShellDestination> get _destinations => destinationsFor(widget.role);

  int get _selected {
    final i = _destinations.indexWhere(
      (d) =>
          widget.location == d.path || widget.location.startsWith('${d.path}/'),
    );
    assert(i >= 0, 'AppShell: ${widget.location} is no tab of ${widget.role}');
    // Release: no tab is highlighted.
    return i;
  }

  void _tap(int index) {
    final path = _destinations[index].path;
    if (index == _selected) {
      widget.onReselect?.call(path);
      return;
    }
    AppHaptics.selection();
    widget.onSelect(path);
  }

  Widget _icon(
    ShellDestination d, {
    required bool selected,
    bool announceBadge = false,
  }) => ShellIcon(
    destination: d,
    selected: selected,
    badge: widget.badges.contains(d.tab),
    announceBadge: announceBadge,
  );

  /// The page fills the screen and scrolls under the bar: with `extendBody`
  /// its bottom inset takes the bar's footprint, so a list's last row and a
  /// form's button clear the bar once scrolled to the end.
  Widget _compact(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected;
    return Scaffold(
      extendBody: true,
      body: _page,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?widget.aboveBar,
          FrostedNavBar(
            selectedIndex: math.max(selected, 0),
            onSelected: _tap,
            destinations: [
              for (var i = 0; i < _destinations.length; i++)
                FitLabel(
                  label: _destinations[i].label(l10n),
                  child: NavigationDestination(
                    icon: _icon(
                      _destinations[i],
                      selected: i == selected,
                      announceBadge: true,
                    ),
                    label: _destinations[i].label(l10n),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _medium(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selected < 0 ? null : _selected,
            onDestinationSelected: _tap,
            labelType: NavigationRailLabelType.all,
            minWidth: AppDimensions.railWidth,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: _icon(d, selected: false),
                  selectedIcon: _icon(d, selected: true),
                  // The rail's own inset plus this keeps a long label
                  // clear of the rail's edges.
                  label: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppDimensions.xxs,
                    ),
                    child: Text(
                      d.label(l10n),
                      // The rail reads the label; a badge adds its notice.
                      semanticsLabel: widget.badges.contains(d.tab)
                          ? l10n.navActionRequired(d.label(l10n))
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          VerticalDivider(
            width: AppDimensions.hairline,
            color: context.colors.divider,
          ),
          Expanded(child: _page),
        ],
      ),
    );
  }

  Widget _expanded(BuildContext context) => Scaffold(
    body: Row(
      children: [
        AppSidebar(
          destinations: _destinations,
          selected: _selected,
          onTap: _tap,
          collapsed: _collapsed,
          onToggle: () => setState(() => _collapsed = !_collapsed),
          badges: widget.badges,
        ),
        Expanded(child: _page),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) =>
      AdaptiveLayout(compact: _compact, medium: _medium, expanded: _expanded);
}
