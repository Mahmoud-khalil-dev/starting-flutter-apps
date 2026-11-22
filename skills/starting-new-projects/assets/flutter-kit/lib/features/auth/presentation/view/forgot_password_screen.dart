import 'package:dartz/dartz.dart' show Unit;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/state/view_state.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/validation/validators.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifier = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  void _submit() {
    setState(
      () => _error = Validators(context.l10n).required()(_identifier.text),
    );
    if (_error != null) return;
    context.hideKeyboard();
    context.read<AuthCubit>().requestPasswordReset(_identifier.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    // The identifier travels as `extra`, never in the URL.
    return BlocListener<AuthCubit, ViewState<Unit>>(
      listenWhen: (_, now) => now.status == ViewStatus.success,
      listener: (context, _) => context.pushReplacement(
        RouteNames.resetPassword,
        extra: _identifier.text,
      ),
      child: AuthLayout(
        title: l10n.authForgotTitle,
        body: l10n.authForgotBody,
        footer: AppButton(
          label: l10n.authBackToSignInLink,
          variant: AppButtonVariant.quiet,
          onPressed: () => context.go(RouteNames.signIn),
        ),
        children: [
          AppTextField(
            label: l10n.authIdentifierLabel,
            controller: _identifier,
            errorText: _error,
            // Types an email and a phone number alike.
            keyboardType: TextInputType.text,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            leftToRight: true,
            autofillHints: const [AutofillHints.username],
          ),
          AuthFailureText(state: state),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: l10n.authSendCodeAction,
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
