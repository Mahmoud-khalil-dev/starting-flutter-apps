import 'dart:async';
import 'dart:collection';

enum ConnectionStatus { online, offline, unstable }

/// How a request ended, for [ConnectivityService.recordRequest].
enum RequestOutcome { ok, timedOut, failed }

/// Whether the backend can be reached.
///
/// The probe alone decides: a connectivity event (from connectivity_plus)
/// only triggers a recheck, debounced, because a link can exist without the
/// API being reachable, and the simulator can report "none" while online.
/// While offline in the foreground it re-probes every [offlineRecheck].
/// Unstable means two of the last five requests timed out. Nothing runs
/// while paused (app in the background).
class ConnectivityService {
  ConnectivityService({
    required this._changes,
    required this._probe,
    this.debounce = const Duration(seconds: 2),
    this.offlineRecheck = const Duration(seconds: 15),
  });

  final Duration debounce;
  final Duration offlineRecheck;
  final Stream<Object?> _changes;
  final Future<bool> Function() _probe;
  final StreamController<ConnectionStatus> _controller =
      StreamController<ConnectionStatus>.broadcast();
  final ListQueue<bool> _recent = ListQueue<bool>();
  StreamSubscription<Object?>? _subscription;
  Timer? _debounceTimer;
  Timer? _offlineTimer;
  var _paused = false;
  var _disposed = false;
  ConnectionStatus _status = ConnectionStatus.online;

  ConnectionStatus get status => _status;

  bool get isOnline => _status != ConnectionStatus.offline;

  Stream<ConnectionStatus> get statusChanges => _controller.stream;

  Future<void> start() async {
    _subscription ??= _changes.listen((_) => _schedule());
    await _check();
  }

  /// `ok`: a response came back, whatever its status. `timedOut`: the
  /// request ran out of time. `failed`: no response and no timeout (no
  /// route, a bad certificate); it proves nothing about the API, so only the
  /// probe may turn the status offline or back.
  void recordRequest({required RequestOutcome outcome}) {
    // A request can finish after dispose; the controller is closed by then.
    if (_disposed || outcome == RequestOutcome.failed) return;
    final timedOut = outcome == RequestOutcome.timedOut;
    _recent.addLast(timedOut);
    while (_recent.length > 5) {
      _recent.removeFirst();
    }
    // A response that came back proves the network is there, so a successful
    // one also clears the offline overlay; a timeout never turns it online.
    if (_status != ConnectionStatus.offline || !timedOut) {
      _set(_reachableStatus);
    }
  }

  void pause() {
    _paused = true;
    _debounceTimer?.cancel();
    _offlineTimer?.cancel();
  }

  void resume() {
    if (_disposed) return;
    _paused = false;
    _schedule();
  }

  Future<void> dispose() async {
    _disposed = true;
    _debounceTimer?.cancel();
    _offlineTimer?.cancel();
    await _subscription?.cancel();
    await _controller.close();
  }

  ConnectionStatus get _reachableStatus =>
      _recent.where((timedOut) => timedOut).length >= 2
      ? ConnectionStatus.unstable
      : ConnectionStatus.online;

  void _schedule() {
    if (_paused || _disposed) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(_check()));
  }

  Future<void> _check() async {
    final reachable = await _probe();
    if (_disposed) return;
    _set(reachable ? _reachableStatus : ConnectionStatus.offline);
    _offlineTimer?.cancel();
    if (!reachable && !_paused) {
      _offlineTimer = Timer(offlineRecheck, () => unawaited(_check()));
    }
  }

  void _set(ConnectionStatus next) {
    if (next == _status) return;
    _status = next;
    _controller.add(next);
  }
}
