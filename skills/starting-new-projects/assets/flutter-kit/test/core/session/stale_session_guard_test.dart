import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/session/session_bound.dart';
import 'package:kit_app/core/session/session_remote_source.dart';
import 'package:kit_app/core/session/session_repository.dart';
import 'package:kit_app/core/session/sign_out_service.dart';
import 'package:kit_app/core/session/stale_session_guard.dart';
import 'package:kit_app/core/storage/app_preferences.dart';
import 'package:kit_app/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemote extends Mock implements SessionRemoteSource {}

/// A Cubit that fetches and applies the answer, the way a feature's does.
class _FeatureCubit extends Cubit<String> with StaleSessionGuard {
  _FeatureCubit(this._generation) : super('empty');

  final int Function() _generation;

  @override
  int Function() get sessionGeneration => _generation;

  Future<void> load(Future<String> answer) async {
    final generation = sessionGeneration();
    final value = await answer;
    if (isStale(generation)) return;
    emit(value);
  }
}

void main() {
  late SessionRepository repository;
  late SignOutService signOut;
  late _FeatureCubit cubit;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final remote = _MockRemote();
    when(() => remote.logout(any())).thenAnswer((_) async {});
    final preferences = AppPreferences(await SharedPreferences.getInstance());
    repository = SessionRepository(
      const SecureStorage(FlutterSecureStorage()),
      preferences,
      remote,
    );
    signOut = SignOutService(
      session: repository,
      remote: remote,
      preferences: preferences,
      bound: SessionBoundRegistry(),
      hooks: () => const [],
    );
    cubit = _FeatureCubit(() => repository.generation);
    addTearDown(cubit.close);
    await repository.start(token: 'test-token', user: const {'id': 1});
  });

  test('KIT-T10: an answer in the same session is applied', () async {
    await cubit.load(Future.value('answer'));
    expect(cubit.state, 'answer');
  });

  test('KIT-T10: a late answer after sign-out is dropped', () async {
    final late = Completer<String>();
    final loading = cubit.load(late.future);
    await signOut.run(byUser: true);
    late.complete('the old user data');
    await loading;
    expect(cubit.state, 'empty');
  });

  test('KIT-T10: a late answer after an expiry is dropped', () async {
    final late = Completer<String>();
    final loading = cubit.load(late.future);
    await signOut.run(byUser: false);
    late.complete('the old user data');
    await loading;
    expect(cubit.state, 'empty');
  });

  test('KIT-T10: a late answer is not applied to the next user', () async {
    final late = Completer<String>();
    final loading = cubit.load(late.future);
    await signOut.run(byUser: true);
    await repository.start(token: 'next-token', user: const {'id': 2});
    late.complete('the old user data');
    await loading;
    expect(cubit.state, 'empty');
  });

  test('KIT-T10: isStale compares the generation it is given', () {
    final guard = _FeatureCubit(() => 5);
    addTearDown(guard.close);
    expect(guard.isStale(5), isFalse);
    expect(guard.isStale(4), isTrue);
  });
}
