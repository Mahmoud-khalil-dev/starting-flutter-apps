import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/router/pending_deep_link.dart';

void main() {
  test('KIT-T10: the pending link holds, replaces and is consumed once', () {
    final link = PendingDeepLink()..hold('/a');
    expect(link.held, '/a');
    link.hold('/b');
    expect(link.consume(), '/b');
    expect(link.consume(), isNull);
    link
      ..hold('/c')
      ..clear();
    expect(link.held, isNull);
  });
}
