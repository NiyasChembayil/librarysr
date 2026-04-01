import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? errorMessage;
  final ProfileModel? profile;

  AuthState({required this.status, this.token, this.errorMessage, this.profile});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState(status: AuthStatus.initial)) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    try {
      debugPrint('Auth: Checking token...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        debugPrint('Auth: Token found, fetching profile...');
        _apiClient.setAuthToken(token);
        final profile = await _fetchProfile();
        state = AuthState(status: AuthStatus.authenticated, token: token, profile: profile);
        debugPrint('Auth: Authenticated.');
      } else {
        debugPrint('Auth: No token found.');
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('Auth: Initialization error: $e');
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<ProfileModel?> _fetchProfile() async {
    try {
      final response = await _apiClient.dio.get('accounts/profile/me/');
      // The serializer now returns username, role, bio, avatar, followers_count
      return ProfileModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<void> login(String username, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final response = await _apiClient.dio.post('token/', data: {
        'username': username,
        'password': password,
      });
      final token = response.data['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      _apiClient.setAuthToken(token);
      
      final profile = await _fetchProfile();
      state = AuthState(status: AuthStatus.authenticated, token: token, profile: profile);
    } catch (e) {
      // Parse friendly error from DioException if available
      String message = 'Login failed. Please check your credentials.';
      state = AuthState(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<bool> register(String username, String email, String password, String role) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _apiClient.dio.post('accounts/auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });
      state = AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      // Try to extract the server's validation error message
      String message = 'Registration failed. Please try again.';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map) {
          final firstKey = data.keys.first;
          final firstVal = data[firstKey];
          message = firstVal is List ? firstVal.first.toString() : firstVal.toString();
        }
      } catch (_) {}
      state = AuthState(status: AuthStatus.error, errorMessage: message);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _apiClient.clearAuthToken();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
