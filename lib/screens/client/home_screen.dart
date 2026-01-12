import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';
import '../../models/product.dart';
import '../../models/coupon.dart';
import 'product/product_detail_screen.dart';
import 'order/order_history_screen.dart';
import 'cart/cart_screen.dart';
import '../../config/api_config.dart';
import 'profile/profile_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  bool _isInit = true;

  // For sticky app bar effect
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    // Lắng nghe sự kiện cuộn để thay đổi trạng thái sticky header
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  // Tải dữ liệu ban đầu
  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final couponProvider = Provider.of<CouponProvider>(
        context,
        listen: false,
      );
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      Future.wait([
        productProvider.fetchCategories(),
        productProvider.fetchProducts(),
        couponProvider.fetchCoupons(),
      ]).then((_) {
        // Fetch cart only if authenticated
        if (authProvider.isAuthenticated) {
          cartProvider.fetchCart();
        }
      });

      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Darker grey background
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                final productProvider = Provider.of<ProductProvider>(
                  context,
                  listen: false,
                );
                final cartProvider = Provider.of<CartProvider>(
                  context,
                  listen: false,
                );
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                await productProvider.fetchProducts();
                if (authProvider.isAuthenticated) {
                  await cartProvider.fetchCart();
                }
              },
              color: AppTheme.goldColor,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Placeholder for AppBar space
                  const SliverToBoxAdapter(child: SizedBox(height: 70)),

                  // 1. Banner Section (Carousel)
                  SliverToBoxAdapter(child: _buildBanner()),

                  // 2. [REMOVED] Quick Action Icons (Categories/Services)

                  // 3. Voucher/Coupons Section
                  SliverToBoxAdapter(child: _buildCouponSection()),

                  // 4. Featured/Flash Sale Header (Simulated)
                  SliverToBoxAdapter(child: _buildFlashSaleHeader()),

                  // 5. Sticky Category Filter
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverCategoryHeaderDelegate(
                      child: _buildCategories(),
                    ),
                  ),

                  // 6. Product Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    sliver: _buildProductGrid(),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
            // Floating Custom AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildStickyAppBar(context),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  // Thanh điều hướng cố định (Sticky AppBar)
  Widget _buildStickyAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor, // Black background
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final isAuthenticated = authProvider.isAuthenticated;
          return Row(
            children: [
              // Search Bar
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Cart Icon
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppTheme.goldColor,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                  ),
                  if (isAuthenticated)
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return cartProvider.itemCount > 0
                            ? Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    '${cartProvider.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                ],
              ),

              if (isAuthenticated) ...[
                IconButton(
                  icon: const Icon(
                    Icons.receipt_long, // Icon for Order History
                    color: AppTheme.goldColor,
                  ),
                  tooltip: 'Đơn hàng của tôi',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.person, // Icon for Profile
                    color: AppTheme.goldColor,
                  ),
                  tooltip: 'Thông tin tài khoản',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ] else
                IconButton(
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: AppTheme.goldColor,
                  ),
                  tooltip: 'Đăng nhập',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  // Banner quảng cáo (Carousel)
  Widget _buildBanner() {
    final banners = [
      'assets/images/banner_1.jpg',
      'assets/images/banner_2.jpg',
      'assets/images/banner_3.jpg',
    ];
    // In production, use real image URLs or assets

    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.black12,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          // Placeholder gradient if image not found
          return Container(
            decoration: BoxDecoration(
              gradient: AppTheme.darkGradient,
              image: DecorationImage(
                image: AssetImage(banners[index]),
                fit: BoxFit.cover,
                onError: (e, s) => null, // Fallback to gradient
              ),
            ),
            child: const Center(
              // REMOVED 'PREMIUM COLLECTION' TEXT
            ),
          );
        },
        itemCount: banners.length,
        autoplay: true,
        pagination: const SwiperPagination(
          builder: DotSwiperPaginationBuilder(
            activeColor: AppTheme.goldColor,
            color: Colors.white54,
            size: 8,
            activeSize: 10,
          ),
        ),
      ),
    );
  }

  // Removed _buildServiceIcons and replaced with Coupon Section in build method.

  // Khu vực hiển thị mã giảm giá (Voucher)
  Widget _buildCouponSection() {
    return Consumer<CouponProvider>(
      builder: (context, couponProvider, _) {
        // Use real coupons or fallback to dummy 'Hot' coupons for display if empty
        final coupons = couponProvider.coupons.isNotEmpty
            ? couponProvider.coupons
            : [
                Coupon(
                  id: 991,
                  code: 'HOT50',
                  discountPercentage: 50,
                  minimumAmount: 500000,
                  quantity: 100,
                  expiryDate: DateTime.now().add(const Duration(days: 7)),
                ),
                Coupon(
                  id: 992,
                  code: 'FREESHIP',
                  discountPercentage: 15,
                  minimumAmount: 200000,
                  quantity: 50,
                  expiryDate: DateTime.now().add(const Duration(days: 7)),
                ),
                Coupon(
                  id: 993,
                  code: 'NEWMEMBER',
                  discountPercentage: 20,
                  minimumAmount: 0,
                  quantity: 999,
                  expiryDate: DateTime.now().add(const Duration(days: 30)),
                ),
              ];

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.local_fire_department,
                    color: AppTheme.goldColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Voucher Hot',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.goldColor,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Xem thêm >',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: coupons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.goldColor.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldColor.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.goldColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '%',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  coupon.code,
                                  style: const TextStyle(
                                    color: AppTheme.goldColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Giảm ${coupon.discountPercentage}%',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Đơn từ ${NumberFormat.compact().format(coupon.minimumAmount)}đ',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Lưu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  // Tiêu đề Flash Sale / Gợi ý
  Widget _buildFlashSaleHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.goldColor,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'GỢI Ý',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'DÀNH RIÊNG CHO BẠN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách danh mục sản phẩm (sắp xếp ngang)
  Widget _buildCategories() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.categories.isEmpty) return const SizedBox.shrink();

        final categories = [
          Category(id: -1, name: 'Tất cả'),
          ...productProvider.categories,
        ];

        return Container(
          height: 50,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategoryId == null
                  ? category.id == -1
                  : category.id == _selectedCategoryId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id == -1
                        ? null
                        : category.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppTheme.goldColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.goldColor : Colors.black54,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Lưới hiển thị sản phẩm
  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        // Check if loading
        if (productProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.goldColor),
              ),
            ),
          );
        }

        if (productProvider.products.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'Không kết nối được máy chủ hoặc chưa có sản phẩm',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showConfigDialog(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Cấu hình Server IP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Filtering logic
        final products = productProvider.products.where((p) {
          final matchesCategory =
              _selectedCategoryId == null ||
              p.categoryId == _selectedCategoryId;
          final matchesSearch =
              _searchQuery.isEmpty ||
              p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.62,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildDenseProductCard(products[index]),
            childCount: products.length,
          ),
        );
      },
    );
  }

  // Thẻ hiển thị thông tin sản phẩm thu gọn
  Widget _buildDenseProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (context) {
                        final imageUrl = product.fullImageUrl;
                        if (imageUrl != null) {
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return Image.asset(
                          'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  // "Mall" or "Premium" Badge
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      color: AppTheme.goldColor,
                      child: const Text(
                        'Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Discount Badge (Simulated)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      color: const Color(
                        0xFFFFD424,
                      ).withOpacity(0.9), // Yellowish
                      padding: const EdgeInsets.all(2),
                      child: const Column(
                        children: [
                          Text(
                            '20%',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'GIẢM',
                            style: TextStyle(color: Colors.white, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  // Tag / Voucher badge simulated
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.goldColor),
                    ),
                    child: const Text(
                      'Voucher 50k',
                      style: TextStyle(fontSize: 9, color: AppTheme.goldColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                        ).format(product.price),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Đã bán 1.2k',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog cấu hình IP Server (dùng cho debug/demo)
  void _showConfigDialog(BuildContext context) {
    final ipController = TextEditingController(text: ApiConfig.hostIP);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Máy Tính (Server)',
                hintText: 'ví dụ: 192.168.1.5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nhập địa chỉ IP của máy tính đang chạy phần mềm (Backend).\nĐiện thoại và máy tính phải kết nối cùng một mạng WiFi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.updateHostIP(ipController.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('IP Updated! Please swipe down to refresh.'),
                  ),
                );
                // Trigger refresh
                Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ).fetchProducts();
                Provider.of<ProductProvider>(
                  context,
                  listen: false,
                ).fetchCategories();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Delegate for Sticky Header
class _SliverCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverCategoryHeaderDelegate({required this.child});

  @override
  double get minExtent => 50.0;
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          if (overlapsContent)
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverCategoryHeaderDelegate oldDelegate) {
    return true;
  }
}
