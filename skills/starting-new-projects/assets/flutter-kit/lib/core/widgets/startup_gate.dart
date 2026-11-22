import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:kit_app/core/logging/app_log.dart';
import 'package:kit_app/core/session/startup_decision.dart';
import 'package:kit_app/core/widgets/startup_retry_notice.dart';

/// Asks what start-up does next. [resumed] is whether the app is in the
/// foreground; [sinceResume] is how long it has been since the gate first saw
/// it there (zero while it is not).
typedef StartupDecisionSource =
    StartupAction Function({
      required bool resumed,
      required Duration sinceResume,
    });

/// Owns the splash's wait while the session is unsettled: it asks
/// [decide] each second and when the app returns to the foreground, calls
/// [onRoute] once when start-up may go on, and shows [StartupRetryNotice]
/// when [decide] says retry. Try again calls [onTryAgain], hides the notice
/// and starts the wait again. Time is read from `clock`, so a test can
/// drive it with fake time.
class StartupGate extends StatefulWidget {
  const StartupGate({
    required this.decide,
    required this.onRoute,
    required this.onTryAgain,
    this.pollInterval = startupPoll,
    super.key,
  });

  final StartupDecisionSource decide;
  final VoidCallback onRoute;
  final Future<void> Function() onTryAgain;
  final Duration pollInterval;

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> with WidgetsBindingObserver {
  Timer? _poll;
  DateTime? _resumedSince;
  bool _showRetry = false;
  bool _routed = false;

  bool get _resumed =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(widget.pollInterval, (_) => _check());
    scheduleMicrotask(_check);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _check();

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _check() {
    if (!mounted || _routed) return;
    final resumed = _resumed;
    _resumedSince = resumed ? (_resumedSince ?? clock.now()) : null;
    StartupAction action;
    try {
      action = widget.decide(
        resumed: resumed,
        sinceResume: _resumedSince == null
            ? Duration.zero
            : clock.now().difference(_resumedSince!),
      );
    } on Object {
      action = StartupAction.route;
    }
    if (action == StartupAction.route) {
      _routed = true;
      _poll?.cancel();
      if (_showRetry) setState(() => _showRetry = false);
      widget.onRoute();
      return;
    }
    final retry = action == StartupAction.retry;
    if (retry != _showRetry) setState(() => _showRetry = retry);
  }

  Future<void> _tryAgain() async {
    setState(() => _showRetry = false);
    _resumedSince = _resumed ? clock.now() : null;
    try {
      await widget.onTryAgain();
    } on Object catch (error) {
      AppLog.error('Start-up retry failed', error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showRetry) return const SizedBox.shrink();
    return StartupRetryNotice(onRetry: _tryAgain);
  }
}
