// import 'dart:io'; (Avoid for Web)
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider((ref) => ApiClient());

// ⚠️ BEFORE RELEASING TO PLAY STORE:
// Replace the baseUrl below with your actual deployed backend URL.
// Example: 'https://api.srishty.com/api/'
// Using localhost (127.0.0.1) will NOT work on real devices!
// Using localhost (127.0.0.1) will NOT work on real physical devices or Android emulators!
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api/',
);

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

    // Add interceptor to handle 401 Unauthorized (Expired Tokens)
    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // If token is expired, clear it so we can at least browse as a guest
          clearAuthToken();
          debugPrint("Auth token expired/invalid. Cleared for guest access.");
        }
        return handler.next(e);
      },
    ));
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
  Future<void> uploadChapterAudio(int bookId, int chapterNumber, String filePath) async {
    final formData = FormData.fromMap({
      'audio_file': await MultipartFile.fromFile(
        filePath,
        filename: 'chapter_${chapterNumber}_audio.m4a',
      ),
      'chapter_number': chapterNumber,
    });
    await dio.post(
      'core/books/$bookId/upload_audio/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  Future<Map<String, dynamic>> convertDocx({String? filePath, Uint8List? bytes, String? filename}) async {
    MultipartFile file;
    if (kIsWeb) {
      if (bytes == null) throw Exception('Bytes required for web upload');
      file = MultipartFile.fromBytes(bytes, filename: filename ?? 'document.docx');
    } else {
      if (filePath == null) throw Exception('FilePath required for mobile upload');
      file = await MultipartFile.fromFile(
        filePath,
        filename: filename ?? filePath.split('/').last,
      );
    }

    final formData = FormData.fromMap({'file': file});
    final response = await dio.post(
      'core/books/convert_docx/',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        validateStatus: (status) => true,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(response.data['error'] ?? 'Conversion failed');
    }
    return response.data;
  }

  Future<Map<String, dynamic>> importChapters(int bookId, List<Map<String, String>> chapters) async {
    final response = await dio.post(
      'core/books/$bookId/import_chapters/',
      data: {'chapters': chapters},
    );
    return response.data;
  }
}
