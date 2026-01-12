import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Cấu hình thiết bị thật (True: Real Device, False: Emulator)
  static const bool useRealDevice =
      true; // Đổi thành true khi test trên điện thoại thật

  // Địa chỉ IP máy chủ backend
  static String hostIP = '192.168.1.10';

  static const String _prefKeyHostIP = 'api_host_ip';

  /// Khởi tạo cấu hình từ Local Storage
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

  /// Cập nhật và lưu IP mới
  static Future<void> updateHostIP(String newIP) async {
    if (newIP.isEmpty) return;
    hostIP = newIP;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyHostIP, newIP);
  }
  // =================================================

  // Lấy Base URL dựa trên platform
  static String get baseUrl {
    // Port API .NET
    const String port = '5050';

    if (kIsWeb) {
      // Web browser
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
        // Desktop App
        return 'http://localhost:$port/api';
      }
    } catch (e) {
      // Fallback mặc định
    }

    return 'http://localhost:$port/api';
  }

  // URL gốc cho hình ảnh
  static String get imageBaseUrl {
    final apiBase = baseUrl;
    return apiBase.replaceAll('/api', '');
  }

  // Endpoint SignalR Hub
  static String get hubUrl => baseUrl.replaceAll('/api', '/orderHub');

  // Endpoints xác thực
  static String get login => '$baseUrl/Auth/login';
  static String get loginWithGoogle => '$baseUrl/Auth/google-login';
  static String get register => '$baseUrl/Auth/register';

  // Endpoints sản phẩm
  static String get products => '$baseUrl/Products';
  static String productById(int id) => '$baseUrl/Products/$id';
  static String productReviews(int id) => '$baseUrl/Products/$id/reviews';
  static String get productsPaged => '$baseUrl/Products/paged';
  static String get productsSearch => '$baseUrl/Products/search';
  static String productUploadImage(int id) =>
      '$baseUrl/Products/$id/upload-image';
  static String get productUploadTempImage =>
      '$baseUrl/Products/upload-temp-image';
  static String get productReview => '$baseUrl/Products/review';

  // Endpoints đơn hàng
  static String get orders => '$baseUrl/Orders';
  static String orderById(int id) => '$baseUrl/Orders/$id';
  static String orderStatus(int id) => '$baseUrl/Orders/$id/status';
  static String get posOrder => '$baseUrl/Orders/pos';
  static String get myOrders => '$baseUrl/Orders/my-orders';

  // Endpoints người dùng
  static String get users => '$baseUrl/Users';
  static String userById(String id) => '$baseUrl/Users/$id';

  // Endpoints mã giảm giá
  static String get coupons => '$baseUrl/CouponApi';
  static String couponById(int id) => '$baseUrl/CouponApi/$id';

  // Endpoints danh mục
  static String get categories => '$baseUrl/Categories';

  // Endpoints thống kê
  static String get dashboard => '$baseUrl/StatisticsApi/dashboard';

  // Endpoints kho hàng
  static String get inventory => '$baseUrl/Inventory';
  static String inventoryByLinear(String linearCode) =>
      '$baseUrl/Inventory/by-linear/$linearCode';
  static String inventoryUpdateQuantity(int productId) =>
      '$baseUrl/Inventory/$productId/update-quantity';
  static String get inventoryGenerateLinearCodes =>
      '$baseUrl/Inventory/generate-linear-codes';
  static String get inventoryExportLinearCodes =>
      '$baseUrl/Inventory/export-linear-codes';

  // Endpoints thanh toán
  static String get payment => '$baseUrl/PaymentApi';
  static String paymentVnPayCreate(int orderId) =>
      '$baseUrl/PaymentApi/vnpay/create/$orderId';
  static String paymentStatus(int orderId) =>
      '$baseUrl/PaymentApi/status/$orderId';
  static String paymentCash(int orderId) => '$baseUrl/PaymentApi/cash/$orderId';

  // Endpoints giỏ hàng
  static String get cart => '$baseUrl/Cart';
  static String cartRemoveItem(int cartItemId) => '$baseUrl/Cart/$cartItemId';

  // Thời gian chờ tối đa
  static const Duration timeout = Duration(seconds: 30);
}
