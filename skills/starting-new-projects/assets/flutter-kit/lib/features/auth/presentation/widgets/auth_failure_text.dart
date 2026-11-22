import 'package:dartz/dartz.dart' show Unit;
import 'package:flutter/widgets.dart';
import 'package:kit_app/core/error/failure_messages.dart';
import 'package:kit_app/core/error/failures.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/inline_error.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// [credentials] true on sign-in: a 401 there means wrong details.
String authFailureMessage(
  AppLocalizations l10n,
  Failure failure, {
  bool credentials = false,
}) => switch (failure) {
  Unauthorized() when credentials => l10n.authInvalidCredentials,
  ValidationFailure(:final messages) when messages.isNotEmpty => messages.first,
  _ => failureMessage(l10n, failure) ?? l10n.errorUnknown,
};

/// The failure of the last auth action, under the form; nothing otherwise.
class AuthFailureText extends StatelessWidget {
  const AuthFailureText({
    required this.state,
    this.credentials = false,
    super.key,
  });

  final ViewState<Unit> state;
  final bool credentials;

  @override
  Widget build(BuildContext context) {
    final failure = state.status == ViewStatus.failure ? state.failure : null;
    if (failure == null) return const SizedBox.shrink();
    return InlineError(
      authFailureMessage(context.l10n, failure, credentials: credentials),
    );
  }
}
