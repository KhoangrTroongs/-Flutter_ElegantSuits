import '../config/api_config.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  // Helper methods để check response với cả PascalCase và camelCase
  bool _isSuccess(Map<String, dynamic> data) {
    return data['IsSuccess'] == true ||
        data['isSuccess'] == true ||
        data['success'] == true;
  }

  dynamic _getData(Map<String, dynamic> data) {
    return data['Data'] ?? data['data'];
  }

  Future<List<Product>> getProducts({int? categoryId}) async {
    try {
      String url = ApiConfig.products;
      if (categoryId != null) {
        url += '?categoryId=$categoryId';
      }

      final response = await ApiService.get(url);
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return (_getData(data) as List)
            .map((json) => Product.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await ApiService.get(ApiConfig.productById(id));
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return Product.fromJson(_getData(data));
      }
      throw Exception('Product not found');
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      // Backend dùng [FromForm] nên cần gửi multipart
      final fields = {
        'name': product.name,
        'description': product.description ?? '',
        'price': product.price.toString(),
        'categoryId': product.categoryId.toString(),
        'isHidden': product.isHidden.toString(),
      };

      final response = await ApiService.postForm(ApiConfig.products, fields);
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return Product.fromJson(_getData(data));
      }
      throw Exception('Failed to create product');
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  Future<Product> updateProduct(int id, Product product) async {
    try {
      // Backend dùng [FromForm] nên cần gửi multipart
      final fields = {
        'name': product.name,
        'description': product.description ?? '',
        'price': product.price.toString(),
        'categoryId': product.categoryId.toString(),
        'isHidden': product.isHidden.toString(),
      };

      final response = await ApiService.putForm(
        ApiConfig.productById(id),
        fields,
      );
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return Product.fromJson(_getData(data));
      }
      throw Exception('Failed to update product');
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await ApiService.delete(ApiConfig.productById(id));
      final data = ApiService.parseResponse(response);

      if (!_isSuccess(data)) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.categories);
      final data = ApiService.parseResponse(response);

      if (_isSuccess(data) && _getData(data) != null) {
        return (_getData(data) as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}
