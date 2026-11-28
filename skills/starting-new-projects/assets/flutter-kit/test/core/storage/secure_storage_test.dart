import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/storage/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('KIT-T9: secure storage reads, writes and deletes token', () async {
    FlutterSecureStorage.setMockInitialValues({'token': 'old'});
    const storage = SecureStorage(FlutterSecureStorage());
    expect(await storage.readToken(), 'old');
    await storage.writeToken('new');
    expect(await const FlutterSecureStorage().read(key: 'token'), 'new');
    await storage.deleteToken();
    expect(await storage.readToken(), isNull);
  });

  test('KIT-T9: without a keychain the token lives in memory only', () async {
    FlutterSecureStorage.setMockInitialValues({'token': 'on-disk'});
    final storage = MemoryTokenStorage();
    expect(await storage.readToken(), isNull);
    await storage.writeToken('new');
    expect(await storage.readToken(), 'new');
    expect(await const FlutterSecureStorage().read(key: 'token'), 'on-disk');
    await storage.deleteToken();
    expect(await storage.readToken(), isNull);
  });

  test('KIT-T9: the web gets the memory store, phones the keychain', () {
    const web = PlatformCapabilities(
      isWeb: true,
      platform: TargetPlatform.iOS,
    );
    const phone = PlatformCapabilities(
      isWeb: false,
      platform: TargetPlatform.android,
    );
    expect(tokenStorageFor(web), isA<MemoryTokenStorage>());
    expect(tokenStorageFor(phone), isNot(isA<MemoryTokenStorage>()));
  });

  test('KIT-T9: every FlutterSecureStorage in lib uses default options', () {
    final constructed = RegExp(r'FlutterSecureStorage\(([^)]*)\)');
    final withOptions = [
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart'))
          for (final m in constructed.allMatches(f.readAsStringSync()))
            if (m.group(1)!.trim().isNotEmpty) '${f.path}: ${m.group(0)}',
    ];
    expect(withOptions, isEmpty);
  });
}
