import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kit_app/core/permissions/app_permission.dart';
import 'package:kit_app/core/permissions/permissions.dart';
import 'package:kit_app/core/state/safe_cubit.dart';

/// Emits each time the app comes back to the foreground (from Settings, for
/// one). Cancelling the subscription disposes the listener.
Stream<void> appResumes() {
  AppLifecycleListener? listener;
  late final StreamController<void> controller;
  controller = StreamController<void>(
    onListen: () =>
        listener = AppLifecycleListener(onResume: () => controller.add(null)),
    onCancel: () => listener?.dispose(),
  );
  return controller.stream;
}

/// One permission on one screen. The state is null until the first check
/// returns, so a screen shows no button yet instead of a wrong one. It
/// checks again whenever the app resumes, so a change made in Settings shows
/// at once. A check that throws keeps the last state (not asked, at first).
class PermissionCubit extends SafeCubit<PermissionState?> {
  PermissionCubit(
    this._permissions,
    this.permission, {
    required Stream<void> resumed,
  }) : super(null) {
    _resumed = resumed.listen((_) => unawaited(check()));
    unawaited(check());
  }

  final Permissions _permissions;
  final AppPermission permission;
  late final StreamSubscription<void> _resumed;

  Future<void> check() async {
    try {
      emit(await _permissions.check(permission));
    } on Object {
      // Keep what is shown; never an unhandled error from a resume.
      emit(state ?? PermissionState.notAsked);
    }
  }

  Future<void> request() async => emit(await _permissions.request(permission));

  Future<void> openSettings() => _permissions.openSettings();

  @override
  Future<void> close() async {
    await _resumed.cancel();
    return super.close();
  }
}
