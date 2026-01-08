import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/cart_provider.dart';
import '../../../models/api_cart.dart';
import '../../../config/api_config.dart';
import '../../../services/api_service.dart';

import '../../../providers/coupon_provider.dart';
import '../../../models/coupon.dart';
import '../payment/payment_webview_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch cart when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  // Checkout logic variables
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  String _selectedPaymentMethod = 'COD';

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _initiateVnPay(BuildContext context, int orderId) async {
    try {
      final response = await ApiService.post(
        ApiConfig.paymentVnPayCreate(orderId),
        {},
      );

      final data = ApiService.parseResponse(response);

      if (data is Map &&
          (data['success'] == true ||
              data['isSuccess'] == true ||
              data['IsSuccess'] == true)) {
        final paymentUrl = data['payUrl'] ?? data['data'] ?? data['Data'];

        if (paymentUrl != null) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewScreen(
                paymentUrl: paymentUrl,
                title: 'Thanh toán VNPay',
              ),
            ),
          );

          if (!mounted) return;

          if (result != null && result is Map) {
            final status = result['status'];
            if (status == 'success') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thanh toán thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Thanh toán thất bại hoặc bị hủy. Lỗi: $status',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Fallback if URL is null
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tạo liên kết thanh toán VNPay.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Cannot create VNPay payment');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi VNPay: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Currency format
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Giỏ hàng',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.cart == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.cart == null || cartProvider.cart!.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Giỏ hàng của bạn đang trống',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'TIẾP TỤC MUA SẮM',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }

          final cart = cartProvider.cart!;

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItem(
                      context,
                      item,
                      cartProvider,
                      currencyFormat,
                    );
                  },
                ),
              ),
              // Bottom Checkout Bar
              _buildBottomBar(context, cart, currencyFormat),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    ApiCartItem item,
    CartProvider provider,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              '${ApiConfig.imageBaseUrl}${item.imageUrl}',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (item.size != null && item.size!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Size: ${item.size}',
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  format.format(item.price),
                  style: const TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // Actions (Qty & Remove)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () {
                  _showRemoveConfirmDialog(context, provider, item.id);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildQtyBtn(Icons.remove, () {
                    if (item.quantity > 1) {
                      provider.updateCartItem(item.id, item.quantity - 1);
                    }
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _buildQtyBtn(Icons.add, () {
                    provider.updateCartItem(item.id, item.quantity + 1);
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ApiCart cart,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  format.format(cart.totalPrice),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _showCheckoutModal(context, cart, format),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 5,
                  shadowColor: Colors.black38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'TIẾN HÀNH THANH TOÁN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutModal(
    BuildContext context,
    ApiCart cart,
    NumberFormat format,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Thông tin đặt hàng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Address
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ giao hàng',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Coupon
                    // Coupon
                    TextField(
                      controller: _couponController,
                      readOnly: true,
                      onTap: () =>
                          _showCouponSelection(context, cart, (selectedCode) {
                            setState(() {
                              _couponController.text = selectedCode;
                            });
                          }),
                      decoration: InputDecoration(
                        labelText: 'Mã giảm giá (nếu có)',
                        hintText: 'Chọn mã giảm giá',
                        prefixIcon: const Icon(Icons.discount_outlined),
                        suffixIcon: _couponController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _couponController.clear();
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        prefixIcon: const Icon(Icons.note_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Payment Methods
                    _buildPaymentOption(
                      'COD',
                      'Thanh toán khi nhận hàng',
                      setState,
                    ),
                    _buildPaymentOption(
                      'VnPay',
                      'Thanh toán qua VNPay',
                      setState,
                    ),
                    const SizedBox(height: 20),
                    // Place Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_addressController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Vui lòng nhập địa chỉ giao hàng',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context); // Close modal
                          _showOrderReview(context, cart, format);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ĐẶT HÀNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOption(String value, String title, StateSetter setState) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _selectedPaymentMethod,
      activeColor: Colors.black,
      contentPadding: EdgeInsets.zero,
      onChanged: (String? val) {
        if (val != null) {
          setState(() {
            _selectedPaymentMethod = val;
          });
        }
      },
    );
  }

  void _showOrderReview(
    BuildContext context,
    ApiCart cart,
    NumberFormat format,
  ) {
    // Calculate discounts
    double discountAmount = 0;
    if (_couponController.text.isNotEmpty) {
      final couponProvider = Provider.of<CouponProvider>(
        context,
        listen: false,
      );
      try {
        final coupon = couponProvider.coupons.firstWhere(
          (c) => c.code == _couponController.text,
        );
        if (cart.totalPrice >= coupon.minimumAmount) {
          discountAmount = cart.totalPrice * coupon.discountPercentage / 100;
        }
      } catch (_) {}
    }

    final finalTotal = cart.totalPrice - discountAmount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // For custom rounded aesthetic
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'XÁC NHẬN ĐƠN HÀNG',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Customer Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildReviewRow(
                              Icons.person,
                              'Người nhận',
                              'Khách hàng',
                            ),
                            const SizedBox(height: 12),
                            _buildReviewRow(
                              Icons.location_on,
                              'Địa chỉ',
                              _addressController.text,
                            ),
                            const SizedBox(height: 12),
                            _buildReviewRow(Icons.phone, 'SĐT', '---'),
                            if (_noteController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildReviewRow(
                                Icons.note,
                                'Ghi chú',
                                _noteController.text,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Payment Method
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: _buildReviewRow(
                          Icons.payment,
                          'Thanh toán',
                          _selectedPaymentMethod == 'COD'
                              ? 'Khi nhận hàng (COD)'
                              : 'VNPay',
                          valueColor: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Order Items
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sản phẩm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                  image: item.imageUrl.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(item.imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.image,
                                        size: 24,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Size: ${item.size ?? "N/A"} | x${item.quantity}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                format.format(item.price * item.quantity),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Totals
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      _buildSummaryRow(
                        'Tạm tính',
                        format.format(cart.totalPrice),
                        false,
                      ),
                      if (discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Giảm giá (${_couponController.text})',
                          '-${format.format(discountAmount)}',
                          false,
                          color: Colors.green,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Tổng cộng',
                        format.format(finalTotal),
                        true,
                        color: Colors.red,
                        fontSize: 20,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close review modal
                    _processCheckout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'XÁC NHẬN ĐẶT HÀNG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isBold, {
    Color? color,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _processCheckout(BuildContext context) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    try {
      final result = await cartProvider.checkout(
        shippingAddress: _addressController.text,
        notes: _noteController.text,
        couponCode: _couponController.text,
        paymentMethod: _selectedPaymentMethod,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        if (_selectedPaymentMethod == 'VnPay') {
          // Note: In a real app, you would handle the redirect URL here if provided only by Order response
          // But usually VNPay flow might require a separate call or the CreateOrder returns the URL.
          // Our CreateOrder implementation returns the Order object.
          // We might need to call PaymentApi/vnpay/create/{orderId} separately?
          // Let's check api_config.
          // api_config has: paymentVnPayCreate(int orderId)

          final orderData = result['data'];
          final orderId = orderData['id'] ?? orderData['Id'];

          // Call VNPay API
          await _initiateVnPay(context, orderId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt hàng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home or order list
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Đặt hàng thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showRemoveConfirmDialog(
    BuildContext context,
    CartProvider provider,
    int cartItemId,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa sản phẩm này khỏi giỏ hàng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeCartItem(cartItemId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCouponSelection(
    BuildContext context,
    ApiCart cart,
    Function(String) onSelect,
  ) {
    Provider.of<CouponProvider>(context, listen: false).fetchCoupons();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chọn mã giảm giá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<CouponProvider>(
                  builder: (context, couponProvider, child) {
                    if (couponProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final coupons = couponProvider.coupons;

                    if (coupons.isEmpty) {
                      return const Center(
                        child: Text(
                          'Không có mã giảm giá nào.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: coupons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final coupon = coupons[index];
                        final isExpired = coupon.expiryDate != null
                            ? coupon.expiryDate!.isBefore(DateTime.now())
                            : false;
                        final isOutOfStock = coupon.quantity == 0;
                        final isMinAmountMet =
                            cart.totalPrice >= coupon.minimumAmount;

                        final isValid =
                            !isExpired && !isOutOfStock && isMinAmountMet;

                        return Opacity(
                          opacity: isValid ? 1.0 : 0.5,
                          child: InkWell(
                            onTap: isValid
                                ? () {
                                    onSelect(coupon.code);
                                    Navigator.pop(context);
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isValid
                                      ? Colors.orange.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isValid
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.local_offer,
                                    color: isValid
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  coupon.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giảm ${coupon.discountPercentage}%',
                                      style: TextStyle(
                                        color: isValid
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (coupon.description != null)
                                      Text(
                                        coupon.description!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (!isMinAmountMet)
                                      Text(
                                        'Đơn tối thiểu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(coupon.minimumAmount)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                        ),
                                      ),
                                    if (isExpired)
                                      const Text(
                                        'Đã hết hạn',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Radio<String>(
                                  value: coupon.code,
                                  groupValue: _couponController.text,
                                  activeColor: Colors.orange,
                                  onChanged: isValid
                                      ? (value) {
                                          if (value != null) {
                                            onSelect(value);
                                            Navigator.pop(context);
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
}
