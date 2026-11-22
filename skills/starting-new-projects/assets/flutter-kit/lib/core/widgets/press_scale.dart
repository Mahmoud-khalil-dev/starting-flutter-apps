import 'package:flutter/widgets.dart';
import 'package:kit_app/core/theme/motion.dart';

/// Press feedback for anything tappable: scales to 0.97 and
/// back; under reduce motion it dims instead. It only listens; the child's
/// own InkWell or GestureDetector handles the tap.
class PressScale extends StatefulWidget {
  const PressScale({required this.builder, this.enabled = true, super.key});

  final Widget Function(BuildContext context, {required bool pressed}) builder;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  void didUpdateWidget(PressScale old) {
    super.didUpdateWidget(old);
    if (!widget.enabled) _pressed = false;
  }

  void _down() {
    if (widget.enabled && !_pressed) setState(() => _pressed = true);
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed && widget.enabled;
    final child = widget.builder(context, pressed: pressed);
    final duration = context.motion.fade(Motion.instant);
    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: context.motion.moves
          ? AnimatedScale(
              scale: pressed ? Motion.pressScale : 1,
              duration: duration,
              curve: Motion.enter,
              child: child,
            )
          : AnimatedOpacity(
              opacity: pressed ? Motion.pressDim : 1,
              duration: duration,
              curve: Motion.enter,
              child: child,
            ),
    );
  }
}
