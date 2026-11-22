import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/network/connectivity_service.dart';

/// The app lifecycle listener bootstrap keeps alive: connectivity pauses in
/// the background; a token the OS refused to read (a locked phone) is read
/// again on resume.
AppLifecycleListener wireSessionLifecycle({
  required ConnectivityService connectivity,
  required SessionRecovery recovery,
  WidgetsBinding? binding,
}) {
  final listener = AppLifecycleListener(
    binding: binding,
    onHide: connectivity.pause,
    onShow: connectivity.resume,
    onResume: () => unawaited(recovery.onResume()),
  );
  // A resume before the listener existed is not missed.
  unawaited(recovery.onResume());
  return listener;
}
