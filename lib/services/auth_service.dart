import 'package:dio/dio.dart';
import 'package:gbpn_dealer/models/auth_response.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<String?> login(String email, String password) async {
    Response response = await _api.post('/mobile-app/login', {
      "email": email,
      "password": password,
    });

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(response.data);
      await _storage.saveToken(authResponse.token);
      await _storage.saveAuthResponse(authResponse);
      await _storage.saveTwilioAccessToken(authResponse.twilioAccessToken);
      return null;
    }

    return response.data['message'];
  }

  Future<void> logout() async {
    await _storage.clearToken();
    await _storage.clearTwilioAccessToken();
  }

  Future<bool> isLoggedIn() async {
    String? token = await _storage.getToken();
    return token != null;
  }
}
