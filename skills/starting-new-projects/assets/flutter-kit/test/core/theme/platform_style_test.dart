import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/theme/platform_style.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('KIT-T8: the Apple look and the backdrop blur follow the theme', (
    tester,
  ) async {
    late bool cupertino;
    late bool blurs;
    final probe = Builder(
      builder: (context) {
        cupertino = context.isCupertino;
        blurs = context.blursBackdrop;
        return const SizedBox();
      },
    );
    await pumpApp(tester, probe, platform: TargetPlatform.iOS, web: false);
    expect((cupertino, blurs), (true, true));
    await pumpApp(tester, probe, platform: TargetPlatform.android, web: false);
    expect((cupertino, blurs), (false, true));
    await pumpApp(tester, probe, platform: TargetPlatform.iOS, web: true);
    expect((cupertino, blurs), (false, false), reason: 'the web is Material');
    await pumpApp(tester, probe, platform: TargetPlatform.macOS, web: false);
    expect((cupertino, blurs), (true, true));
  });
}
