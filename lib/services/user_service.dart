import 'dart:convert';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class UserService {
  // Helper methods để check response với cả PascalCase và camelCase
  bool _isSuccess(Map<String, dynamic> data) {
    return data['IsSuccess'] == true ||
        data['isSuccess'] == true ||
        data['success'] == true;
  }

  dynamic _getData(Map<String, dynamic> data) {
    return data['Data'] ?? data['data'];
  }

  // Lấy danh sách người dùng
  Future<List<User>> getUsers() async {
    try {
      final response = await ApiService.get(ApiConfig.users);

      // Debug: in ra response để kiểm tra
      print('=== USERS RESPONSE ===');
      print('Status: ${response.statusCode}');
      print(
        'Body (first 500): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
      );
      print('=======================');

      // Kiểm tra nếu response là HTML (redirect đến login)
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw Exception(
          'Received HTML instead of JSON. Token may be invalid or expired.',
        );
      }

      final data = jsonDecode(response.body);

      if (_isSuccess(data) && _getData(data) != null) {
        return (_getData(data) as List)
            .map((json) => User.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Lấy thông tin người dùng theo ID
  Future<User> getUserById(String id) async {
    try {
      final response = await ApiService.get(ApiConfig.userById(id));
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return User.fromJson(_getData(data));
      }
      throw Exception('User not found');
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Xóa người dùng
  Future<void> deleteUser(String id) async {
    try {
      final response = await ApiService.delete(ApiConfig.userById(id));
      final data = ApiService.parseResponse(response);

      if (!_isSuccess(data)) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
