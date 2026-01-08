class ApiCart {
  final int id;
  final String userId;
  final List<ApiCartItem> items;
  final double totalPrice;

  ApiCart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
  });

  factory ApiCart.fromJson(Map<String, dynamic> json) {
    var list = json['items'] ?? json['Items'] ?? [];
    List<ApiCartItem> itemsList = [];
    if (list is List) {
      itemsList = list
          .map<ApiCartItem>((i) => ApiCartItem.fromJson(i))
          .toList();
    }

    return ApiCart(
      id: json['id'] ?? json['Id'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? '',
      items: itemsList,
      totalPrice: (json['totalPrice'] ?? json['TotalPrice'] ?? 0).toDouble(),
    );
  }
}

class ApiCartItem {
  final int id; // CartItemId
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final String? size;

  ApiCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.size,
  });

  factory ApiCartItem.fromJson(Map<String, dynamic> json) {
    return ApiCartItem(
      id: json['id'] ?? json['Id'] ?? 0,
      productId: json['productId'] ?? json['ProductId'] ?? 0,
      productName: json['productName'] ?? json['ProductName'] ?? '',
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? json['Quantity'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['ImageUrl'] ?? '',
      size: json['size'] ?? json['Size'],
    );
  }

  String get fullImageUrl {
    if (imageUrl.isEmpty) return 'https://via.placeholder.com/150';
    if (imageUrl.startsWith('http')) return imageUrl;
    // Base URL logic should be handled by a helper or passed in,
    // but for simple display, we might rely on the caller to format it
    // or ApiConfig.imageBaseUrl if available globally.
    // For now, return relative path and let UI handle concatenation.
    return imageUrl;
  }
}
