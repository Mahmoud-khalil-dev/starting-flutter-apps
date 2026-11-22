import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_refresh_list.dart';
import 'package:kit_app/core/widgets/app_shimmer.dart';
import 'package:kit_app/core/widgets/app_skeletons.dart';
import 'package:kit_app/core/widgets/inline_error.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// A refreshable list that asks for the next page when the reader comes
/// within [AppDimensions.loadMoreExtent] of the end. A failed page shows
/// a footer error with Try again; the rows above stay.
class AppPagedList extends StatefulWidget {
  const AppPagedList({
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreError,
    this.onRetryMore,
    this.padding,
    super.key,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool loadingMore;
  final String? loadMoreError;
  final VoidCallback? onRetryMore;
  final EdgeInsetsGeometry? padding;

  @override
  State<AppPagedList> createState() => _AppPagedListState();
}

class _AppPagedListState extends State<AppPagedList> {
  final _controller = ScrollController();

  // Asked once per item count, so a slow page is not requested twice.
  int? _askedAt;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
    _checkAfterFrame();
  }

  @override
  void didUpdateWidget(AppPagedList old) {
    super.didUpdateWidget(old);
    if (old.hasMore != widget.hasMore) _askedAt = null;
    if (old.itemCount != widget.itemCount ||
        old.hasMore != widget.hasMore ||
        old.loadingMore != widget.loadingMore ||
        old.loadMoreError != widget.loadMoreError) {
      _checkAfterFrame();
    }
  }

  // A page shorter than the viewport never scrolls, so no scroll event
  // would ask for the next one.
  void _checkAfterFrame() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _maybeLoadMore();
  });

  Future<void> _refresh() async {
    await widget.onRefresh();
    _askedAt = null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final near =
        position.maxScrollExtent - position.pixels <=
        AppDimensions.loadMoreExtent;
    final idle = !widget.loadingMore && widget.loadMoreError == null;
    if (near && idle && widget.hasMore && _askedAt != widget.itemCount) {
      _askedAt = widget.itemCount;
      widget.onLoadMore();
    }
  }

  Widget? get _footer {
    final error = widget.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppDimensions.md),
        child: Column(
          children: [
            InlineError(error),
            const SizedBox(height: AppDimensions.xs),
            AppButton(
              label: AppLocalizations.of(context)!.kitRetry,
              onPressed: widget.onRetryMore,
              variant: AppButtonVariant.quiet,
            ),
          ],
        ),
      );
    }
    if (widget.loadingMore) {
      // Report 10 section 6.4: two rows, not a spinner.
      return const AppShimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [AppSkeletonRow(), AppSkeletonRow()],
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AppRefreshList(
    controller: _controller,
    onRefresh: _refresh,
    itemCount: widget.itemCount,
    itemBuilder: widget.itemBuilder,
    padding: widget.padding,
    footer: _footer,
  );
}
