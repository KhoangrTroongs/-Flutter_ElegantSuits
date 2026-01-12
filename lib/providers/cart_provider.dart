import 'package:flutter/material.dart';
import '../models/api_cart.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class CartProvider with ChangeNotifier {
  ApiCart? _cart;
  bool _isLoading = false;
  String? _error;

  ApiCart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount =>
      _cart?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;

  // Tổng giá trị đơn hàng
  double get totalPrice => _cart?.totalPrice ?? 0;

  // Lấy danh sách giỏ hàng
  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get(ApiConfig.cart);
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        _cart = ApiCart.fromJson(data['data'] ?? data['Data']);
      } else {
        // Giỏ hàng trống hoặc lỗi
        _cart = null;
        // Xử lý thông báo lỗi từ Map
        if (data is Map) {
          _error = data['message'] ?? data['Message'];
        }
      }
    } catch (e) {
      _error = e.toString();
      print("Error fetching cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm sản phẩm vào giỏ
  Future<void> addToCart(int productId, int quantity, String? size) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {'productId': productId, 'quantity': quantity, 'size': size};

      final response = await ApiService.post(ApiConfig.cart, body);
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        _cart = ApiCart.fromJson(data['data'] ?? data['Data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      _error = e.toString();
      rethrow; // Để UI xử lý (hiện snackbar)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật số lượng sản phẩm
  Future<void> updateCartItem(int cartItemId, int quantity) async {
    try {
      final body = {'cartItemId': cartItemId, 'quantity': quantity};

      final response = await ApiService.put(ApiConfig.cart, body);
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        _cart = ApiCart.fromJson(data['data'] ?? data['Data']);
        notifyListeners();
      } else {
        throw Exception(data['message'] ?? 'Failed to update cart');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Xóa sản phẩm khỏi giỏ
  Future<void> removeCartItem(int cartItemId) async {
    try {
      final response = await ApiService.delete(
        ApiConfig.cartRemoveItem(cartItemId),
      );
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        // Tải lại giỏ hàng sau khi xóa
        await fetchCart();
      } else {
        throw Exception(data['message'] ?? 'Failed to remove item');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    try {
      final response = await ApiService.delete(ApiConfig.cart);
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        _cart = null;
        await fetchCart();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Thanh toán
  Future<Map<String, dynamic>> checkout({
    required String shippingAddress,
    String? notes,
    String? couponCode,
    String paymentMethod = 'COD',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'shippingAddress': shippingAddress,
        'notes': notes,
        'couponCode': couponCode,
        'paymentMethod': paymentMethod,
      };

      final response = await ApiService.post(ApiConfig.orders, body);
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        // Thanh toán thành công, làm mới giỏ hàng
        await fetchCart();
        return {'success': true, 'data': data['data'] ?? data['Data']};
      } else {
        throw Exception(data['message'] ?? 'Checkout failed');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
