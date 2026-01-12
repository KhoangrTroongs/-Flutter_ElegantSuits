import '../config/api_config.dart';
class Product {

  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int categoryId;
  final String? categoryName;
  final bool isHidden;
  final int quantity;
  final String? linearCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
    this.isHidden = false,
    this.quantity = 0,
    this.linearCode,
    this.createdAt,
    this.updatedAt,
  });

  /// Get full image URL (add base URL if relative path)
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    // Nếu đã là URL đầy đủ, trả về luôn
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
// Nếu là relative path, thêm base URL từ ApiConfig
    // Loại bỏ dấu / ở đầu imageUrl nếu có để tránh double slash //
    final cleanPath = imageUrl!.startsWith('/')
        ? imageUrl!.substring(1)
        : imageUrl!;
    return '${ApiConfig.imageBaseUrl}/$cleanPath';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả PascalCase (từ backend) và camelCase
    return Product(
      id: json['Id'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      description: json['Description'] ?? json['description'] ?? '',
      price: (json['Price'] ?? json['price'] ?? 0).toDouble(),
      imageUrl: json['ImageUrl'] ?? json['imageUrl'],
      categoryId: json['CategoryId'] ?? json['categoryId'] ?? 0,
      categoryName: json['CategoryName'] ?? json['categoryName'],
      isHidden: json['IsHidden'] ?? json['isHidden'] ?? false,
      quantity: json['Quantity'] ?? json['quantity'] ?? 0,
      linearCode: json['LinearCode'] ?? json['linearCode'],
      createdAt: (json['CreatedAt'] ?? json['createdAt']) != null
          ? DateTime.parse(json['CreatedAt'] ?? json['createdAt'])
          : null,
      updatedAt: (json['UpdatedAt'] ?? json['updatedAt']) != null
          ? DateTime.parse(json['UpdatedAt'] ?? json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'isHidden': isHidden,
      'quantity': quantity,
      'linearCode': linearCode,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    String? categoryName,
    bool? isHidden,
    int? quantity,
    String? linearCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isHidden: isHidden ?? this.isHidden,
      quantity: quantity ?? this.quantity,
      linearCode: linearCode ?? this.linearCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả PascalCase (từ backend) và camelCase
    return Category(
      id: json['Id'] ?? json['id'] ?? 0,
      name: json['Name'] ?? json['name'] ?? '',
      description: json['Description'] ?? json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}
