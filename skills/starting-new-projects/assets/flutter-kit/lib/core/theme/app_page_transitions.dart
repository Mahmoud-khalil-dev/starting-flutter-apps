import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kit_app/core/theme/motion.dart';

/// Page transitions: iOS keeps the native interactive
/// swipe-back, also under reduce motion (the gesture is the user's);
/// everywhere else a fade-through. appPage stays a MaterialPage, so the
/// theme picks.
abstract final class AppPageTransitions {
  /// The web build, whatever OS the browser reports: the browser owns back,
  /// so no edge swipe fights it.
  static const web = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
    },
  );

  static const theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
      TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
    },
  );
}

/// The old page fades out over the first 35%, the new one fades in and
/// settles from 94% scale over the rest. Under reduce motion: a plain fade
/// over the first 40% (192 ms of [Motion.gentle]).
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Motion.gentle;

  @override
  Duration get reverseTransitionDuration => Motion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _FadeThrough(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}

class _FadeThrough extends StatefulWidget {
  const _FadeThrough({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_FadeThrough> createState() => _FadeThroughState();
}

class _FadeThroughState extends State<_FadeThrough> {
  static const _split = 0.35;
  static const _reducedEnd = 0.4;
  static const _startScale = 0.94;

  late CurvedAnimation _reduced;
  late CurvedAnimation _incoming;
  late CurvedAnimation _outgoing;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void didUpdateWidget(_FadeThrough old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation ||
        old.secondaryAnimation != widget.secondaryAnimation) {
      _dispose();
      _create();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _create() {
    _reduced = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0, _reducedEnd, curve: Motion.enter),
      // A pop mirrors the push: the fade fills the first 40% of the reverse.
      reverseCurve: const Interval(1 - _reducedEnd, 1, curve: Motion.exit),
    );
    _incoming = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(_split, 1, curve: Motion.enter),
    );
    _outgoing = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: const Interval(0, _split, curve: Motion.exit),
    );
    _scale = Tween<double>(begin: _startScale, end: 1).animate(_incoming);
  }

  void _dispose() {
    _reduced.dispose();
    _incoming.dispose();
    _outgoing.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.motion.moves) {
      return FadeTransition(opacity: _reduced, child: widget.child);
    }
    return FadeTransition(
      opacity: ReverseAnimation(_outgoing),
      child: FadeTransition(
        opacity: _incoming,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
