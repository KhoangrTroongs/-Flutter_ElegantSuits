class Order {
  final int id;
  final String userId;
  final String userName;
  final double totalAmount;
  final String status;
  final DateTime orderDate;
  final String? shippingAddress;
  final String? notes;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.shippingAddress,
    this.notes,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả PascalCase (từ backend) và camelCase
    final itemsList =
        json['OrderDetails'] ?? json['orderDetails'] ?? json['items'];
    return Order(
      id: json['Id'] ?? json['id'] ?? 0,
      userId: json['UserId'] ?? json['userId'] ?? '',
      userName: json['UserName'] ?? json['userName'] ?? '',
      totalAmount:
          (json['TotalPrice'] ?? json['totalPrice'] ?? json['totalAmount'] ?? 0)
              .toDouble(),
      status: _parseStatus(json['Status'] ?? json['status']),
      orderDate: DateTime.parse(json['OrderDate'] ?? json['orderDate']),
      shippingAddress: json['ShippingAddress'] ?? json['shippingAddress'],
      notes: json['Notes'] ?? json['notes'],
      items: itemsList != null
          ? (itemsList as List).map((i) => OrderItem.fromJson(i)).toList()
          : null,
    );
  }

  static String _parseStatus(dynamic status) {
    if (status is int) {
      // Enum values: 0=Pending, 1=Processing, 2=Shipped, 3=Delivered, 4=Cancelled
      const statusNames = [
        'Pending',
        'Processing',
        'Shipped',
        'Delivered',
        'Cancelled',
      ];
      return status >= 0 && status < statusNames.length
          ? statusNames[status]
          : 'Unknown';
    }
    return status?.toString() ?? 'Pending';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'totalAmount': totalAmount,
    'status': status,
    'orderDate': orderDate.toIso8601String(),
    'shippingAddress': shippingAddress,
    'notes': notes,
    'items': items?.map((i) => i.toJson()).toList(),
  };
}

class OrderItem {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final String? size;
  final String? productImageUrl;

  OrderItem({
    this.id = 0,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.size,
    this.productImageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['Id'] ?? json['id'] ?? 0,
      productId: json['ProductId'] ?? json['productId'] ?? 0,
      productName: json['ProductName'] ?? json['productName'] ?? '',
      quantity: json['Quantity'] ?? json['quantity'] ?? 0,
      price: (json['Price'] ?? json['price'] ?? 0).toDouble(),
      size: json['Size'] ?? json['size'],
      productImageUrl: json['ProductImageUrl'] ?? json['productImageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'price': price,
    'size': size,
  };
}
