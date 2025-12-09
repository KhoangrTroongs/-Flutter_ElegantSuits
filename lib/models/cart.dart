import 'product.dart';

/// Item trong giỏ hàng POS
class CartItem {
  final Product product;
  int quantity;
  final String? size;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.size,
  });

  /// Tính thành tiền của item
  double get subtotal => product.price * quantity;

  /// Tăng số lượng
  void increment() {
    if (quantity < product.quantity) {
      quantity++;
    }
  }

  /// Giảm số lượng
  void decrement() {
    if (quantity > 1) {
      quantity--;
    }
  }

  /// Copy with new quantity
  CartItem copyWith({int? quantity, String? size}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
    );
  }

  Map<String, dynamic> toOrderJson() {
    return {
      'productId': product.id,
      'productName': product.name,
      'quantity': quantity,
      'price': product.price,
      'size': size,
    };
  }
}

/// Giỏ hàng POS
class Cart {
  final List<CartItem> items;
  String? couponCode;
  int discountPercentage;
  double discountAmount;

  Cart({
    List<CartItem>? items,
    this.couponCode,
    this.discountPercentage = 0,
    this.discountAmount = 0,
  }) : items = items ?? [];

  /// Tổng tiền trước giảm giá
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Số lượng sản phẩm trong giỏ
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  /// Tổng tiền sau giảm giá
  double get total => subtotal - discountAmount;

  /// Giỏ hàng có rỗng không
  bool get isEmpty => items.isEmpty;

  /// Thêm sản phẩm vào giỏ
  void addProduct(Product product, {int quantity = 1, String? size}) {
    // Kiểm tra sản phẩm đã có trong giỏ chưa
    final existingIndex = items.indexWhere((item) => 
      item.product.id == product.id && item.size == size);
    
    if (existingIndex != -1) {
      // Đã có, tăng số lượng
      final existingItem = items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      if (newQuantity <= product.quantity) {
        items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      }
    } else {
      // Chưa có, thêm mới
      items.add(CartItem(
        product: product,
        quantity: quantity,
        size: size,
      ));
    }
  }

  /// Xóa sản phẩm khỏi giỏ
  void removeProduct(int productId, {String? size}) {
    items.removeWhere((item) => 
      item.product.id == productId && item.size == size);
  }

  /// Cập nhật số lượng sản phẩm
  void updateQuantity(int productId, int quantity, {String? size}) {
    final index = items.indexWhere((item) => 
      item.product.id == productId && item.size == size);
    
    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
    }
  }

  /// Áp dụng coupon
  void applyCoupon(String code, int percentage) {
    couponCode = code;
    discountPercentage = percentage;
    discountAmount = subtotal * percentage / 100;
  }

  /// Hủy coupon
  void removeCoupon() {
    couponCode = null;
    discountPercentage = 0;
    discountAmount = 0;
  }

  /// Xóa toàn bộ giỏ hàng
  void clear() {
    items.clear();
    removeCoupon();
  }

  /// Convert to order JSON
  List<Map<String, dynamic>> toOrderItemsJson() {
    return items.map((item) => item.toOrderJson()).toList();
  }
}

