import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/lifecycle_wiring.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/network/connectivity_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecovery extends Mock implements SessionRecovery {}

class _MockConnectivity extends Mock implements ConnectivityService {}

void main() {
  late _MockRecovery recovery;
  late _MockConnectivity connectivity;

  setUp(() {
    recovery = _MockRecovery();
    connectivity = _MockConnectivity();
    when(recovery.onResume).thenAnswer((_) async {});
  });

  testWidgets(
    'KIT-T10: the wiring reads the token once at once, then on each return to the foreground',
    (tester) async {
      final binding = tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final listener = wireSessionLifecycle(
        connectivity: connectivity,
        recovery: recovery,
        binding: binding,
      );
      addTearDown(listener.dispose);
      // Already resumed: no transition will fire, so one early call.
      verify(recovery.onResume).called(1);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      verifyNever(recovery.onResume);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      verify(recovery.onResume).called(1);
    },
  );

  testWidgets(
    'KIT-T10: the wiring pauses connectivity in the background and resumes it',
    (tester) async {
      final binding = tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final listener = wireSessionLifecycle(
        connectivity: connectivity,
        recovery: recovery,
        binding: binding,
      );
      addTearDown(listener.dispose);
      [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ].forEach(binding.handleAppLifecycleStateChanged);
      verify(connectivity.pause).called(1);
      [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(binding.handleAppLifecycleStateChanged);
      verify(connectivity.resume).called(1);
    },
  );
}
