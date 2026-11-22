import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:kit_app/core/theme/app_colors.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Hands the connection status down to every AppScaffold without a feature
/// importing the network layer. The app places it once, fed by the
/// ConnectivityService.
class ConnectionScope extends InheritedWidget {
  const ConnectionScope({
    required this.statuses,
    required super.child,
    this.initial = ConnectionStatus.online,
    super.key,
  });

  final Stream<ConnectionStatus> statuses;
  final ConnectionStatus initial;

  static ConnectionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConnectionScope>();

  @override
  bool updateShouldNotify(ConnectionScope old) =>
      statuses != old.statuses || initial != old.initial;
}

enum _Notice { offline, backOnline, slow }

/// The offline banner: slides from the top while offline,
/// says "Back online" for [Motion.bannerHold] after reconnecting, and names
/// a slow connection. Announced as it changes. Fades in place under reduce
/// motion.
class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({
    required this.statuses,
    this.initial = ConnectionStatus.online,
    super.key,
  });

  final Stream<ConnectionStatus> statuses;
  final ConnectionStatus initial;

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _show;
  late final CurvedAnimation _reveal;
  StreamSubscription<ConnectionStatus>? _subscription;
  Timer? _hold;
  _Notice? _notice;

  @override
  void initState() {
    super.initState();
    _show = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && _notice != null) {
          setState(() => _notice = null);
        }
      });
    _reveal = CurvedAnimation(
      parent: _show,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
    );
    _subscription = widget.statuses.listen(_on);
    if (widget.initial != ConnectionStatus.online) {
      _notice = _noticeFor(widget.initial);
      _show.value = 1;
    }
  }

  @override
  void didUpdateWidget(ConnectionBanner old) {
    super.didUpdateWidget(old);
    if (old.statuses != widget.statuses) {
      _subscription?.cancel();
      _subscription = widget.statuses.listen(_on);
    }
  }

  @override
  void dispose() {
    _hold?.cancel();
    _subscription?.cancel();
    _reveal.dispose();
    _show.dispose();
    super.dispose();
  }

  _Notice _noticeFor(ConnectionStatus status) =>
      status == ConnectionStatus.offline ? _Notice.offline : _Notice.slow;

  void _on(ConnectionStatus status) {
    // A repeated online must not restart or cut short the "Back online" hold.
    if (status == ConnectionStatus.online && _notice == _Notice.backOnline) {
      return;
    }
    _hold?.cancel();
    _show
      ..duration = context.motion.move(Motion.standard)
      ..reverseDuration = context.motion.fade(Motion.quick);
    if (status == ConnectionStatus.online) {
      if (_notice == null) return;
      if (_notice == _Notice.offline) {
        setState(() => _notice = _Notice.backOnline);
        _hold = Timer(Motion.bannerHold, _hide);
      } else {
        _hide();
      }
      return;
    }
    setState(() => _notice = _noticeFor(status));
    _show.forward();
  }

  void _hide() {
    if (!mounted) return;
    _show.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (notice == null) return const SizedBox.shrink();
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    // Every notice is a quiet raised surface in ink text; the icon
    // carries the tone (champagne gold for offline). All text pairs are
    // covered by T3's contrast test.
    final (text, fill, ink, icon, tint) = switch (notice) {
      _Notice.offline => (
        l10n.kitOffline,
        c.surfaceRaised,
        c.ink,
        Icons.wifi_off_rounded,
        c.gold,
      ),
      _Notice.backOnline => (
        l10n.kitBackOnline,
        c.surfaceRaised,
        c.ink,
        Icons.wifi_rounded,
        c.success,
      ),
      _Notice.slow => (
        l10n.kitSlowConnection,
        c.surfaceRaised,
        c.ink,
        Icons.network_check_rounded,
        c.warning,
      ),
    };
    final moves = context.motion.moves;
    return SlideTransition(
      position: Tween<Offset>(
        begin: moves ? const Offset(0, -1) : Offset.zero,
        end: Offset.zero,
      ).animate(_reveal),
      child: FadeTransition(
        opacity: _reveal,
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: fill,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.xs,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: AppDimensions.iconSm,
                        color: tint,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Expanded(
                      child: Text(
                        text,
                        style: context.text.label.copyWith(color: ink),
                      ),
                    ),
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
