class StatisticsOverview {
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;
  final int totalUsers;
  final OrdersByStatus ordersByStatus;

  StatisticsOverview({
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalProducts,
    required this.totalUsers,
    required this.ordersByStatus,
  });

  factory StatisticsOverview.fromJson(Map<String, dynamic> json) {
    return StatisticsOverview(
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalProducts: json['totalProducts'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      ordersByStatus: OrdersByStatus.fromJson(json['ordersByStatus'] ?? {}),
    );
  }

  // Tính doanh thu hôm nay (giả sử từ API trả về)
  double get todaySales => totalRevenue;
}

class OrdersByStatus {
  final int pending;
  final int confirmed;
  final int shipping;
  final int delivered;
  final int cancelled;
  final int returned;

  OrdersByStatus({
    this.pending = 0,
    this.confirmed = 0,
    this.shipping = 0,
    this.delivered = 0,
    this.cancelled = 0,
    this.returned = 0,
  });

  factory OrdersByStatus.fromJson(Map<String, dynamic> json) {
    return OrdersByStatus(
      pending: json['pending'] ?? 0,
      confirmed: json['confirmed'] ?? 0,
      shipping: json['shipping'] ?? 0,
      delivered: json['delivered'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      returned: json['returned'] ?? 0,
    );
  }

  int get total => pending + confirmed + shipping + delivered + cancelled + returned;
}

