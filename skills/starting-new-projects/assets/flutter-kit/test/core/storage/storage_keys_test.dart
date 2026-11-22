import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/storage/storage_keys.dart';

void main() {
  test('KIT-T9: the persisted keys are fixed', () {
    expect(StorageKeys.secure, ['token']);
    expect(StorageKeys.device, [
      'endOnboarding',
      'settings.themeMode',
      'settings.locale',
      'settings.textScale',
      'storage_schema',
      'permissions_asked',
      'permissions_granted',
    ]);
  });

  test('KIT-T9: every key is wiped on sign-out or kept, never both', () {
    expect(
      StorageKeys.userData.toSet().intersection(StorageKeys.device.toSet()),
      isEmpty,
    );
    expect(
      {...StorageKeys.userData, ...StorageKeys.device},
      {...StorageKeys.preferences},
    );
    expect(StorageKeys.preferences, isNot(contains(StorageKeys.token)));
  });

  test('KIT-T14: the cache prefix starts no other key', () {
    for (final key in [...StorageKeys.preferences, ...StorageKeys.secure]) {
      expect(key.startsWith(StorageKeys.cachePrefix), isFalse, reason: key);
    }
  });

  test('KIT-T17: what was asked survives a sign-out', () {
    expect(
      StorageKeys.device,
      containsAll([
        StorageKeys.permissionsAsked,
        StorageKeys.permissionsGranted,
      ]),
    );
    expect(StorageKeys.userData, isNot(contains(StorageKeys.permissionsAsked)));
  });
}
