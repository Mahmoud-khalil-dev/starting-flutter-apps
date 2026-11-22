import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permission_cubit.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:mocktail/mocktail.dart';

class _Permissions extends Mock implements Permissions {}

void main() {
  late _Permissions permissions;
  late StreamController<void> resumed;

  setUp(() {
    permissions = _Permissions();
    resumed = StreamController<void>.broadcast();
  });
  tearDown(() => resumed.close());

  void checkSays(PermissionState state) => when(
    () => permissions.check(AppPermission.camera),
  ).thenAnswer((_) async => state);

  PermissionCubit cubit() {
    final c = PermissionCubit(
      permissions,
      AppPermission.camera,
      resumed: resumed.stream,
    );
    addTearDown(c.close);
    return c;
  }

  test('KIT-T17: request asks, then shows the answer', () async {
    checkSays(PermissionState.notAsked);
    when(
      () => permissions.request(AppPermission.camera),
    ).thenAnswer((_) async => PermissionState.granted);
    final c = cubit();
    await c.request();
    expect(c.state, PermissionState.granted);
  });

  test('KIT-T17: coming back from Settings checks again', () async {
    var state = PermissionState.permanentlyDenied;
    when(
      () => permissions.check(AppPermission.camera),
    ).thenAnswer((_) async => state);
    when(permissions.openSettings).thenAnswer((_) async => true);
    final c = cubit();
    await c.check();
    await c.openSettings();
    state = PermissionState.granted;
    resumed.add(null);
    await pumpEventQueue();
    expect(c.state, PermissionState.granted);
  });

  test('KIT-T17: a resume after close is ignored', () async {
    when(
      () => permissions.check(AppPermission.camera),
    ).thenAnswer((_) async => PermissionState.granted);
    final c = PermissionCubit(
      permissions,
      AppPermission.camera,
      resumed: resumed.stream,
    );
    await pumpEventQueue();
    clearInteractions(permissions);
    await c.close();
    resumed.add(null);
    await pumpEventQueue();
    verifyNever(() => permissions.check(AppPermission.camera));
  });

  test('KIT-T17: an answer that lands after close is dropped', () async {
    checkSays(PermissionState.notAsked);
    final answer = Completer<PermissionState>();
    when(
      () => permissions.request(AppPermission.camera),
    ).thenAnswer((_) => answer.future);
    final c = PermissionCubit(
      permissions,
      AppPermission.camera,
      resumed: resumed.stream,
    );
    await pumpEventQueue();
    final pending = c.request();
    await c.close();
    answer.complete(PermissionState.granted);
    await pending;
    expect(c.state, PermissionState.notAsked);
  });

  testWidgets('KIT-T17: appResumes emits on a return to the foreground', (
    tester,
  ) async {
    var resumes = 0;
    final subscription = appResumes().listen((_) => resumes++);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(resumes, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(resumes, 1);

    unawaited(subscription.cancel());
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(resumes, 1);
  });

  test('KIT-T17: it shows no state until the first check returns', () async {
    final first = Completer<PermissionState>();
    when(
      () => permissions.check(AppPermission.camera),
    ).thenAnswer((_) => first.future);
    final c = cubit();
    expect(c.state, isNull);
    first.complete(PermissionState.granted);
    await pumpEventQueue();
    expect(c.state, PermissionState.granted);
  });

  test('KIT-T17: a check that throws on resume keeps the last state', () async {
    checkSays(PermissionState.granted);
    final c = cubit();
    await pumpEventQueue();
    when(
      () => permissions.check(AppPermission.camera),
    ).thenAnswer((_) async => throw StateError('plugin'));
    final uncaught = <Object>[];
    await runZonedGuarded(() async {
      resumed.add(null);
      await pumpEventQueue();
    }, (error, _) => uncaught.add(error));
    expect(uncaught, isEmpty);
    expect(c.state, PermissionState.granted);
  });

  test('KIT-T17: a first check that throws falls back to not asked', () async {
    when(
      () => permissions.check(AppPermission.camera),
    ).thenAnswer((_) async => throw StateError('plugin'));
    final uncaught = <Object>[];
    late PermissionCubit c;
    await runZonedGuarded(() async {
      c = cubit();
      await pumpEventQueue();
    }, (error, _) => uncaught.add(error));
    expect(uncaught, isEmpty);
    expect(c.state, PermissionState.notAsked);
  });
}
