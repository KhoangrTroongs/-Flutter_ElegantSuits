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

  // Tổng tiền (nếu API tính sai hoặc cần tính local)
  double get totalPrice => _cart?.totalPrice ?? 0;

  // Fetch Cart
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
        // Nếu chưa có giỏ hàng hoặc lỗi
        _cart = null;
        // Không coi là lỗi nếu chỉ là rỗng? Controller trả về 200 OK với empty items nếu rỗng.
        // Nên nếu fail thật thì mới log.
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

  // Add to Cart
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

  // Update Cart Item
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

  // Remove Cart Item
  Future<void> removeCartItem(int cartItemId) async {
    try {
      final response = await ApiService.delete(
        ApiConfig.cartRemoveItem(cartItemId),
      );
      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['isSuccess'] == true || data['IsSuccess'] == true)) {
        // Backend returns boolean success, so we must re-fetch cart because
        // we don't know the new total price or state on server.
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

  // Clear Cart
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
}
