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

  Future<void> updateOrderStatus(int id, String status) async {
    try {
      final response = await ApiService.put(ApiConfig.orderStatus(id), {
        'status': status,
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
