import 'dart:typed_data';

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
  static const _photoKey = 'photo_url';
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
    for (final key in [_tokenKey, _roleKey, _nameKey, _emailKey, _photoKey]) {
      await _storage.delete(key: key);
    }
  }

  Future<bool> hasToken() async =>
      (await _storage.read(key: _tokenKey)) != null;

  Future<String?> getRole() => _storage.read(key: _roleKey);

  Future<String?> getName() => _storage.read(key: _nameKey);

  /// Alamat foto profil akun yang sedang login (null kalau tidak punya foto).
  /// Disimpan saat login, jadi akun yang login sebelum fitur ini ada perlu
  /// login ulang sekali.
  Future<String?> getPhotoUrl() async {
    final url = await _storage.read(key: _photoKey);
    return (url == null || url.isEmpty) ? null : url;
  }

  /// Profil akun yang sedang login (disimpan saat login).
  Future<({String name, String email, String role})> getProfile() async {
    return (
      name: await _storage.read(key: _nameKey) ?? '',
      email: await _storage.read(key: _emailKey) ?? '',
      role: await _storage.read(key: _roleKey) ?? '',
    );
  }

  /// Login, simpan token, role, nama, email, dan foto, lalu kembalikan role
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
    final photo = user['photo_url'];
    if (photo is String && photo.isNotEmpty) {
      await _storage.write(key: _photoKey, value: photo);
    } else {
      await _storage.delete(key: _photoKey);
    }
    return role;
  }

  /// Ganti atau hapus foto profil akun yang sedang login
  /// (POST /profile/photo). Alamat foto baru ikut disimpan di perangkat,
  /// supaya drawer dan header langsung memakainya. Mengembalikan alamat foto
  /// baru, atau null kalau fotonya dihapus.
  Future<String?> updateMyPhoto({Uint8List? bytes, bool remove = false}) async {
    final form = FormData.fromMap({
      if (remove) 'remove': '1',
      if (bytes != null)
        'photo': MultipartFile.fromBytes(bytes, filename: 'photo.jpg'),
    });
    final res = await dio.post('/profile/photo', data: form);
    final url = res.data['data']['photo_url'];
    if (url is String && url.isNotEmpty) {
      await _storage.write(key: _photoKey, value: url);
      return url;
    }
    await _storage.delete(key: _photoKey);
    return null;
  }

  Future<void> logout() async {
    try {
      await dio.post('/logout');
    } catch (_) {}
    await _clearSession();
  }
}
