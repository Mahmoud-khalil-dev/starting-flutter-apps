import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_loading.dart';
import 'package:kit_app/core/widgets/app_state_views.dart';

/// The five screen states. Every screen shows exactly one.
enum ScreenStatus { loading, content, empty, error, offline }

/// Switches between the five states with a fade. Loading waits
/// [Motion.loadingDelay] before it shows and, once shown, holds at least
/// [Motion.loadingMinShow], so a skeleton neither flashes nor flickers.
class AppStateView extends StatefulWidget {
  const AppStateView({
    required this.status,
    required this.content,
    this.loading,
    this.empty,
    this.failure,
    this.onRetry,
    super.key,
  });

  final ScreenStatus status;
  final WidgetBuilder content;

  /// A skeleton of the content; the spinner when null.
  final Widget? loading;
  final Widget? empty;
  final Failure? failure;
  final VoidCallback? onRetry;

  @override
  State<AppStateView> createState() => _AppStateViewState();
}

class _AppStateViewState extends State<AppStateView> {
  /// What is on screen; null is the blank wait before loading shows.
  ScreenStatus? _shown;
  Timer? _delay;
  Timer? _hold;
  bool _held = false;

  @override
  void initState() {
    super.initState();
    _arrive(widget.status, initial: true);
  }

  @override
  void didUpdateWidget(AppStateView old) {
    super.didUpdateWidget(old);
    if (widget.status != old.status) _arrive(widget.status);
  }

  /// No setState in initState: the first state is assigned.
  void _show(ScreenStatus? status, {bool initial = false}) {
    if (initial || !mounted) {
      _shown = status;
    } else {
      setState(() => _shown = status);
    }
  }

  void _arrive(ScreenStatus status, {bool initial = false}) {
    if (status == ScreenStatus.loading) {
      if (_shown == ScreenStatus.loading || _delay != null) return;
      // First load waits blank; a reload keeps what is on screen, so the
      // wait never flashes empty.
      if (_shown == null) _show(null, initial: initial);
      _delay = Timer(Motion.loadingDelay, () {
        _delay = null;
        _held = true;
        _hold = Timer(Motion.loadingMinShow, () {
          _hold = null;
          _held = false;
          if (widget.status != ScreenStatus.loading) _show(widget.status);
        });
        _show(ScreenStatus.loading);
      });
      return;
    }
    _delay?.cancel();
    _delay = null;
    // While the skeleton holds, its timer shows the new state when it ends.
    if (_held) return;
    if (initial || _shown != status) _show(status, initial: initial);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _hold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: context.motion.fade(Motion.standard),
    switchInCurve: Motion.enter,
    switchOutCurve: Motion.exit,
    child: KeyedSubtree(
      key: ValueKey(_shown),
      child: switch (_shown) {
        // The blank wait fills a bounded parent and is nothing in an
        // unbounded one (a Column or Row child), where expand would throw.
        null => LayoutBuilder(
          builder: (context, box) => box.biggest.isFinite
              ? const SizedBox.expand()
              : const SizedBox.shrink(),
        ),
        ScreenStatus.loading => widget.loading ?? const AppLoading(),
        ScreenStatus.content => widget.content(context),
        ScreenStatus.empty => widget.empty ?? const AppEmptyView(),
        ScreenStatus.error => AppErrorView(
          failure: widget.failure ?? const UnknownFailure(),
          onRetry: widget.onRetry,
        ),
        ScreenStatus.offline => AppErrorView(
          failure: const NoConnection(),
          onRetry: widget.onRetry,
        ),
      },
    ),
  );
}
