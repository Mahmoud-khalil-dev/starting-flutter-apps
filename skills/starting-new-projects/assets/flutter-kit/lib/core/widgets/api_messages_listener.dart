import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kit_app/core/error/failure_messages.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/widgets/app_snackbar.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// Shows the failures the StatusInterceptor reports (ApiMessages.failures)
/// as danger snackbars. A cancel has no message and shows nothing. The app
/// places it once under the ScaffoldMessenger.
class ApiMessagesListener extends StatefulWidget {
  const ApiMessagesListener({
    required this.messages,
    required this.child,
    super.key,
  });

  final Stream<Failure> messages;
  final Widget child;

  @override
  State<ApiMessagesListener> createState() => _ApiMessagesListenerState();
}

class _ApiMessagesListenerState extends State<ApiMessagesListener> {
  StreamSubscription<Failure>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.messages.listen(_show, onError: _ignore);
  }

  @override
  void didUpdateWidget(ApiMessagesListener old) {
    super.didUpdateWidget(old);
    if (old.messages != widget.messages) {
      unawaited(_subscription?.cancel());
      _subscription = widget.messages.listen(_show, onError: _ignore);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  // A failing stream must not take the app down; there is nothing to show.
  void _ignore(Object error) {}

  void _show(Failure failure) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null || ScaffoldMessenger.maybeOf(context) == null) return;
    final message = failureMessage(l10n, failure);
    if (message == null) return;
    AppSnackbar.show(context, message, tone: SnackTone.danger);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
