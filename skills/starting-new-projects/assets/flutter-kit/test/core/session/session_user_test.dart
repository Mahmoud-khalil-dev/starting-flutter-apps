import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/session/app_role.dart';
import 'package:kit_app/core/session/session_user.dart';

const _user = <String, dynamic>{
  'id': 1,
  'name': 'Test Member',
  'email': 'member@example.test',
  'role': 'MEMBER',
  'status': 'ACTIVE',
};

void main() {
  group('KIT-T10: SessionUser', () {
    test('KIT-T10: reads data.user from an auth body', () {
      final raw = SessionUser.userIn({
        'data': {'token': 'test-token', 'user': _user},
      });
      final user = SessionUser.fromJson(raw)!;
      expect(user.id, 1);
      expect(user.role, AppRole.member);
      expect(user.status, UserStatus.active);
      expect(user.name, 'Test Member');
      expect(user.email, 'member@example.test');
      expect(user.raw, _user);
    });

    test('reads a bare user under data when it has an id', () {
      expect(SessionUser.userIn({'data': _user}), _user);
      expect(
        SessionUser.userIn({
          'data': {'token': 'test-token'},
        }),
        isNull,
      );
      expect(SessionUser.userIn('not json'), isNull);
    });

    test('an unknown role or status is null, so the guard denies it', () {
      final user = SessionUser.fromJson({
        ..._user,
        'role': 'OWNER',
        'status': 1,
      })!;
      expect(user.role, isNull);
      expect(user.status, isNull);
    });

    test('reads its fields tolerantly', () {
      final odd = SessionUser.fromJson({
        ..._user,
        'id': '7',
        'name': 7,
        'phone': ' ',
      })!;
      expect(odd.id, 7);
      expect(odd.name, '7');
      expect(odd.phone, isNull);
    });
  });
}
