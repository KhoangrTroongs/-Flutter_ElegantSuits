class Coupon {
  final int id;
  final String code;
  final String? description;
  final int quantity;
  final int discountPercentage;
  final double minimumAmount;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Coupon({
    required this.id,
    required this.code,
    this.description,
    required this.quantity,
    required this.discountPercentage,
    this.minimumAmount = 0,
    this.expiryDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ cả PascalCase (từ backend) và camelCase
    final expiryStr = json['ExpiryDate'] ?? json['expiryDate'];
    final createdStr = json['CreatedAt'] ?? json['createdAt'];
    final updatedStr = json['UpdatedAt'] ?? json['updatedAt'];

    return Coupon(
      id: json['Id'] ?? json['id'] ?? 0,
      code: json['Code'] ?? json['code'] ?? '',
      description: json['Description'] ?? json['description'],
      quantity: json['Quantity'] ?? json['quantity'] ?? 0,
      discountPercentage:
          json['DiscountPercentage'] ?? json['discountPercentage'] ?? 0,
      minimumAmount: (json['MinimumAmount'] ?? json['minimumAmount'] ?? 0)
          .toDouble(),
      expiryDate: expiryStr != null ? DateTime.parse(expiryStr) : null,
      isActive: json['IsActive'] ?? json['isActive'] ?? true,
      createdAt: createdStr != null ? DateTime.parse(createdStr) : null,
      updatedAt: updatedStr != null ? DateTime.parse(updatedStr) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'quantity': quantity,
    'discountPercentage': discountPercentage,
    'minimumAmount': minimumAmount,
    'expiryDate': expiryDate?.toIso8601String(),
    'isActive': isActive,
  };

  // Kiểm tra hết hạn
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  // Kiểm tra hết số lượng
  bool get isDepleted => quantity == 0;

  // Kiểm tra tính hợp lệ
  bool get isValid {
    if (!isActive) return false;
    if (isExpired) return false;
    if (quantity == 0) return false;
    return true;
  }

  // Trạng thái hiển thị
  String get status {
    if (!isActive) return 'Không kích hoạt';
    if (isExpired) return 'Đã hết hạn';
    if (isDepleted) return 'Đã hết số lượng';
    return 'Còn hiệu lực';
  }
}
