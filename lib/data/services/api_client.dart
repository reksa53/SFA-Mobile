import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'token';
  static const _roleKey = 'role';
  static const _nameKey = 'name';
  static const _emailKey = 'email';
  final _storage = const FlutterSecureStorage();

  late final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await _storage.read(key: _tokenKey);
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (e, handler) async {
              // Token kedaluwarsa/tidak valid (selain saat login itu sendiri)
              if (e.response?.statusCode == 401 &&
                  e.requestOptions.path != '/login') {
                await _clearSession();
              }
              handler.next(e);
            },
          ),
            )
    ..interceptors.add(
      LogInterceptor(
        requestHeader: true,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint('[API] $o'),
      ),
    );

  Future<void> _clearSession() async {
    for (final key in [_tokenKey, _roleKey, _nameKey, _emailKey]) {
      await _storage.delete(key: key);
    }
  }

  Future<bool> hasToken() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<String?> getRole() => _storage.read(key: _roleKey);

  Future<String?> getName() => _storage.read(key: _nameKey);

  /// Profil akun yang sedang login (disimpan saat login).
  Future<({String name, String email, String role})> getProfile() async {
    return (
      name: await _storage.read(key: _nameKey) ?? '',
      email: await _storage.read(key: _emailKey) ?? '',
      role: await _storage.read(key: _roleKey) ?? '',
    );
  }

  /// Login, simpan token, role, nama, dan email, lalu kembalikan role
  /// ('manager' / 'sales').
  Future<String> login(String email, String password) async {
    final res = await dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    final token = res.data['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('Token tidak ditemukan di response');
    }
    final user = res.data['data'];
    final role = user?['role'];
    if (role is! String || role.isEmpty) {
      throw Exception('Role tidak ditemukan di response');
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _nameKey, value: '${user['name'] ?? ''}');
    await _storage.write(key: _emailKey, value: '${user['email'] ?? ''}');
    return role;
  }

  Future<void> logout() async {
    try {
      await dio.post('/logout');
    } catch (_) {}
    await _clearSession();
  }
}
