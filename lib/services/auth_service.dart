import 'package:dio/dio.dart';
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
      String token = response.data['token'];
      String twilioAccessToken = response.data['twilio_access_token'];
      await _storage.saveToken(token);
      await _storage.saveTwilioAccessToken(twilioAccessToken);
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
