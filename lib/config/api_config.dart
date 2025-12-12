import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // ========== CẤU HÌNH CHO ĐIỆN THOẠI THẬT ==========
  // Đặt true nếu đang test trên điện thoại thật (kết nối cùng mạng WiFi)
  // Đặt false nếu đang test trên Emulator
  static const bool useRealDevice =
      true; // Đổi thành true khi test trên điện thoại thật

  // IP của máy tính chạy backend (lấy từ ipconfig)
  // Điện thoại và máy tính phải cùng mạng WiFi
  static String hostIP = '192.168.1.5';

  static const String _prefKeyHostIP = 'api_host_ip';

  /// Khởi tạo config từ SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIP = prefs.getString(_prefKeyHostIP);
      if (savedIP != null && savedIP.isNotEmpty) {
        hostIP = savedIP;
      }
    } catch (e) {
      debugPrint('Error loading API config: $e');
    }
  }

  /// Cập nhật IP mới và lưu vào SharedPreferences
  static Future<void> updateHostIP(String newIP) async {
    if (newIP.isEmpty) return;
    hostIP = newIP;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyHostIP, newIP);
  }
  // =================================================

  // Tự động phát hiện platform và sử dụng URL phù hợp
  static String get baseUrl {
    // Port của API .NET
    const String port = '5050';

    if (kIsWeb) {
      // Web browser - sử dụng localhost
      return 'http://localhost:$port/api';
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (useRealDevice) {
          // Điện thoại thật (Android/iOS) - sử dụng IP của máy tính
          return 'http://$hostIP:$port/api';
        }
        if (Platform.isAndroid) {
          // Android Emulator
          return 'http://10.0.2.2:$port/api';
        }
        // iOS Simulator
        return 'http://localhost:$port/api';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop - sử dụng localhost
        return 'http://localhost:$port/api';
      }
    } catch (e) {
      // Fallback nếu không thể xác định platform
    }

    return 'http://localhost:$port/api';
  }

  // SignalR Hub Endpoint
  static String get hubUrl => baseUrl.replaceAll('/api', '/orderHub');

  // Auth endpoints
  static String get login => '$baseUrl/Auth/login';
  static String get register => '$baseUrl/Auth/register';

  // Products endpoints
  static String get products => '$baseUrl/Products';
  static String productById(int id) => '$baseUrl/Products/$id';
  static String get productsPaged => '$baseUrl/Products/paged';
  static String get productsSearch => '$baseUrl/Products/search';
  static String productUploadImage(int id) =>
      '$baseUrl/Products/$id/upload-image';
  static String get productUploadTempImage =>
      '$baseUrl/Products/upload-temp-image';

  // Orders endpoints
  static String get orders => '$baseUrl/Orders';
  static String orderById(int id) => '$baseUrl/Orders/$id';
  static String orderStatus(int id) => '$baseUrl/Orders/$id/status';
  static String get posOrder => '$baseUrl/Orders/pos';

  // Users endpoints
  static String get users => '$baseUrl/Users';
  static String userById(String id) => '$baseUrl/Users/$id';

  // Coupons endpoints
  static String get coupons => '$baseUrl/CouponApi';
  static String couponById(int id) => '$baseUrl/CouponApi/$id';

  // Categories endpoints
  static String get categories => '$baseUrl/Categories';

  // Statistics endpoints
  static String get dashboard => '$baseUrl/StatisticsApi/dashboard';

  // Inventory endpoints
  static String get inventory => '$baseUrl/Inventory';
  static String inventoryByLinear(String linearCode) =>
      '$baseUrl/Inventory/by-linear/$linearCode';
  static String inventoryUpdateQuantity(int productId) =>
      '$baseUrl/Inventory/$productId/update-quantity';
  static String get inventoryGenerateLinearCodes =>
      '$baseUrl/Inventory/generate-linear-codes';
  static String get inventoryExportLinearCodes =>
      '$baseUrl/Inventory/export-linear-codes';

  // Payment endpoints
  static String get payment => '$baseUrl/PaymentApi';
  static String paymentVnPayCreate(int orderId) =>
      '$baseUrl/PaymentApi/vnpay/create/$orderId';
  static String paymentStatus(int orderId) =>
      '$baseUrl/PaymentApi/status/$orderId';
  static String paymentCash(int orderId) => '$baseUrl/PaymentApi/cash/$orderId';

  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
