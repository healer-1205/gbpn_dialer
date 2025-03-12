import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "https://app.gbpn.com/api"));

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await StorageService().getToken();
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      return await _dio.post(endpoint, data: data);
    } on DioException catch (e) {
      return e.response!;
    }
  }

  Future<Response> get(String endpoint) async {
    try {
      return await _dio.get(endpoint);
    } on DioException catch (e) {
      return e.response!;
    }
  }
}
