import 'package:flutter/widgets.dart';

/// Folds the platform's reduce-motion flag (iOS Reduce Motion) into
/// MediaQuery.disableAnimations (Android "Remove animations"), so every
/// widget asks one place: `context.motion`. Rebuilds when the setting
/// changes. Place it once in the app builder.
class ReduceMotionScope extends StatefulWidget {
  const ReduceMotionScope({required this.child, super.key});

  final Widget child;

  @override
  State<ReduceMotionScope> createState() => _ReduceMotionScopeState();
}

class _ReduceMotionScopeState extends State<ReduceMotionScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final platform = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion;
    return MediaQuery(
      data: media.copyWith(
        disableAnimations: media.disableAnimations || platform,
      ),
      child: widget.child,
    );
  }
}
