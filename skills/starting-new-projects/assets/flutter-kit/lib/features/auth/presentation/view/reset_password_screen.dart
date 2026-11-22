import 'package:dartz/dartz.dart' show Unit;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/code_input_formatter.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/validation/validators.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_snackbar.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_password_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({required this.identifier, super.key});

  final String identifier;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Map<TextEditingController, String?> _errors = {};

  @override
  void dispose() {
    for (final c in [_code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final rules = Validators(context.l10n);
    final errors = {
      _code: AuthCodeField.rules(rules)(_code.text),
      _password: Validators.all([rules.required(), rules.password()])(
        _password.text,
      ),
      _confirm: Validators.all([
        rules.required(),
        rules.matches(() => _password.text),
      ])(_confirm.text),
    };
    setState(() => _errors = errors);
    if (errors.values.any((e) => e != null)) return;
    context.hideKeyboard();
    context.read<AuthCubit>().resetPassword(
      identifier: widget.identifier,
      code: CodeInputFormatter.clean(_code.text),
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    return BlocListener<AuthCubit, ViewState<Unit>>(
      listenWhen: (_, now) => now.status == ViewStatus.success,
      listener: (context, _) {
        AppSnackbar.show(
          context,
          l10n.authPasswordSaved,
          tone: SnackTone.success,
        );
        context.go(RouteNames.signIn);
      },
      child: AuthLayout(
        title: l10n.authResetTitle,
        body: l10n.authResetBody,
        footer: AppButton(
          label: l10n.authBackToSignInLink,
          variant: AppButtonVariant.quiet,
          onPressed: () => context.go(RouteNames.signIn),
        ),
        children: [
          AuthCodeField(
            controller: _code,
            errorText: _errors[_code],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimensions.md),
          AuthPasswordField(
            label: l10n.authNewPasswordLabel,
            controller: _password,
            errorText: _errors[_password],
            newPassword: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDimensions.md),
          AuthPasswordField(
            label: l10n.authConfirmPasswordLabel,
            controller: _confirm,
            errorText: _errors[_confirm],
            newPassword: true,
            onSubmitted: _submit,
          ),
          AuthFailureText(state: state),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: l10n.authResetAction,
            expand: true,
            state: state.isLoading
                ? AppButtonState.loading
                : AppButtonState.idle,
            onPressed: state.isLoading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
