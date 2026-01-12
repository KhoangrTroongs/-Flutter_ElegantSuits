import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../providers/pos_provider.dart';
import '../../../models/cart.dart' show CartItem;
import '../../../config/app_theme.dart';

import 'dart:async';
import 'package:app_links/app_links.dart';
import '../inventory/scan_barcode_screen.dart';
import '../../client/payment/payment_webview_screen.dart';
import '../../../widgets/payment_success_dialog.dart';

// Format giá VNĐ
String formatVND(double price) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return formatter.format(price);
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _customerSearchController =
      TextEditingController();
  bool _showCustomerSearch = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PosProvider>(context, listen: false);
      provider.loadProducts();
      provider.loadCoupons();
    });

    // Lắng nghe deep link
    _initDeepLinkListener();
  }

  // Khởi tạo và lắng nghe Deep Link
  void _initDeepLinkListener() {
    final _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'elegantsuits' && uri.path.contains('payment-result')) {
        // Parse params: ?orderId=123&status=00
        final orderIdStr = uri.queryParameters['orderId'];
        final status = uri.queryParameters['status'];

        if (orderIdStr != null && mounted) {
          final orderId = int.tryParse(orderIdStr);
          if (orderId != null) {
            if (status == 'success') {
              _checkPaymentAndShowDialog(orderId);
            } else {
              // Payment failed or other status
              _handlePaymentFailure(status ?? 'unknown');
            }
          }
        }
      }
    });
  }

  // Kiểm tra thanh toán và hiển thị dialog thành công
  Future<void> _checkPaymentAndShowDialog(int orderId) async {
    try {
      final provider = Provider.of<PosProvider>(context, listen: false);
      final statusData = await provider.checkPaymentStatus(orderId);

      if (!mounted) return;

      if (statusData != null && statusData['isPaid'] == true) {
        // Safely close any open dialogs
        while (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        _showSuccessDialog(orderId, 'VNPay');
        provider.reset();
        provider.selectGuestCustomer();
      }
    } catch (e) {
      print('Error checking payment status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kiểm tra trạng thái thanh toán')),
        );
      }
    }
  }

  // Xử lý khi thanh toán thất bại
  void _handlePaymentFailure(String status) {
    if (!mounted) return;

    // Close any dialogs
    while (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thanh toán thất bại: $status'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Tạo Đơn Hàng (POS)'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnGold,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<PosProvider>(context, listen: false).reset();
              Provider.of<PosProvider>(
                context,
                listen: false,
              ).selectGuestCustomer();
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Consumer<PosProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Phần 1: Chọn khách hàng
              _buildCustomerSection(provider),

              // Phần 2: Giỏ hàng
              Expanded(child: _buildCartSection(provider)),

              // Phần 3: Tổng tiền và thanh toán
              _buildTotalSection(provider),
            ],
          );
        },
      ),
    );
  }

  // Phần chọn khách hàng
  // Cho phép tìm kiếm hoặc chọn khách vãng lai
  Widget _buildCustomerSection(PosProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.goldColor),
              const SizedBox(width: 8),
              const Text(
                'Khách hàng:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.selectedCustomer?.displayName ?? 'Chưa chọn',
                  style: const TextStyle(
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showCustomerSearch = !_showCustomerSearch),
                icon: Icon(
                  _showCustomerSearch ? Icons.close : Icons.search,
                  size: 18,
                ),
                label: Text(_showCustomerSearch ? 'Đóng' : 'Tìm KH'),
              ),
            ],
          ),
          if (_showCustomerSearch) ...[
            const SizedBox(height: 12),
            _buildCustomerSearchField(provider),
          ],
        ],
      ),
    );
  }

  // Ô tìm kiếm khách hàng
  Widget _buildCustomerSearchField(PosProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customerSearchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tên, SĐT hoặc Email...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.goldColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (value) => provider.searchCustomers(value),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                provider.selectGuestCustomer();
                setState(() => _showCustomerSearch = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
              ),
              child: const Text(
                'Khách Vãn Lai',
                style: TextStyle(color: AppTheme.goldColor),
              ),
            ),
          ],
        ),
        if (provider.searchedCustomers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.goldColor.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.searchedCustomers.length,
              itemBuilder: (context, index) {
                final customer = provider.searchedCustomers[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person, color: AppTheme.goldColor),
                  title: Text(
                    customer.displayName,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    customer.phoneNumber ?? customer.email,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    provider.selectCustomer(customer);
                    setState(() => _showCustomerSearch = false);
                    _customerSearchController.clear();
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Phần hiển thị giỏ hàng
  // Bao gồm danh sách sản phẩm và nút thêm sản phẩm
  Widget _buildCartSection(PosProvider provider) {
    if (provider.cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Giỏ hàng trống',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Quét mã'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddProductDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm SP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: provider.cart.items.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        // Last item is the add button
        if (index == provider.cart.items.length) {
          return _buildAddProductButton();
        }
        final item = provider.cart.items[index];
        return _buildCartItem(item, provider);
      },
    );
  }

  // Nút thêm sản phẩm
  Widget _buildAddProductButton() {
    return Card(
      color: AppTheme.cardColor.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _showAddProductDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: AppTheme.goldColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Thêm sản phẩm',
                style: TextStyle(
                  color: AppTheme.goldColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Quét mã'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card hiển thị sản phẩm trong giỏ
  Widget _buildCartItem(CartItem cartItem, PosProvider provider) {
    final product = cartItem.product;
    return Card(
      color: AppTheme.cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.fullImageUrl != null
                  ? Image.network(
                      product.fullImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 12),
            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatVND(product.price)}₫',
                    style: const TextStyle(color: AppTheme.goldColor),
                  ),
                ],
              ),
            ),
            // Số lượng
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () {
                      if (cartItem.quantity > 1) {
                        provider.updateQuantity(
                          product.id,
                          cartItem.quantity - 1,
                        );
                      }
                    },
                    color: AppTheme.textPrimary,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    '${cartItem.quantity}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () {
                      if (cartItem.quantity < product.quantity) {
                        provider.updateQuantity(
                          product.id,
                          cartItem.quantity + 1,
                        );
                      }
                    },
                    color: AppTheme.textPrimary,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Thành tiền
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatVND(cartItem.subtotal)}₫',
                  style: const TextStyle(
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => provider.removeFromCart(product.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 50,
      height: 50,
      color: AppTheme.primaryColor,
      child: const Icon(Icons.image, color: AppTheme.goldColor, size: 24),
    );
  }

  // Phần tống tiền và thanh toán
  // Tính toán tổng tiền, áp dụng coupon và các phương thức thanh toán
  Widget _buildTotalSection(PosProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Coupon
            _buildCouponSection(provider),
            const SizedBox(height: 12),
            // Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền hàng:',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                Text(
                  '${formatVND(provider.cart.subtotal)}₫',
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ],
            ),
            if (provider.cart.couponCode != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giảm giá (${provider.cart.discountPercentage}%):',
                    style: TextStyle(color: Colors.green[400]),
                  ),
                  Text(
                    '-${formatVND(provider.cart.discountAmount)}₫',
                    style: TextStyle(color: Colors.green[400]),
                  ),
                ],
              ),
            ],
            const Divider(color: AppTheme.goldColor, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG THANH TOÁN:',
                  style: TextStyle(
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${formatVND(provider.cart.total)}₫',
                  style: const TextStyle(
                    color: AppTheme.goldColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nút thanh toán
            Row(
              children: [
                // Nút thanh toán tiền mặt
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: provider.cart.isEmpty
                          ? null
                          : () => _processPayment(isCash: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.green.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      icon: const Icon(Icons.money),
                      label: const Text(
                        'TIỀN MẶT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nút thanh toán VNPay
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: provider.cart.isEmpty
                          ? null
                          : () => _processPayment(isCash: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.goldColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        'VNPAY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị Coupon
  Widget _buildCouponSection(PosProvider provider) {
    if (provider.cart.couponCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer, color: Colors.green[400], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mã: ${provider.cart.couponCode} (-${provider.cart.discountPercentage}%)',
                style: TextStyle(color: Colors.green[400]),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: provider.removeCoupon,
              color: Colors.green[400],
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
      );
    }

    // Nếu không có coupon khả dụng
    if (provider.availableCoupons.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Không có mã giảm giá khả dụng',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Nút chọn coupon từ danh sách
    return InkWell(
      onTap: provider.cart.isEmpty
          ? null
          : () => _showCouponSelectionDialog(provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: AppTheme.goldColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chọn mã giảm giá (${provider.availableCoupons.length} mã)',
                style: TextStyle(
                  color: provider.cart.isEmpty
                      ? AppTheme.textSecondary
                      : AppTheme.goldColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: provider.cart.isEmpty
                  ? AppTheme.textSecondary
                  : AppTheme.goldColor,
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị dialog chọn coupon
  void _showCouponSelectionDialog(PosProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: AppTheme.goldColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Chọn mã giảm giá',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppTheme.goldColor),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.availableCoupons.length,
                  itemBuilder: (context, index) {
                    final coupon = provider.availableCoupons[index];
                    final isMinAmountMet =
                        provider.cart.subtotal >= coupon.minimumAmount;
                    return Card(
                      color: isMinAmountMet
                          ? AppTheme.primaryColor
                          : AppTheme.cardColor.withValues(alpha: 0.5),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isMinAmountMet
                                ? AppTheme.goldColor
                                : AppTheme.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${coupon.discountPercentage}%',
                            style: TextStyle(
                              color: isMinAmountMet
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          coupon.code,
                          style: TextStyle(
                            color: isMinAmountMet
                                ? AppTheme.goldColor
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (coupon.description != null)
                              Text(
                                coupon.description!,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            if (coupon.minimumAmount > 0)
                              Text(
                                'Đơn tối thiểu: ${formatVND(coupon.minimumAmount)}₫',
                                style: TextStyle(
                                  color: isMinAmountMet
                                      ? Colors.green[400]
                                      : Colors.red[400],
                                  fontSize: 12,
                                ),
                              ),
                            Text(
                              'Còn ${coupon.quantity} lượt',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: isMinAmountMet
                            ? const Icon(
                                Icons.check_circle,
                                color: AppTheme.goldColor,
                              )
                            : null,
                        onTap: isMinAmountMet
                            ? () async {
                                Navigator.pop(context);
                                final success = await provider.applyCoupon(
                                  coupon.code,
                                );
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Đã áp dụng mã ${coupon.code}!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else if (mounted && provider.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(provider.error!)),
                                  );
                                }
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Quét barcode
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanBarcodeScreen(isPosMode: true),
      ),
    );

    if (result != null && mounted) {
      final provider = Provider.of<PosProvider>(context, listen: false);
      // Tìm sản phẩm theo linear code
      final product = provider.products
          .where((p) => p.linearCode == result)
          .firstOrNull;

      if (product != null) {
        provider.addToCart(product);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã thêm: ${product.name}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy sản phẩm với mã: $result')),
        );
      }
    }
  }

  /// Hiển thị dialog thêm sản phẩm
  void _showAddProductDialog() {
    final provider = Provider.of<PosProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.goldColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Chọn sản phẩm',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _scanBarcode();
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Quét mã'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Danh sách sản phẩm
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: provider.products.length,
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.fullImageUrl != null
                          ? Image.network(
                              product.fullImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      '${formatVND(product.price)}₫ • Còn ${product.quantity}',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.goldColor,
                      ),
                      onPressed: () {
                        provider.addToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm: ${product.name}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      provider.addToCart(product);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xử lý thanh toán
  Future<void> _processPayment({required bool isCash}) async {
    final provider = Provider.of<PosProvider>(context, listen: false);

    // Kiểm tra điều kiện
    if (provider.selectedCustomer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khách hàng')));
      return;
    }

    if (provider.cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giỏ hàng trống')));
      return;
    }

    // Tạo đơn hàng với phương thức thanh toán phù hợp
    final paymentMethod = isCash ? 'Cash' : 'VnPay';
    final orderId = await provider.createOrder(paymentMethod: paymentMethod);

    if (orderId != null && mounted) {
      if (isCash) {
        // Thanh toán tiền mặt - đã được đánh dấu hoàn thành từ backend
        _showSuccessDialog(orderId, 'Tiền mặt');
        provider.reset();
        provider.selectGuestCustomer();
      } else {
        // Thanh toán VNPay
        final payUrl = await provider.createVnPayPayment(orderId);
        if (payUrl != null && mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                paymentUrl: payUrl,
                title: 'Thanh toán VNPay',
              ),
            ),
          );

          if (!mounted) return;

          if (result != null && result is Map) {
            final status = result['status'];
            if (status == 'success') {
              _showSuccessDialog(orderId, 'VNPay');
              provider.reset();
              provider.selectGuestCustomer();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thanh toán thất bại: $status'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else if (mounted && provider.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(provider.error!)));
        }
      }
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  void _showSuccessDialog(int orderId, String paymentMethod) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuccessDialog(
        orderId: orderId,
        paymentMethod: paymentMethod,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
