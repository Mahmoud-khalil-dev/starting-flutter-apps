import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/router/route_guard.dart';
import 'package:kit_app/app/shell/shell_destinations.dart';
import 'package:kit_app/core/router/route_names.dart';
import 'package:kit_app/core/session/app_role.dart';

List<ShellTab> _tabs(AppRole? role) =>
    destinationsFor(role).map((d) => d.tab).toList();

void main() {
  test('KIT-T10: every role and a visitor see Home and Settings', () {
    for (final role in [...AppRole.values, null]) {
      expect(_tabs(role), [ShellTab.home, ShellTab.settings], reason: '$role');
    }
  });

  test('KIT-T10: every destination is a path the guard allows the role', () {
    for (final role in AppRole.values) {
      for (final d in destinationsFor(role)) {
        expect(RouteGuard.allows(role, d.path), isTrue, reason: '$role $d');
      }
    }
  });

  test('KIT-T10: the destinations are exactly the router tabs', () {
    expect(
      destinationsFor(AppRole.member).map((d) => d.path).toSet(),
      RouteNames.tabs,
    );
  });
}
