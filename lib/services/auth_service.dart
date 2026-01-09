import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Ensure we get the idToken for backend validation
    serverClientId:
        '338699126878-2lpqaf50h0rfuvamgl762f46s6gjetip.apps.googleusercontent.com',
    scopes: ['email', 'profile', 'openid'],
  );

  Future<LoginResponse> login(String email, String password) async {
    // ... existing login code ...
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

  Future<LoginResponse> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign In Cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Note: Backend must support this endpoint and handle the idToken
      final response = await ApiService.post(ApiConfig.loginWithGoogle, {
        'idToken': googleAuth.idToken,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'provider': 'GOOGLE',
      });

      if (response.statusCode == 404) {
        throw Exception(
          'Backend Endpoint Not Found (${ApiConfig.loginWithGoogle}). Please check server.',
        );
      }

      final data = ApiService.parseResponse(response);
      // Reuse parsing logic if backend returns standard structure
      // If backend not ready, we might simulate login for demo purposes (BUT better to properly call API)

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
      throw Exception(
        data['Message'] ?? data['message'] ?? 'Google Login failed',
      );
    } catch (e) {
      if (e.toString().contains('Google Sign In Cancelled')) {
        rethrow;
      }
      throw Exception('Google Sign In error: $e');
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(ApiConfig.register, data);
      final responseData = ApiService.parseResponse(response);

      // Check success based on backend response structure
      final bool isSuccess =
          responseData['IsSuccess'] == true ||
          responseData['isSuccess'] == true;

      if (isSuccess) {
        return true;
      }

      throw Exception(
        responseData['Message'] ??
            responseData['message'] ??
            'Registration failed',
      );
    } catch (e) {
      throw Exception('Registration error: $e');
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
