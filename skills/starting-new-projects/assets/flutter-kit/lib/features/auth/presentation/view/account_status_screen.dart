import 'package:flutter/material.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';

enum AccountStatusKind { blocked, noAccess }

/// Where the guard sends a blocked account or one with no role here. The
/// only way on is to sign out.
class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({
    required this.kind,
    required this.onSignOut,
    super.key,
  });

  final AccountStatusKind kind;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, body) = switch (kind) {
      AccountStatusKind.blocked => (
        l10n.authBlockedTitle,
        l10n.authBlockedBody,
      ),
      AccountStatusKind.noAccess => (
        l10n.authNoAccessTitle,
        l10n.authNoAccessBody,
      ),
    };
    return AuthLayout(
      title: title,
      body: body,
      children: [
        AppButton(
          label: l10n.authSignOutAction,
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: onSignOut,
        ),
      ],
    );
  }
}
