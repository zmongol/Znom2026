import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal string key/value storage the kit uses for session tokens.
///
/// The default implementation is [SecureTokenStore] (platform secure
/// storage — iOS Keychain / Android Keystore). Hosts and tests may inject
/// [MemoryTokenStore] or their own implementation.
abstract interface class ZmongolTokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [ZmongolTokenStore] backed by flutter_secure_storage.
final class SecureTokenStore implements ZmongolTokenStore {
  final FlutterSecureStorage _storage;

  const SecureTokenStore(
      [this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory [ZmongolTokenStore] — useful for tests and previews.
final class MemoryTokenStore implements ZmongolTokenStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

/// Minimal string key/value storage for non-secret data (the config
/// cache and cross-promo state). The default implementation is
/// [SharedPreferencesStore]; tests may inject [MemoryKeyValueStore].
abstract interface class ZmongolKeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

/// [ZmongolKeyValueStore] backed by shared_preferences.
final class SharedPreferencesStore implements ZmongolKeyValueStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async =>
      (await _instance()).getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await (await _instance()).setString(key, value);
  }
}

/// In-memory [ZmongolKeyValueStore] — useful for tests and previews.
final class MemoryKeyValueStore implements ZmongolKeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
