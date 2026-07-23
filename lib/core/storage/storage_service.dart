import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _tokenKey = 'auth_token';
  static const _userKey = 'cached_user';
  static const _langKey = 'language_code';

  Future<void> saveLanguage(String langCode) async {
    await _storage.write(key: _langKey, value: langCode);
  }

  Future<String?> getLanguage() async {
    return await _storage.read(key: _langKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUser(Map<String, dynamic> userMap) async {
    final userJson = jsonEncode(userMap);
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
