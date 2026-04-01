import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider((ref) => ApiClient());

// ⚠️ BEFORE RELEASING TO PLAY STORE:
// Replace the baseUrl below with your actual deployed backend URL.
// Example: 'https://api.srishty.com/api/'
// Using localhost (127.0.0.1) will NOT work on real devices!
const String _baseUrl = kDebugMode
    ? 'http://192.168.1.3:8000/api/' // Computer Local IP → physical device over Wi-Fi
    : 'https://your-production-api.com/api/'; // ← REPLACE THIS before release!

class ApiClient {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    // Only log requests in debug mode — never in production builds
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
    }
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}
