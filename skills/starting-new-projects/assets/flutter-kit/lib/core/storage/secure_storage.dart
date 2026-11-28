import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kit_app/core/platform/platform_capabilities.dart';
import 'package:kit_app/core/storage/storage_keys.dart';

/// The session token in the Keychain or Keystore, and the only writer of it.
/// Build it with `const FlutterSecureStorage()` and no options: other options
/// change where the token is stored and would log every installed user out.
class SecureStorage {
  const SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: StorageKeys.token);

  Future<void> writeToken(String token) =>
      _storage.write(key: StorageKeys.token, value: token);

  Future<void> deleteToken() => _storage.delete(key: StorageKeys.token);
}

/// The token in memory only, for a platform without a keychain. On the web
/// flutter_secure_storage writes to localStorage, which any script on the
/// page can read, so the token is never written there: a reload signs the
/// user out. To keep a web session across reloads, have the backend set an
/// httpOnly, Secure, SameSite cookie and send requests with credentials;
/// record that decision in docs/decisions.md.
class MemoryTokenStorage extends SecureStorage {
  MemoryTokenStorage() : super(const FlutterSecureStorage());

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;
}

/// The keychain store where the platform has one, memory otherwise.
SecureStorage tokenStorageFor(PlatformCapabilities capabilities) =>
    capabilities.keychainStorage
    ? const SecureStorage(FlutterSecureStorage())
    : MemoryTokenStorage();
