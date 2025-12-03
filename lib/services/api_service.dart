import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String url) async {
    final headers = await getHeaders();
    // Debug: in headers để kiểm tra token
    print('=== API GET ===');
    print('URL: $url');
    print('Headers: $headers');
    print('===============');
    return await http
        .get(Uri.parse(url), headers: headers)
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await getHeaders();
    return await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await getHeaders();
    return await http
        .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
  }

  static Future<http.Response> delete(String url) async {
    final headers = await getHeaders();
    return await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(ApiConfig.timeout);
  }

  // Multipart POST for form data (file upload)
  static Future<http.Response> postForm(
    String url,
    Map<String, String> fields,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    final streamedResponse = await request.send().timeout(ApiConfig.timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  // Multipart PUT for form data (file upload)
  static Future<http.Response> putForm(
    String url,
    Map<String, String> fields,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest('PUT', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    final streamedResponse = await request.send().timeout(ApiConfig.timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  // Upload file với multipart
  static Future<http.Response> uploadFile(
    String url,
    String filePath,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Thêm file
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    // Thêm các fields bổ sung nếu có
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    final streamedResponse = await request.send().timeout(ApiConfig.timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  // Upload file từ bytes (cho web hoặc camera)
  static Future<http.Response> uploadFileBytes(
    String url,
    List<int> bytes,
    String fileName,
    String fieldName, {
    Map<String, String>? additionalFields,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Thêm file từ bytes
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
    );

    // Thêm các fields bổ sung nếu có
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }

    final streamedResponse = await request.send().timeout(ApiConfig.timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  static Map<String, dynamic> parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
