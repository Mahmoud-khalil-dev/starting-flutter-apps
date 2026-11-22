import 'package:go_router/go_router.dart';

/// Opens a notification's location. Only an in-app path opens; the route
/// guard holds it in `PendingDeepLink` while there is no session yet and
/// opens it once the session settles.
class NotificationRouter {
  NotificationRouter(this._router);

  final GoRouter _router;

  static String? safeLocation(String? raw) {
    if (raw == null || !raw.startsWith('/') || raw.startsWith('//')) {
      return null;
    }
    if (raw.contains(r'\')) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    return raw;
  }

  void open(String? raw) {
    final location = safeLocation(raw);
    if (location != null) _router.go(location);
  }
}
