import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
