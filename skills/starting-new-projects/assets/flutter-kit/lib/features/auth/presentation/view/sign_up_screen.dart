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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  Map<TextEditingController, String?> _errors = {};

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final rules = Validators(context.l10n);
    final required = rules.required();
    final errors = {
      _name: Validators.all([required, rules.length(min: 2, max: 80)])(
        _name.text,
      ),
      _email: Validators.all([required, rules.email()])(_email.text),
      _phone: Validators.all([required, rules.phone()])(_phone.text),
      _password: Validators.all([required, rules.password()])(_password.text),
      _confirm: Validators.all([required, rules.matches(() => _password.text)])(
        _confirm.text,
      ),
    };
    setState(() => _errors = errors);
    if (errors.values.any((e) => e != null)) return;
    context.hideKeyboard();
    context.read<AuthCubit>().signUp(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    const gap = SizedBox(height: AppDimensions.md);
    return AuthLayout(
      title: l10n.authSignUpTitle,
      body: l10n.authSignUpBody,
      footer: AppButton(
        label: l10n.authHaveAccountLink,
        variant: AppButtonVariant.quiet,
        onPressed: () => context.go(RouteNames.signIn),
      ),
      children: [
        AppTextField(
          label: l10n.authNameLabel,
          controller: _name,
          errorText: _errors[_name],
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
        ),
        gap,
        AppTextField(
          label: l10n.authEmailLabel,
          controller: _email,
          errorText: _errors[_email],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          leftToRight: true,
          autofillHints: const [AutofillHints.email],
        ),
        gap,
        AppTextField(
          label: l10n.authPhoneLabel,
          controller: _phone,
          errorText: _errors[_phone],
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          digits: true,
          leftToRight: true,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        gap,
        AuthPasswordField(
          label: l10n.authPasswordLabel,
          controller: _password,
          errorText: _errors[_password],
          newPassword: true,
          textInputAction: TextInputAction.next,
        ),
        gap,
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
          label: l10n.authSignUpAction,
          expand: true,
          state: state.isLoading ? AppButtonState.loading : AppButtonState.idle,
          onPressed: state.isLoading ? null : _submit,
        ),
      ],
    );
  }
}
