import 'package:flutter/foundation.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _inventoryService;

  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;
  InventoryItem? _scannedItem;

  InventoryProvider(this._inventoryService);

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  InventoryItem? get scannedItem => _scannedItem;

  /// Lấy danh sách tồn kho
  Future<void> loadInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _inventoryService.getInventory();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Tìm sản phẩm theo mã vạch
  Future<InventoryItem?> findByLinearCode(String linearCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _scannedItem = await _inventoryService.getByLinearCode(linearCode);
      if (_scannedItem == null) {
        _error = 'Không tìm thấy sản phẩm với mã: $linearCode';
      }
    } catch (e) {
      _error = e.toString();
      _scannedItem = null;
    }

    _isLoading = false;
    notifyListeners();
    return _scannedItem;
  }

  /// Xóa sản phẩm đã quét
  void clearScannedItem() {
    _scannedItem = null;
    notifyListeners();
  }

  /// Nhập kho
  Future<bool> importStock(int productId, int quantity) async {
    try {
      final updated = await _inventoryService.importStock(productId, quantity);
      if (updated != null) {
        _updateItemInList(updated);
        if (_scannedItem?.productId == productId) {
          _scannedItem = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xuất kho
  Future<bool> exportStock(int productId, int quantity) async {
    try {
      final updated = await _inventoryService.exportStock(productId, quantity);
      if (updated != null) {
        _updateItemInList(updated);
        if (_scannedItem?.productId == productId) {
          _scannedItem = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Đặt số lượng tuyệt đối
  Future<bool> setQuantity(int productId, int quantity) async {
    try {
      final updated = await _inventoryService.setQuantity(productId, quantity);
      if (updated != null) {
        _updateItemInList(updated);
        if (_scannedItem?.productId == productId) {
          _scannedItem = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Tạo mã vạch cho tất cả sản phẩm
  Future<int> generateLinearCodes() async {
    try {
      final count = await _inventoryService.generateLinearCodes();
      await loadInventory(); // Reload để cập nhật mã mới
      return count;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _updateItemInList(InventoryItem updated) {
    final index = _items.indexWhere((i) => i.productId == updated.productId);
    if (index != -1) {
      _items[index] = updated;
    }
  }
}
