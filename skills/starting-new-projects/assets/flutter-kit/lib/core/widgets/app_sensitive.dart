import 'package:flutter/widgets.dart';
import 'package:kit_app/core/telemetry/recording_mask.dart';

/// Hides personal content from session recordings: names, emails, phone
/// numbers, codes, notes, account and financial text. The screen looks and
/// behaves the same; only a recording is masked, by the [RecordingMasker]
/// the app registered (none by default, so nothing changes). Wrap a screen's
/// body once rather than single texts, and leave public chrome (buttons,
/// headings, tab bars) outside, so recordings still show where users get
/// stuck.
class AppSensitive extends StatelessWidget {
  const AppSensitive({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => RecordingMaskScope.of(context)(child);
}
