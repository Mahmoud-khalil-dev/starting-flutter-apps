import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kit_app/core/l10n/digits.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/motion.dart';
import 'package:kit_app/core/widgets/app_sensitive.dart';
import 'package:kit_app/core/widgets/inline_error.dart';

/// A text field on the theme's input decoration. A new error shakes it once
/// (the only shake in the app); under reduce motion it does not move.
/// [digits] passes Western digits to [onChanged] while the field keeps
/// showing what was typed.
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.digits = false,
    this.leftToRight = false,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.suffix,
    this.inputFormatters,
    this.autocorrect = true,
    this.sensitive = true,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  /// The keyboard's action key, or Enter on a desktop or web keyboard. With
  /// `TextInputAction.next` the focus moves on by itself; the last field of a
  /// form uses `done` and submits here.
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool digits;

  /// Phone numbers, emails, codes: left to right in both languages.
  final bool leftToRight;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final Widget? suffix;

  /// Shapes typed and pasted text before it reaches the controller.
  final List<TextInputFormatter>? inputFormatters;

  /// False for an email, a code or a name that is not a word.
  final bool autocorrect;

  /// Hides what is typed from session recordings. False only for a
  /// field that never holds personal data, such as a search box.
  final bool sensitive;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: Motion.standard,
  );

  // Out, back, smaller, settle: one calm shake.
  static final _offsets = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -1, end: 1), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 1, end: -0.5), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -0.5, end: 0), weight: 1),
  ]);

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    final appeared = old.errorText == null && widget.errorText != null;
    if (appeared && context.motion.moves) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _changed(String text) =>
      widget.onChanged?.call(widget.digits ? normalizeDigits(text) : text);

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        key: const ValueKey('shake'),
        offset: Offset(
          _offsets.transform(Motion.enter.transform(_shake.value)) *
              AppDimensions.shakeOffset,
          0,
        ),
        child: child,
      ),
      child: _masked(
        TextField(
          controller: widget.controller,
          onChanged: _changed,
          onSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          autocorrect: widget.autocorrect,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          autofillHints: widget.autofillHints,
          textDirection: widget.leftToRight ? TextDirection.ltr : null,
          style: context.text.body,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            suffixIcon: widget.suffix,
            error: error == null ? null : InlineError(error),
          ),
        ),
      ),
    );
  }

  Widget _masked(Widget field) =>
      widget.sensitive ? AppSensitive(child: field) : field;
}
