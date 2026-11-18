import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/api_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'token';
  static const _roleKey = 'role';
  static const _nameKey = 'name';
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
                await _storage.delete(key: _tokenKey);
                await _storage.delete(key: _roleKey);
                await _storage.delete(key: _nameKey);
              }
              handler.next(e);
            },
          ),
        );

  Future<bool> hasToken() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<String?> getRole() => _storage.read(key: _roleKey);
  Future<String?> getName() => _storage.read(key: _nameKey);

  /// Login, simpan token dan role, lalu kembalikan role ('manager' / 'sales').
  Future<String> login(String email, String password) async {
    final res = await dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    final token = res.data['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('Token tidak ditemukan di response');
    }
    final role = res.data['data']?['role'];
    if (role is! String || role.isEmpty) {
      throw Exception('Role tidak ditemukan di response');
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
        final nama = res.data['data']?['name'];
    if (nama is String && nama.isNotEmpty) {
      await _storage.write(key: _nameKey, value: nama);
    }
    return role;
  }

  Future<void> logout() async {
    try {
      await dio.post('/logout');
    } catch (_) {}
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _nameKey);
  }
}
