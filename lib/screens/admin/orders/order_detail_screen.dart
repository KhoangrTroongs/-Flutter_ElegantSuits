import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/order_provider.dart';
import '../../../models/order.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/admin/custom_drawer.dart';

// Format giá VNĐ
String formatVND(double price) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return formatter.format(price);
}

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final order = await provider.getOrderById(widget.orderId);
    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final success = await provider.updateOrderStatus(widget.orderId, newStatus);
    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Status updated to $newStatus'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Failed to update status'),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return AppTheme.infoColor;
      case 'shipping':
        return Colors.blue;
      case 'delivered':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      case 'returned':
        return Colors.purple;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.thumb_up;
      case 'shipping':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'returned':
        return Icons.assignment_return;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.goldColor),
              const SizedBox(height: 16),
              Text(
                'Loading order...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                'Order not found',
                style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = _getStatusColor(_order!.status);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Order '),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${_order!.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnGold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        color: AppTheme.goldColor,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(_order!.status),
                      color: statusColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _order!.status,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMMM dd, yyyy • HH:mm',
                    ).format(_order!.orderDate),
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 16),
                  // Status Dropdown
                  Builder(
                    builder: (context) {
                      // Map legacy statuses just in case of Hot Reload state mismatch
                      String currentStatus = _order!.status;
                      if (currentStatus == 'Processing')
                        currentStatus = 'Confirmed';
                      if (currentStatus == 'Shipped')
                        currentStatus = 'Shipping';

                      final validStatuses = [
                        'Pending',
                        'Confirmed',
                        'Shipping',
                        'Delivered',
                        'Cancelled',
                        'Returned',
                      ];

                      if (!validStatuses.contains(currentStatus)) {
                        currentStatus = 'Pending';
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Update Status:',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: _isUpdating
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.goldColor,
                                      ),
                                    ),
                                  )
                                : DropdownButton<String>(
                                    value: currentStatus,
                                    underline: const SizedBox(),
                                    dropdownColor: AppTheme.cardColor,
                                    items: validStatuses
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        v != null && v != _order!.status
                                        ? _updateStatus(v)
                                        : null,
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Customer Info Card
            _buildInfoCard(
              title: 'Customer Information',
              icon: Icons.person_outline,
              children: [
                _buildInfoRow(Icons.person, 'Name', _order!.userName),
                if (_order!.shippingAddress != null)
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    'Address',
                    _order!.shippingAddress!,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Order Summary Card
            _buildInfoCard(
              title: 'Order Summary',
              icon: Icons.receipt_long_outlined,
              children: [
                _buildInfoRow(Icons.tag, 'Order ID', '#${_order!.id}'),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date',
                  DateFormat('dd/MM/yyyy HH:mm').format(_order!.orderDate),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: AppTheme.textOnGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${formatVND(_order!.totalAmount)}₫',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Order Items
            if (_order!.items != null && _order!.items!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppTheme.goldColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Order Items (${_order!.items!.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...(_order!.items!.map((item) => _buildOrderItem(item))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.goldColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.checkroom, color: AppTheme.goldColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SL: ${item.quantity} × ${formatVND(item.price)}₫',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${formatVND(item.price * item.quantity)}₫',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.goldColor,
            ),
          ),
        ],
      ),
    );
  }
}
