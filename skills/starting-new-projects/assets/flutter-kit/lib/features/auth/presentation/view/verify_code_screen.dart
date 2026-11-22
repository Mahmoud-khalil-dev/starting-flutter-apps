import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/code_input_formatter.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/validation/validators.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_snackbar.dart';
import 'package:kit_app/core/widgets/inline_error.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';

/// A signed-in user whose account is not active yet. The guard sends them
/// here and moves them on once the verified user is saved.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final rules = Validators(context.l10n);
    setState(() => _error = AuthCodeField.rules(rules)(_code.text));
    if (_error != null) return;
    context.hideKeyboard();
    context.read<AuthCubit>().verifyCode(CodeInputFormatter.clean(_code.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    final resend = context.watch<ResendCodeCubit>().state;
    return BlocListener<ResendCodeCubit, ResendState>(
      listenWhen: (before, now) => now.sentCount > before.sentCount,
      listener: (context, _) =>
          AppSnackbar.show(context, l10n.authCodeSent, tone: SnackTone.success),
      child: AuthLayout(
        title: l10n.authVerifyTitle,
        body: l10n.authVerifyBody,
        footer: AppButton(
          label: l10n.authSignOutAction,
          variant: AppButtonVariant.quiet,
          onPressed: widget.onSignOut,
        ),
        children: [
          AuthCodeField(
            controller: _code,
            errorText: _error,
            onSubmitted: _submit,
          ),
          AuthFailureText(state: state),
          if (resend.failure case final failure?)
            InlineError(authFailureMessage(l10n, failure)),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: l10n.authVerifyAction,
            expand: true,
            state: state.isLoading
                ? AppButtonState.loading
                : AppButtonState.idle,
            onPressed: state.isLoading ? null : _submit,
          ),
          const SizedBox(height: AppDimensions.xs),
          if (resend.canSend)
            AppButton(
              label: l10n.authResendAction,
              variant: AppButtonVariant.quiet,
              onPressed: context.read<ResendCodeCubit>().resend,
            )
          else
            Text(
              l10n.authResendIn(context.formats.formatDuration(resend.left)),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
