class ApiConfig {
  // Base URL - Update this to your API URL
  // Dùng localhost nếu chạy trên Windows/Web
  // Dùng 10.0.2.2 nếu chạy trên Android Emulator
  // Dùng IP máy tính (ví dụ: 192.168.x.x) nếu chạy trên thiết bị thật
  static const String baseUrl = 'https://localhost:5001/api';

  // Auth endpoints
  static const String login = '$baseUrl/Auth/login';
  static const String register = '$baseUrl/Auth/register';

  // Products endpoints
  static const String products = '$baseUrl/Products';
  static String productById(int id) => '$baseUrl/Products/$id';
  static const String productsPaged = '$baseUrl/Products/paged';
  static const String productsSearch = '$baseUrl/Products/search';

  // Orders endpoints
  static const String orders = '$baseUrl/Orders';
  static String orderById(int id) => '$baseUrl/Orders/$id';
  static String orderStatus(int id) => '$baseUrl/Orders/$id/status';

  // Users endpoints
  static const String users = '$baseUrl/Users';
  static String userById(String id) => '$baseUrl/Users/$id';

  // Coupons endpoints
  static const String coupons = '$baseUrl/CouponApi';
  static String couponById(int id) => '$baseUrl/CouponApi/$id';

  // Categories endpoints
  static const String categories = '$baseUrl/Categories';

  // Statistics endpoints
  static const String dashboard = '$baseUrl/StatisticsApi/dashboard';

  // Timeout
  static const Duration timeout = Duration(seconds: 30);
}
