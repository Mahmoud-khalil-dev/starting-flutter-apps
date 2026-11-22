import 'package:flutter/material.dart';
import 'package:kit_app/core/utils/code_input_formatter.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/validation/validators.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';

/// The one-time code field of verify and reset: digits only, shown as typed
/// (a paste of "123 456" becomes 123456, of "١٢٣-٤٥٦" becomes ١٢٣٤٥٦), at
/// most [maxLength] of them. Send `CodeInputFormatter.clean` of its text.
/// Masked in recordings through `AppTextField`'s sensitive default.
class AuthCodeField extends StatelessWidget {
  const AuthCodeField({
    required this.controller,
    this.errorText,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    super.key,
  });

  static const minLength = 4;
  static const maxLength = 8;

  final TextEditingController controller;
  final String? errorText;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  /// The rules a code must meet before it is sent.
  static Validator rules(Validators validators) => Validators.all([
    validators.required(),
    validators.length(min: minLength, max: maxLength),
  ]);

  @override
  Widget build(BuildContext context) => AppTextField(
    label: context.l10n.authCodeLabel,
    controller: controller,
    errorText: errorText,
    keyboardType: TextInputType.number,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
    inputFormatters: const [CodeInputFormatter(maxLength: maxLength)],
    autocorrect: false,
    leftToRight: true,
    autofillHints: const [AutofillHints.oneTimeCode],
  );
}
