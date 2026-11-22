import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';

/// The shape of an AppRow: avatar, title, value.
/// Put under an AppShimmer; AppSkeletonList does that for a list.
class AppSkeletonRow extends StatelessWidget {
  const AppSkeletonRow({this.leading = true, super.key});

  final bool leading;

  // AppRow's own box (app_row.dart): its padding, its gap after the
  // leading and its minimum height, so the content does not move when the
  // real rows replace the skeleton. A test pins both against AppRow.
  static const EdgeInsetsDirectional _padding = EdgeInsetsDirectional.symmetric(
    horizontal: AppDimensions.md,
    vertical: AppDimensions.sm,
  );
  static const double _gap = AppDimensions.sm;

  /// The row's height, from the same tokens it lays out with.
  static double get extent => math.max(
    AppDimensions.touchTarget,
    AppDimensions.avatarMd + _padding.vertical,
  );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: AppDimensions.touchTarget),
    child: Padding(
      padding: _padding,
      child: Row(
        children: [
          if (leading) ...[
            const AppSkeleton.circle(),
            const SizedBox(width: _gap),
          ],
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.bar(widthFactor: 0.6),
                SizedBox(height: AppDimensions.xs),
                AppSkeleton.bar(widthFactor: 0.35),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// A card: optional 16:9 image, a title, a line and a pill.
class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({this.image = false, super.key});

  final bool image;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.all(AppDimensions.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image) ...[
            const AspectRatio(
              key: ValueKey('skeleton-image'),
              aspectRatio: 16 / 9,
              child: AppSkeleton(
                height: double.infinity,
                radius: AppDimensions.radiusMd,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
          ],
          const AppSkeleton.bar(widthFactor: 0.7),
          const SizedBox(height: AppDimensions.sm),
          const AppSkeleton.bar(widthFactor: 0.45),
          const SizedBox(height: AppDimensions.md),
          const AppSkeleton(
            height: AppDimensions.lg,
            width: AppDimensions.xxxl,
            radius: AppDimensions.radiusPill,
          ),
        ],
      ),
    ),
  );
}

/// A screen header: a headline-high bar and a line under it.
class AppSkeletonHeader extends StatelessWidget {
  const AppSkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: AppDimensions.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton.bar(widthFactor: 0.5),
        SizedBox(height: AppDimensions.sm),
        AppSkeleton.bar(widthFactor: 0.8),
      ],
    ),
  );
}

/// Rows enough to fill the height, under one shimmer, so a short list
/// never shows a blank band under its skeleton.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({this.rows, this.announce = true, super.key});

  /// As [AppShimmer.announce]: false when another shimmer on the screen
  /// already says "Loading".
  final bool announce;

  /// Null: as many as fill a bounded height, or [_unbounded] without one.
  final int? rows;

  /// Rows when the height is unbounded (a column in a scroll view): a
  /// fixed fallback, not a size.
  static const int _unbounded = 6;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final fills = rows == null && box.hasBoundedHeight;
      final count =
          rows ??
          (fills
              ? math.max(1, (box.maxHeight / AppSkeletonRow.extent).ceil())
              : _unbounded);
      final Widget column = Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < count; i++) const AppSkeletonRow()],
      );
      return AppShimmer(
        announce: announce,
        // Filling a bounded height clips the last row; otherwise the list
        // is its rows' own height (an OverflowBox under an unbounded height
        // would size to infinity).
        child: fills
            ? ClipRect(
                child: OverflowBox(
                  alignment: AlignmentDirectional.topStart,
                  maxHeight: double.infinity,
                  child: column,
                ),
              )
            : column,
      );
    },
  );
}
