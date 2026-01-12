import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lấy danh sách sản phẩm (có thể lọc theo danh mục)
  Future<void> fetchProducts({int? categoryId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts(categoryId: categoryId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lấy danh sách danh mục
  Future<void> fetchCategories() async {
    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Thêm sản phẩm mới
  Future<bool> addProduct(Product product) async {
    try {
      final newProduct = await _productService.createProduct(product);
      _products.add(newProduct);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cập nhật sản phẩm
  Future<bool> updateProduct(int id, Product product) async {
    try {
      final updatedProduct = await _productService.updateProduct(id, product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Xóa sản phẩm
  Future<bool> deleteProduct(int id) async {
    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Tải lên ảnh sản phẩm
  Future<String?> uploadProductImage(int productId, String filePath) async {
    try {
      final imageUrl = await _productService.uploadProductImage(
        productId,
        filePath,
      );
      // Cập nhật product trong list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(imageUrl: imageUrl);
        notifyListeners();
      }
      return imageUrl;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Tải lên ảnh tạm (cho sản phẩm đang tạo)
  Future<String?> uploadTempImage(String filePath, String productName) async {
    try {
      final imageUrl = await _productService.uploadTempImage(
        filePath,
        productName,
      );
      return imageUrl;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
