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
  final String? couponCode;
  final double discountAmount;
  final String? paymentMethod;
  final String? paymentStatus;

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
    this.couponCode,
    this.discountAmount = 0,
    this.paymentMethod,
    this.paymentStatus,
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
      couponCode: json['CouponCode'] ?? json['couponCode'],
      discountAmount: (json['DiscountAmount'] ?? json['discountAmount'] ?? 0)
          .toDouble(),
      paymentMethod: json['PaymentMethod'] ?? json['paymentMethod'],
      paymentStatus: _parsePaymentStatus(
        json['PaymentStatus'] ?? json['paymentStatus'],
      ),
      items: itemsList != null
          ? (itemsList as List).map((i) => OrderItem.fromJson(i)).toList()
          : null,
    );
  }

  static String _parsePaymentStatus(dynamic status) {
    if (status is int) {
      // 0=Pending, 1=Paid, 2=Failed
      const statusNames = ['Pending', 'Paid', 'Failed'];
      return status >= 0 && status < statusNames.length
          ? statusNames[status]
          : 'Unknown';
    }
    return status?.toString() ?? 'Pending';
  }

  static String _parseStatus(dynamic status) {
    if (status is int) {
      // Enum values: 0=Pending, 1=Confirmed, 2=Shipping, 3=Delivered, 4=Cancelled, 5=Returned
      const statusNames = [
        'Pending',
        'Confirmed',
        'Shipping',
        'Delivered',
        'Cancelled',
        'Returned',
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
