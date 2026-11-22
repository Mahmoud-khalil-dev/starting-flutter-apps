import 'dart:async';

/// Runs the last action of a burst, [wait] after it. For a text field's
/// onChanged; a Bloc event uses `debounce` from `core/state` instead.
/// Dispose it with the widget that owns it.
class Debouncer {
  Debouncer(this.wait);

  final Duration wait;
  Timer? _timer;
  bool _disposed = false;

  bool get pending => _timer?.isActive ?? false;

  void call(void Function() action) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(wait, action);
  }

  void cancel() => _timer?.cancel();

  /// Drops the pending call; later calls do nothing.
  void dispose() {
    _disposed = true;
    cancel();
  }
}
