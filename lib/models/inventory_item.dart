class InventoryItem {
  static const String _imageBaseUrl = 'https://localhost:5001';

  final int productId;
  final String productName;
  final String categoryName;
  final int quantity;
  final String? linearCode;
  final String? imageUrl;
  final double price;

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantity,
    this.linearCode,
    this.imageUrl,
    required this.price,
  });

  // Lấy URL ảnh đầy đủ
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
    return '$_imageBaseUrl$imageUrl';
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      productId: json['ProductId'] ?? json['productId'] ?? 0,
      productName: json['ProductName'] ?? json['productName'] ?? '',
      categoryName: json['CategoryName'] ?? json['categoryName'] ?? '',
      quantity: json['Quantity'] ?? json['quantity'] ?? 0,
      linearCode: json['LinearCode'] ?? json['linearCode'],
      imageUrl: json['ImageUrl'] ?? json['imageUrl'],
      price: (json['Price'] ?? json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'quantity': quantity,
      'linearCode': linearCode,
      'imageUrl': imageUrl,
      'price': price,
    };
  }

  InventoryItem copyWith({
    int? productId,
    String? productName,
    String? categoryName,
    int? quantity,
    String? linearCode,
    String? imageUrl,
    double? price,
  }) {
    return InventoryItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      linearCode: linearCode ?? this.linearCode,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }
}
