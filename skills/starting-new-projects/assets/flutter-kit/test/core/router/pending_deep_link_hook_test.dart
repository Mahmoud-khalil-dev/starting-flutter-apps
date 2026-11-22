import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';
import 'package:kit_app/core/router/pending_deep_link_hook.dart';

void main() {
  for (final byUser in [false, true]) {
    test(
      'KIT-T10: a held link is gone after a sign-out (byUser: $byUser)',
      () async {
        final links = PendingDeepLink()..hold('/orders/7');
        await PendingDeepLinkHook(links).onSignOut(byUser: byUser);
        expect(links.held, isNull);
      },
    );
  }
}
