import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  // Bisa di-override saat run: --dart-define=API_BASE_URL=http://192.168.1.5:8000/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api'; // Android emulator
    }
    return 'http://localhost:8000/api'; // iOS simulator
  }
}