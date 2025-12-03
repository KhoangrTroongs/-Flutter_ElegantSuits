import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Tự động phát hiện platform và sử dụng URL phù hợp
  static String get baseUrl {
    // Port của API .NET
    const String port = '5001';

    if (kIsWeb) {
      // Web browser - sử dụng localhost
      return 'https://localhost:$port/api';
    }

    try {
      if (Platform.isAndroid) {
        // Android Emulator - 10.0.2.2 là địa chỉ đặc biệt trỏ đến localhost của máy host
        return 'https://10.0.2.2:$port/api';
      } else if (Platform.isIOS) {
        // iOS Simulator - có thể dùng localhost
        return 'https://localhost:$port/api';
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop - sử dụng localhost
        return 'https://localhost:$port/api';
      }
    } catch (e) {
      // Fallback nếu không thể xác định platform
    }

    return 'https://localhost:$port/api';
  }

  // Auth endpoints
  static String get login => '$baseUrl/Auth/login';
  static String get register => '$baseUrl/Auth/register';

  // Products endpoints
  static String get products => '$baseUrl/Products';
  static String productById(int id) => '$baseUrl/Products/$id';
  static String get productsPaged => '$baseUrl/Products/paged';
  static String get productsSearch => '$baseUrl/Products/search';

  // Orders endpoints
  static String get orders => '$baseUrl/Orders';
  static String orderById(int id) => '$baseUrl/Orders/$id';
  static String orderStatus(int id) => '$baseUrl/Orders/$id/status';

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

  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
