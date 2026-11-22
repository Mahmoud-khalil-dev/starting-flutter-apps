/// One target held across start-up, sign-in and blocking steps, then
/// consumed once (a notification tap or a link opened while signed out).
class PendingDeepLink {
  String? _held;

  String? get held => _held;

  void hold(String location) {
    assert(location.isNotEmpty, 'A held link is a location, never empty.');
    _held = location;
  }

  String? consume() {
    final location = _held;
    _held = null;
    return location;
  }

  void clear() => _held = null;
}
