import 'dart:convert';
import '../config/api_config.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  // Helper method để check success với cả PascalCase và camelCase
  bool _isSuccess(Map<String, dynamic> data) {
    return data['IsSuccess'] == true ||
        data['isSuccess'] == true ||
        data['success'] == true;
  }

  dynamic _getData(Map<String, dynamic> data) {
    return data['Data'] ?? data['data'];
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await ApiService.get(ApiConfig.orders);

      // Debug: in ra response để kiểm tra
      print('=== ORDERS RESPONSE ===');
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
            .map((json) => Order.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<List<Order>> getMyOrders() async {
    try {
      final response = await ApiService.get(ApiConfig.myOrders);
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return (_getData(data) as List)
            .map((json) => Order.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching my orders: $e');
    }
  }

  Future<Order> getOrderById(int id) async {
    try {
      final response = await ApiService.get(ApiConfig.orderById(id));
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return Order.fromJson(_getData(data));
      }
      throw Exception('Order not found');
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  int _statusToInt(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'shipping':
        return 2;
      case 'delivered':
        return 3;
      case 'cancelled':
        return 4;
      case 'returned':
        return 5;
      default:
        return 0;
    }
  }

  Future<void> updateOrderStatus(int id, String status) async {
    try {
      final statusInt = _statusToInt(status);
      final response = await ApiService.put(ApiConfig.orderStatus(id), {
        'status': statusInt,
      });
      final data = ApiService.parseResponse(response);

      if (!_isSuccess(data)) {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }
}
