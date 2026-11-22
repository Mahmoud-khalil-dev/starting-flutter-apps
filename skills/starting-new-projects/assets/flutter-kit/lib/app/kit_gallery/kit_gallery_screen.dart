import 'package:flutter/material.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_samples.dart';
import 'package:kit_app/app/kit_gallery/kit_gallery_sections.dart';
import 'package:kit_app/core/l10n/app_formats.dart';
import 'package:kit_app/core/l10n/arabic_digit_localizations.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/app_text_styles.dart';
import 'package:kit_app/core/theme/app_theme_scope.dart';
import 'package:kit_app/core/time/app_clock.dart';
import 'package:kit_app/core/widgets/app_group.dart';
import 'package:kit_app/core/widgets/app_row.dart';
import 'package:kit_app/core/widgets/app_scaffold.dart';
import 'package:kit_app/core/widgets/app_segmented.dart';
import 'package:kit_app/core/widgets/app_sheet.dart';

/// The kit gallery (debug builds only, route /kit): every component in
/// every state, with switches for theme, language, platform, text size and
/// reduce motion, so each can be checked on a device in a minute.
class KitGalleryScreen extends StatefulWidget {
  const KitGalleryScreen({this.clock = const SystemClock(), super.key});

  final AppClock clock;

  @override
  State<KitGalleryScreen> createState() => _KitGalleryScreenState();
}

class _KitGalleryScreenState extends State<KitGalleryScreen> {
  static const _textScales = [1.0, 1.3, 2.0];

  Brightness _brightness = Brightness.light;
  String _language = 'en';
  TargetPlatform? _platform;
  double _textScale = 1;
  bool _reduceMotion = false;
  bool _highContrast = false;

  /// The page is a route of its own navigator, which a rebuild of this
  /// state does not reach; this tells it to draw again.
  final _redraw = ValueNotifier<int>(0);

  void _update(VoidCallback change) {
    setState(change);
    _redraw.value++;
  }

  @override
  void dispose() {
    _redraw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: Locale(_language),
    // The gallery switches language under the app's own delegates, so it
    // brings the digit ones, and its pickers show Arabic-Indic digits.
    delegates: const [
      ArabicDigitMaterialLocalizations.delegate,
      ArabicDigitCupertinoLocalizations.delegate,
    ],
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_textScale),
          disableAnimations: _reduceMotion,
          highContrast: _highContrast,
        ),
        child: AppThemeScope(
          brightness: _brightness,
          platform: _platform,
          // Its own navigator under the overrides, so a sheet, a picker or a
          // dialog opened from the page inherits the theme, text size,
          // contrast, motion and language set here, not the app's.
          child: AppNestedOverlays(
            child: Navigator(
              onGenerateRoute: (_) => PageRouteBuilder<void>(
                pageBuilder: (context, _, _) => ValueListenableBuilder<int>(
                  valueListenable: _redraw,
                  builder: (context, _, _) => _page(context),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _page(BuildContext context) {
    String s(String en, String ar) => sample(context, en: en, ar: ar);
    final f = AppFormats.of(context);
    final platform = _platform ?? Theme.of(context).platform;
    return AppScaffold(
      title: s('Kit gallery', 'معرض المكوّنات'),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: AppDimensions.xxl),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.all(AppDimensions.md),
            child: Column(
              children: [
                AppSegmented<Brightness>(
                  segments: [
                    AppSegment(
                      value: Brightness.light,
                      label: s('Light', 'فاتح'),
                    ),
                    AppSegment(
                      value: Brightness.dark,
                      label: s('Dark', 'داكن'),
                    ),
                  ],
                  selected: _brightness,
                  onChanged: (v) => _update(() => _brightness = v),
                ),
                const SizedBox(height: AppDimensions.xs),
                AppSegmented<String>(
                  segments: const [
                    AppSegment(value: 'en', label: 'English'),
                    AppSegment(value: 'ar', label: 'العربية'),
                  ],
                  selected: _language,
                  onChanged: (v) => _update(() => _language = v),
                ),
                const SizedBox(height: AppDimensions.xs),
                AppSegmented<TargetPlatform>(
                  segments: const [
                    AppSegment(value: TargetPlatform.android, label: 'Android'),
                    AppSegment(value: TargetPlatform.iOS, label: 'iOS'),
                  ],
                  selected: platform == TargetPlatform.iOS
                      ? TargetPlatform.iOS
                      : TargetPlatform.android,
                  onChanged: (v) => _update(() => _platform = v),
                ),
                const SizedBox(height: AppDimensions.xs),
                AppSegmented<double>(
                  segments: [
                    for (final scale in _textScales)
                      AppSegment(
                        value: scale,
                        label: _language == 'ar'
                            ? '${f.formatNumber(scale * 100)}٪'
                            : '${f.formatNumber(scale * 100)}%',
                      ),
                  ],
                  selected: _textScale,
                  onChanged: (v) => _update(() => _textScale = v),
                ),
              ],
            ),
          ),
          AppGroup(
            children: [
              AppRow.toggle(
                title: s('Reduce motion', 'تقليل الحركة'),
                value: _reduceMotion,
                onChanged: (v) => _update(() => _reduceMotion = v),
              ),
              AppRow.toggle(
                title: s('Increase contrast', 'زيادة التباين'),
                value: _highContrast,
                onChanged: (v) => _update(() => _highContrast = v),
              ),
            ],
          ),
          for (final section in KitSection.values) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDimensions.md,
                AppDimensions.xl,
                AppDimensions.md,
                AppDimensions.xs,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  section.title(context),
                  style: context.text.headline,
                ),
              ),
            ),
            section.build(clock: widget.clock),
          ],
        ],
      ),
    );
  }
}
