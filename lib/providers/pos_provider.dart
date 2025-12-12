import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/coupon.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'dart:convert';

class PosProvider extends ChangeNotifier {
  Cart _cart = Cart();
  User? _selectedCustomer;
  bool _isLoading = false;
  String? _error;
  List<User> _searchedCustomers = [];
  List<Product> _products = [];
  List<Coupon> _availableCoupons = [];

  // Getters
  Cart get cart => _cart;
  User? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<User> get searchedCustomers => _searchedCustomers;
  List<Product> get products => _products;
  List<Coupon> get availableCoupons => _availableCoupons;

  // Khách vãn lai default email
  static const String guestEmail = 'khachvanlai@example.com';

  /// Tìm kiếm khách hàng (chỉ Customer, không bao gồm Admin)
  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      _searchedCustomers = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '${ApiConfig.users}?search=${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both list and wrapped response
        final List<dynamic> usersList = data is List
            ? data
            : (data['data'] ?? data['Data'] ?? []);
        _searchedCustomers = usersList
            .map((json) => User.fromJson(json))
            .where((user) => !user.isAdmin) // Loại bỏ admin
            .toList();
      } else {
        _error = 'Không thể tìm kiếm khách hàng';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Chọn khách hàng
  void selectCustomer(User customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  /// Chọn khách vãn lai
  Future<void> selectGuestCustomer() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '${ApiConfig.users}?search=${Uri.encodeComponent(guestEmail)}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> usersList = data is List
            ? data
            : (data['data'] ?? data['Data'] ?? []);

        // Tìm user có email khớp chính xác
        final guestJson = usersList.firstWhere(
          (u) =>
              (u['Email'] ?? u['email'])?.toString().toLowerCase() ==
              guestEmail.toLowerCase(),
          orElse: () => null,
        );

        if (guestJson != null) {
          _selectedCustomer = User.fromJson(guestJson);
        } else {
          // Tạo guest user local nếu không tìm thấy
          _selectedCustomer = User(
            id: 'guest',
            email: guestEmail,
            fullName: 'Khách Vãn Lai',
          );
        }
      } else {
        // API error - use local guest
        _selectedCustomer = User(
          id: 'guest',
          email: guestEmail,
          fullName: 'Khách Vãn Lai',
        );
      }
    } catch (e) {
      // Fallback to local guest user
      _selectedCustomer = User(
        id: 'guest',
        email: guestEmail,
        fullName: 'Khách Vãn Lai',
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load danh sách sản phẩm
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConfig.products);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsList = data is List
            ? data
            : (data['data'] ?? data['Data'] ?? []);
        _products = productsList
            .map((json) => Product.fromJson(json))
            .where((p) => !p.isHidden && p.quantity > 0)
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load danh sách coupon khả dụng
  Future<void> loadCoupons() async {
    try {
      final response = await ApiService.get(ApiConfig.coupons);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> couponsList = data is List
            ? data
            : (data['data'] ?? data['Data'] ?? []);
        _availableCoupons = couponsList
            .map((json) => Coupon.fromJson(json))
            .where((c) => c.isValid)
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Thêm sản phẩm vào giỏ
  void addToCart(Product product, {int quantity = 1, String? size}) {
    // Kiểm tra số lượng tồn kho
    final existingItem = _cart.items
        .where((item) => item.product.id == product.id && item.size == size)
        .firstOrNull;

    final currentQty = existingItem?.quantity ?? 0;
    if (currentQty + quantity > product.quantity) {
      _error = 'Số lượng vượt quá tồn kho (còn ${product.quantity})';
      notifyListeners();
      return;
    }

    _cart.addProduct(product, quantity: quantity, size: size);
    _recalculateDiscount();
    notifyListeners();
  }

  /// Xóa sản phẩm khỏi giỏ
  void removeFromCart(int productId, {String? size}) {
    _cart.removeProduct(productId, size: size);
    _recalculateDiscount();
    notifyListeners();
  }

  /// Cập nhật số lượng
  void updateQuantity(int productId, int quantity, {String? size}) {
    _cart.updateQuantity(productId, quantity, size: size);
    _recalculateDiscount();
    notifyListeners();
  }

  /// Tính lại discount khi giỏ hàng thay đổi
  void _recalculateDiscount() {
    if (_cart.couponCode != null) {
      _cart.discountAmount = _cart.subtotal * _cart.discountPercentage / 100;
    }
  }

  /// Load danh sách coupon khả dụng
  Future<void> loadAvailableCoupons() async {
    try {
      final response = await ApiService.get(ApiConfig.coupons);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> couponsList = data is List
            ? data
            : (data['data'] ?? data['Data'] ?? []);

        _availableCoupons = couponsList
            .map((json) => Coupon.fromJson(json))
            .where((c) => c.isValid && c.minimumAmount <= _cart.subtotal)
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  /// Áp dụng coupon
  Future<bool> applyCoupon(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(
        '${ApiConfig.coupons}/validate?code=${Uri.encodeComponent(code)}&cartTotal=${_cart.subtotal}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['isValid'] == true || data['IsValid'] == true) {
          final couponData = data['coupon'] ?? data['Coupon'];
          if (couponData != null) {
            final coupon = Coupon.fromJson(couponData);
            _cart.applyCoupon(code, coupon.discountPercentage);
            _isLoading = false;
            notifyListeners();
            return true;
          }
        } else {
          _error =
              data['errorMessage'] ??
              data['ErrorMessage'] ??
              'Mã giảm giá không hợp lệ';
        }
      } else {
        // Fallback: tìm coupon local
        final coupon = _availableCoupons
            .where((c) => c.code.toUpperCase() == code.toUpperCase())
            .firstOrNull;
        if (coupon != null && coupon.minimumAmount <= _cart.subtotal) {
          _cart.applyCoupon(code, coupon.discountPercentage);
          _isLoading = false;
          notifyListeners();
          return true;
        }
        _error = 'Mã giảm giá không hợp lệ';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Hủy coupon
  void removeCoupon() {
    _cart.removeCoupon();
    notifyListeners();
  }

  /// Tạo đơn hàng POS (với items trực tiếp)
  Future<int?> createOrder({String paymentMethod = 'Cash'}) async {
    if (_selectedCustomer == null) {
      _error = 'Vui lòng chọn khách hàng';
      notifyListeners();
      return null;
    }

    if (_cart.isEmpty) {
      _error = 'Giỏ hàng trống';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Format cho POS endpoint mới - gửi items trực tiếp
      final orderData = {
        'customerId': _selectedCustomer!.id,
        'shippingAddress': _selectedCustomer!.address ?? 'Mua tại cửa hàng',
        'notes': 'Đơn hàng POS - ${DateTime.now()}',
        'couponCode': _cart.couponCode,
        'paymentMethod': paymentMethod,
        'items': _cart.toOrderItemsJson(),
      };

      final response = await ApiService.post(ApiConfig.posOrder, orderData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Handle wrapped response
        final orderObj = data['data'] ?? data['Data'] ?? data;
        final orderId =
            orderObj['id'] ??
            orderObj['Id'] ??
            orderObj['orderId'] ??
            orderObj['OrderId'];
        _isLoading = false;
        notifyListeners();
        return orderId;
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? data['Message'] ?? 'Không thể tạo đơn hàng';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Tạo URL thanh toán VNPay
  Future<String?> createVnPayPayment(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '${ApiConfig.paymentVnPayCreate(orderId)}?clientHost=${ApiConfig.hostIP}',
        {},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _isLoading = false;
          notifyListeners();
          return data['payUrl'];
        } else {
          _error = data['message'] ?? 'Không thể tạo thanh toán VNPay';
        }
      } else {
        _error = 'Lỗi kết nối đến server';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Đánh dấu thanh toán tiền mặt
  Future<bool> markCashPayment(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        ApiConfig.paymentCash(orderId),
        {},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Không thể xác nhận thanh toán';
        }
      } else {
        _error = 'Lỗi kết nối đến server';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Kiểm tra trạng thái thanh toán
  Future<Map<String, dynamic>?> checkPaymentStatus(int orderId) async {
    try {
      final response = await ApiService.get(ApiConfig.paymentStatus(orderId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  /// Reset toàn bộ POS
  void reset() {
    _cart = Cart();
    _selectedCustomer = null;
    _searchedCustomers = [];
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
