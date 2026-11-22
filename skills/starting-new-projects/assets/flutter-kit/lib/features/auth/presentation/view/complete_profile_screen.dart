import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/core/media/avatar_upload_state.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/utils/context_extensions.dart';
import 'package:kit_app/core/validation/validators.dart';
import 'package:kit_app/core/widgets/app_avatar_upload.dart';
import 'package:kit_app/core/widgets/app_button.dart';
import 'package:kit_app/core/widgets/app_text_field.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_failure_text.dart';
import 'package:kit_app/features/auth/presentation/widgets/auth_layout.dart';

/// A signed-in, active user with no name yet (`RouteGuard.nameMissing`).
/// Saving the name updates the session; the guard then moves on.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    required this.onSignOut,
    required this.canUseCamera,
    this.canOpenSettings = true,
    super.key,
  });

  final Future<void> Function() onSignOut;

  /// `PlatformCapabilities.cameraCapture`: the photo sheet offers the camera.
  final bool canUseCamera;

  /// `PlatformCapabilities.appSettingsPage`, for the camera prompt.
  final bool canOpenSettings;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final rules = Validators(context.l10n);
    setState(
      () => _error = Validators.all([
        rules.required(),
        rules.length(min: 2, max: 80),
      ])(_name.text),
    );
    if (_error != null) return;
    context.hideKeyboard();
    context.read<AuthCubit>().completeProfile(name: _name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AuthCubit>().state;
    return AuthLayout(
      title: l10n.authCompleteTitle,
      body: l10n.authCompleteBody,
      footer: AppButton(
        label: l10n.authSignOutAction,
        variant: AppButtonVariant.quiet,
        onPressed: widget.onSignOut,
      ),
      children: [
        Center(
          // The initials follow the name as it is typed.
          child: ListenableBuilder(
            listenable: _name,
            builder: (context, _) =>
                BlocBuilder<AvatarUploadCubit, AvatarUploadState>(
                  builder: (context, upload) {
                    final cubit = context.read<AvatarUploadCubit>();
                    return AppAvatarUpload(
                      name: _name.text,
                      state: upload,
                      canUseCamera: widget.canUseCamera,
                      canOpenSettings: widget.canOpenSettings,
                      onChoose: cubit.choose,
                      onAllow: cubit.allowCamera,
                      onRetry: cubit.retry,
                      onOpenSettings: cubit.openSettings,
                    );
                  },
                ),
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        AppTextField(
          label: l10n.authNameLabel,
          controller: _name,
          errorText: _error,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          autofillHints: const [AutofillHints.name],
        ),
        AuthFailureText(state: state),
        const SizedBox(height: AppDimensions.lg),
        AppButton(
          label: l10n.authCompleteAction,
          expand: true,
          state: state.isLoading ? AppButtonState.loading : AppButtonState.idle,
          onPressed: state.isLoading ? null : _submit,
        ),
      ],
    );
  }
}
