import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kit_app/core/l10n/arabic_digit_localizations.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';
import 'package:kit_app/core/theme/app_theme_scope.dart';
import 'package:kit_app/core/theme/reduce_motion_scope.dart';
import 'package:kit_app/core/widgets/app_system_overlay.dart';
import 'package:kit_app/features/settings/data/models/app_settings.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:kit_app/features/settings/presentation/cubit/settings_state.dart';
import 'package:kit_app/l10n/app_localizations.dart';

/// The root MaterialApp on the go_router config. The user's choices come
/// from [settings]: the theme (system follows the platform brightness), the
/// language (null follows the device) and the text size, which multiplies
/// the system's up to a cap of 2.0. The theme itself comes from the language, the window width
/// and that brightness.
class App extends StatelessWidget {
  const App({
    required this.router,
    required this.settings,
    this.builder,
    this.masker = unmasked,
    super.key,
  });

  final GoRouter router;
  final SettingsCubit settings;
  final TransitionBuilder? builder;

  /// Hides what `AppSensitive` wraps from session recordings; the locator's
  /// [RecordingMasker], or none.
  final RecordingMasker masker;

  static Brightness? _brightness(ThemeMode mode) => switch (mode) {
    ThemeMode.system => null,
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
  };

  /// The system's own text scaling, times the user's, never above
  /// [AppSettings.maxEffectiveTextScale]. At 1.0 the system's scaler is kept
  /// as it is, so a platform's non-linear scaling survives.
  static MediaQueryData _scaled(MediaQueryData data, double textScale) =>
      data.copyWith(
        textScaler:
            (textScale == 1
                    ? data.textScaler
                    : TextScaler.linear(data.textScaler.scale(1) * textScale))
                .clamp(maxScaleFactor: AppSettings.maxEffectiveTextScale),
      );

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: settings,
    child: BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final chosen = state.settings;
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          locale: chosen.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            // First, so the Arabic-Indic digit strings win over the stock
            // ones.
            ArabicDigitMaterialLocalizations.delegate,
            ArabicDigitCupertinoLocalizations.delegate,
            ...AppLocalizations.localizationsDelegates,
          ],
          builder: (context, page) => MediaQuery(
            data: _scaled(MediaQuery.of(context), chosen.textScale),
            child: RecordingMaskScope(
              masker: masker,
              child: ReduceMotionScope(
                child: AppThemeScope(
                  brightness: _brightness(chosen.themeMode),
                  child: AppSystemOverlay(
                    child:
                        builder?.call(context, page) ??
                        page ??
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
