import 'package:flutter/material.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';

/// A password field with a show and hide button. Masked in recordings
/// through `AppTextField`'s sensitive default.
class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    required this.label,
    required this.controller,
    this.errorText,
    this.newPassword = false,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final bool newPassword;
  final TextInputAction textInputAction;

  /// Enter or the keyboard's action on this field; the last field of a form
  /// submits here.
  final VoidCallback? onSubmitted;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _hidden = true;

  // Next goes to the next field, not to this button.
  final _toggleFocus = FocusNode(skipTraversal: true);

  @override
  void dispose() {
    _toggleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: widget.label,
    controller: widget.controller,
    errorText: widget.errorText,
    obscureText: _hidden,
    leftToRight: true,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: widget.textInputAction,
    onSubmitted: widget.onSubmitted == null
        ? null
        : (_) => widget.onSubmitted!(),
    autofillHints: [
      if (widget.newPassword)
        AutofillHints.newPassword
      else
        AutofillHints.password,
    ],
    suffix: IconButton(
      focusNode: _toggleFocus,
      tooltip: _hidden
          ? context.l10n.authShowPassword
          : context.l10n.authHidePassword,
      icon: Icon(
        _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _hidden = !_hidden),
    ),
  );
}
