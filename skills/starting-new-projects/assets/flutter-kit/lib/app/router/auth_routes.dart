import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/app/router/app_route.dart';
import 'package:kit_app/core/media/avatar_upload_cubit.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:kit_app/features/auth/presentation/cubit/resend_code_cubit.dart';
import 'package:kit_app/features/auth/presentation/view/account_status_screen.dart';
import 'package:kit_app/features/auth/presentation/view/complete_profile_screen.dart';
import 'package:kit_app/features/auth/presentation/view/forgot_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/reset_password_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_in_screen.dart';
import 'package:kit_app/features/auth/presentation/view/sign_up_screen.dart';
import 'package:kit_app/features/auth/presentation/view/verify_code_screen.dart';

/// The auth screens, each with a fresh Cubit. The guard decides who sees
/// which; these routes only build them.
List<RouteBase> authRoutes({
  required AuthCubit Function() authCubit,
  required ResendCodeCubit Function() resendCubit,
  required AvatarUploadCubit Function() avatarCubit,
  required bool canUseCamera,
  required bool canOpenSettings,
  required Future<void> Function() signOut,
}) {
  Widget withAuth(Widget screen) =>
      BlocProvider<AuthCubit>(create: (_) => authCubit(), child: screen);

  return [
    appRoute(
      path: RouteNames.signIn,
      builder: (context, state) => withAuth(const SignInScreen()),
    ),
    appRoute(
      path: RouteNames.signUp,
      builder: (context, state) => withAuth(const SignUpScreen()),
    ),
    appRoute(
      path: RouteNames.verify,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(create: (_) => authCubit()),
          BlocProvider<ResendCodeCubit>(
            create: (_) {
              // A screen that has just sent a code may open verify with
              // `extra: true`; after a guard redirect the repository says
              // so. A cold open allows a new code at once.
              return resendCubit()..begin(justSent: state.extra == true);
            },
          ),
        ],
        child: VerifyCodeScreen(onSignOut: signOut),
      ),
    ),
    appRoute(
      path: RouteNames.forgotPassword,
      builder: (context, state) => withAuth(const ForgotPasswordScreen()),
    ),
    appRoute(
      path: RouteNames.resetPassword,
      builder: (context, state) => withAuth(switch (state.extra) {
        final String identifier => ResetPasswordScreen(identifier: identifier),
        // A reload on the web loses `extra`: ask for the identifier again.
        _ => const ForgotPasswordScreen(),
      }),
    ),
    appRoute(
      path: RouteNames.completeProfile,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(create: (_) => authCubit()),
          BlocProvider<AvatarUploadCubit>(create: (_) => avatarCubit()),
        ],
        child: CompleteProfileScreen(
          onSignOut: signOut,
          canUseCamera: canUseCamera,
          canOpenSettings: canOpenSettings,
        ),
      ),
    ),
    appRoute(
      path: RouteNames.blocked,
      builder: (context, state) => AccountStatusScreen(
        kind: AccountStatusKind.blocked,
        onSignOut: signOut,
      ),
    ),
    appRoute(
      path: RouteNames.noAccess,
      builder: (context, state) => AccountStatusScreen(
        kind: AccountStatusKind.noAccess,
        onSignOut: signOut,
      ),
    ),
  ];
}
