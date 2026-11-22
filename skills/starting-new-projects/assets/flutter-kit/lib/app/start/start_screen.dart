import 'package:flutter/material.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/startup_decision.dart';
import 'package:kit_app/core/widgets/startup_gate.dart';

/// The splash: a blank ground while the saved session settles. When
/// `startupDecision` says the session is settled it calls [onRoute] once
/// (the router then picks the screen); when the session stays unread it
/// shows the quiet retry notice, and Try again calls [onTryAgain].
class StartScreen extends StatelessWidget {
  const StartScreen({
    required this.session,
    required this.onRoute,
    required this.onTryAgain,
    super.key,
  });

  final SessionCubit session;
  final VoidCallback onRoute;
  final Future<void> Function() onTryAgain;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: StartupGate(
        decide: ({required resumed, required sinceResume}) => startupDecision(
          status: session.state.status,
          resumed: resumed,
          sinceResume: sinceResume,
        ),
        onRoute: onRoute,
        onTryAgain: onTryAgain,
      ),
    ),
  );
}
