import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/app/session_recovery.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_cubit.dart';
import 'package:kit_app/core/session/session_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionCubit {}

void main() {
  late _MockSession session;
  late List<String> steps;
  late SessionRecovery recovery;

  const signedIn = SessionState.authenticated(
    role: AppRole.member,
    userStatus: UserStatus.active,
    savedOnly: true,
  );

  setUp(() {
    session = _MockSession();
    steps = [];
    when(() => session.state).thenReturn(signedIn);
    when(session.retryRestore).thenAnswer((_) async {
      steps.add('retry');
      return true;
    });
    when(session.refresh).thenAnswer((_) async {
      steps.add('refresh');
      return null;
    });
    recovery = SessionRecovery(session: session);
  });

  test(
    'KIT-T10: a token that reads after unlock refreshes the profile',
    () async {
      await recovery.onResume();
      expect(steps, ['retry', 'refresh']);
    },
  );

  test('KIT-T10: a resume with nothing to retry does nothing', () async {
    when(session.retryRestore).thenAnswer((_) async => false);
    await recovery.onResume();
    verifyNever(session.refresh);
    expect(steps, isEmpty);
  });

  test('KIT-T10: a read that finds no token starts nothing', () async {
    when(() => session.state).thenReturn(const SessionState.unauthenticated());
    await recovery.onResume();
    expect(steps, ['retry']);
  });

  test('KIT-T10: a refresh that throws is logged and never escapes', () async {
    when(session.refresh).thenAnswer((_) async => throw StateError('failed'));
    await recovery.onResume();
    verify(session.refresh).called(1);
  });

  test(
    'KIT-T10: Try again refreshes even when the session already signed in',
    () async {
      when(session.retryRestore).thenAnswer((_) async {
        steps.add('retry');
        return false;
      });
      await recovery.tryAgain();
      expect(steps, ['retry', 'refresh']);
    },
  );

  test('KIT-T10: Try again that reads no token starts nothing', () async {
    when(() => session.state).thenReturn(const SessionState.unauthenticated());
    await recovery.tryAgain();
    expect(steps, ['retry']);
  });
}
