import 'dart:convert';
import '../config/api_config.dart';
import '../models/inventory_item.dart';
import 'api_service.dart';

class InventoryService {
  InventoryService([ApiService? apiService]);

  /// Lấy danh sách tồn kho
  Future<List<InventoryItem>> getInventory() async {
    try {
      print('Calling inventory API: ${ApiConfig.inventory}');
      final response = await ApiService.get(ApiConfig.inventory);
      print('Inventory response status: ${response.statusCode}');
      print('Inventory response body: ${response.body}');

      final json = jsonDecode(response.body);

      // API trả về IsSuccess, Message, Data (viết hoa)
      final isSuccess = json['IsSuccess'] ?? json['succeeded'] ?? false;
      final data = json['Data'] ?? json['data'];

      if (isSuccess == true && data != null) {
        final items = data as List;
        print('Found ${items.length} inventory items');
        return items.map((item) => InventoryItem.fromJson(item)).toList();
      }

      print(
        'API returned: isSuccess=$isSuccess, message=${json['Message'] ?? json['message']}',
      );
      return [];
    } catch (e) {
      print('Inventory error: $e');
      rethrow;
    }
  }

  /// Tìm sản phẩm theo mã linear (barcode)
  Future<InventoryItem?> getByLinearCode(String linearCode) async {
    try {
      final response = await ApiService.get(
        ApiConfig.inventoryByLinear(linearCode),
      );
      final json = jsonDecode(response.body);

      final isSuccess = json['IsSuccess'] ?? json['succeeded'] ?? false;
      final data = json['Data'] ?? json['data'];

      if (isSuccess == true && data != null) {
        return InventoryItem.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cập nhật số lượng tồn kho
  /// [isAbsolute] = true: đặt số lượng tuyệt đối
  /// [isAbsolute] = false: thêm/bớt số lượng (quantity có thể âm để xuất kho)
  Future<InventoryItem?> updateQuantity(
    int productId,
    int quantity, {
    bool isAbsolute = false,
  }) async {
    final response = await ApiService.put(
      ApiConfig.inventoryUpdateQuantity(productId),
      {'quantity': quantity, 'isAbsolute': isAbsolute},
    );
    final json = jsonDecode(response.body);

    final isSuccess = json['IsSuccess'] ?? json['succeeded'] ?? false;
    final data = json['Data'] ?? json['data'];

    if (isSuccess == true && data != null) {
      return InventoryItem.fromJson(data);
    }
    return null;
  }

  /// Nhập kho - thêm số lượng
  Future<InventoryItem?> importStock(int productId, int quantity) async {
    return updateQuantity(productId, quantity, isAbsolute: false);
  }

  /// Xuất kho - bớt số lượng
  Future<InventoryItem?> exportStock(int productId, int quantity) async {
    return updateQuantity(productId, -quantity, isAbsolute: false);
  }

  /// Đặt số lượng tuyệt đối
  Future<InventoryItem?> setQuantity(int productId, int quantity) async {
    return updateQuantity(productId, quantity, isAbsolute: true);
  }

  /// Tạo mã linear cho tất cả sản phẩm chưa có
  Future<int> generateLinearCodes() async {
    final response = await ApiService.post(
      ApiConfig.inventoryGenerateLinearCodes,
      {},
    );
    final json = jsonDecode(response.body);

    final isSuccess = json['IsSuccess'] ?? json['succeeded'] ?? false;
    final data = json['Data'] ?? json['data'];

    if (isSuccess == true) {
      return data ?? 0;
    }
    throw Exception(
      json['Message'] ?? json['message'] ?? 'Lỗi khi tạo mã linear',
    );
  }
}
