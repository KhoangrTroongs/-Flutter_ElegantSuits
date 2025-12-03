import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConfig.login, {
        'email': email,
        'password': password,
      });

      final data = ApiService.parseResponse(response);

      // Backend trả về PascalCase: { IsSuccess, Message, Data: { Token, UserId, UserName, Roles } }
      final bool isSuccess =
          data['IsSuccess'] == true || data['isSuccess'] == true;
      final dynamic loginData = data['Data'] ?? data['data'];

      if (isSuccess && loginData != null) {
        final String? token = loginData['Token'] ?? loginData['token'];
        if (token != null && token.isNotEmpty) {
          final loginResponse = LoginResponse.fromJson(loginData);
          await ApiService.saveToken(loginResponse.token);
          return loginResponse;
        }
      }
      throw Exception(data['Message'] ?? data['message'] ?? 'Login failed');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<void> logout() async {
    await ApiService.removeToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null;
  }
}
