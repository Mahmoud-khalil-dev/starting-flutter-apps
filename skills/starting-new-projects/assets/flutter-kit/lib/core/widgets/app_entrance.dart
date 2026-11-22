import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kit_app/core/theme/app_dimensions.dart';
import 'package:kit_app/core/theme/motion.dart';

/// List entrance: the item rises [AppDimensions.riseOffset]
/// and fades in, [Motion.stagger] after the one before, capped at
/// [Motion.maxStaggered]. Under reduce motion it fades, all at once.
/// Plays when its State is created, so a sliver item that scrolls out and is
/// rebuilt plays it again.
class AppEntrance extends StatefulWidget {
  const AppEntrance({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<AppEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  Timer? _delay;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = context.motion;
    _controller.duration = motion.move(Motion.standard);
    final wait = motion.stagger(widget.index);
    if (wait == Duration.zero) {
      _controller.forward();
    } else {
      _delay = Timer(wait, _controller.forward);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moves = context.motion.moves;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Motion.enter.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, moves ? (1 - t) * AppDimensions.riseOffset : 0),
            child: child,
          ),
        );
      },
    );
  }
}
