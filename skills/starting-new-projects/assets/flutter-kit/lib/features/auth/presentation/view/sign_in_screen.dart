import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/validation/validators.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_password_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final rules = Validators(context.l10n);
    setState(() {
      _identifierError = rules.required()(_identifier.text);
      _passwordError = rules.required()(_password.text);
    });
    if (_identifierError != null || _passwordError != null) return;
    context.hideKeyboard();
    context.read<AuthCubit>().signIn(
      identifier: _identifier.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    return AuthLayout(
      title: l10n.authSignInTitle,
      body: l10n.authSignInBody,
      footer: AppButton(
        label: l10n.authNoAccountLink,
        variant: AppButtonVariant.quiet,
        onPressed: () => context.go(RouteNames.signUp),
      ),
      children: [
        AppTextField(
          label: l10n.authIdentifierLabel,
          controller: _identifier,
          errorText: _identifierError,
          // Types an email and a phone number alike.
          keyboardType: TextInputType.text,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          leftToRight: true,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: AppDimensions.md),
        AuthPasswordField(
          label: l10n.authPasswordLabel,
          controller: _password,
          errorText: _passwordError,
          onSubmitted: _submit,
        ),
        AuthFailureText(state: state, credentials: true),
        const SizedBox(height: AppDimensions.lg),
        AppButton(
          label: l10n.authSignInAction,
          expand: true,
          state: state.isLoading ? AppButtonState.loading : AppButtonState.idle,
          onPressed: state.isLoading ? null : _submit,
        ),
        AppButton(
          label: l10n.authForgotLink,
          variant: AppButtonVariant.quiet,
          onPressed: () => context.push(RouteNames.forgotPassword),
        ),
      ],
    );
  }
}
