import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/platform_style.dart';

/// A pull-to-refresh list in the platform's own idiom: the stretching
/// Cupertino control on iOS, the Material indicator elsewhere.
class AppRefreshList extends StatelessWidget {
  const AppRefreshList({
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
    this.footer,
    this.padding,
    this.controller,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final list = SliverPadding(
      padding: padding ?? EdgeInsetsDirectional.zero,
      sliver: SliverList.builder(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
    final tail = [if (footer != null) SliverToBoxAdapter(child: footer)];
    if (context.isCupertino) {
      return CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          list,
          ...tail,
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.colors.primaryInk,
      child: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [list, ...tail],
      ),
    );
  }
}
