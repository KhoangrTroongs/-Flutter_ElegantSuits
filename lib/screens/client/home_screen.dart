import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/coupon_provider.dart';
import '../auth/login_screen.dart';
import '../../models/product.dart';
import '../../models/coupon.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      // Fetch data
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final couponProvider = Provider.of<CouponProvider>(
        context,
        listen: false,
      );

      Future.wait([
        productProvider.fetchCategories(),
        productProvider.fetchProducts(),
        couponProvider.fetchCoupons(),
      ]);

      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('ELEGANT SUITS'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.goldColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              // Navigate to Cart
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final productProvider = Provider.of<ProductProvider>(
            context,
            listen: false,
          );
          final couponProvider = Provider.of<CouponProvider>(
            context,
            listen: false,
          );
          await Future.wait([
            productProvider.fetchCategories(),
            productProvider.fetchProducts(),
            couponProvider.fetchCoupons(),
          ]);
        },
        color: AppTheme.goldColor,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildCouponSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            _buildFeaturedProductsHeading(),
            _buildProductSections(),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
            SliverToBoxAdapter(child: _buildFooter()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final banners = [
      {
        'title': 'Cửa hàng\náo Vest.',
        'subtitle':
            'Tổng hợp nhiều loại suit phù hợp cho từng mục đích của bạn.',
        'button': 'Khám phá ngay',
        'image': 'assets/images/wall.jpg', // Placeholder logic inside
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Nhận\nđặt may.',
        'subtitle':
            'Lựa chọn kiểu dáng, loại vải, màu sắc phù hợp với mục đích của bạn.',
        'button': 'Liên hệ ngay',
        'image': 'assets/images/wall4.jpg',
        'color': AppTheme.primaryDark,
      },
      {
        'title': 'Dịch vụ\ncho thuê.',
        'subtitle': 'Bạn muốn tiết kiệm chi phí, đến với chúng tôi.',
        'button': 'Xem chi tiết',
        'image': 'assets/images/wall3.jpg',
        'color': const Color(0xFF0D0D0D),
      },
    ];

    return SizedBox(
      height: 250,
      child: Swiper(
        itemBuilder: (BuildContext context, int index) {
          final banner = banners[index];
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (banner['color'] as Color),
                  (banner['color'] as Color).withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Pattern overlay (optional)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: GridPaper(
                      color: AppTheme.goldColor,
                      divisions: 2,
                      subdivisions: 2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner['title'] as String,
                        style: const TextStyle(
                          color: AppTheme.goldColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 250,
                        child: Text(
                          banner['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldColor,
                          foregroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(banner['button'] as String),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        itemCount: banners.length,
        pagination: const SwiperPagination(
          builder: DotSwiperPaginationBuilder(
            activeColor: AppTheme.goldColor,
            color: Colors.grey,
          ),
        ),
        autoplay: true,
        autoplayDelay: 5000,
      ),
    );
  }

  Widget _buildCouponSection() {
    return Consumer<CouponProvider>(
      builder: (context, couponProvider, _) {
        if (couponProvider.coupons.isEmpty) return const SizedBox.shrink();

        // Chỉ hiện coupon còn hạn và còn số lượng (giả sử logic lọc ở đây)
        final activeCoupons = couponProvider.coupons;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldDark.withValues(alpha: 0.1),
                    AppTheme.goldLight.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: const Center(
                child: Text(
                  'DEAL SỐC CÙNG VOUCHER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: activeCoupons.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) {
                  return _buildCouponCard(activeCoupons[i]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                bottomLeft: Radius.circular(11),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.confirmation_number_outlined,
                color: AppTheme.goldColor,
                size: 32,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Giảm ${coupon.discountPercentage}%',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coupon.description ??
                        'Cho đơn hàng từ ${NumberFormat.compact().format(coupon.minimumAmount)}đ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SL: ${coupon.quantity == -1 ? '∞' : coupon.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép mã!')),
                          );
                        },
                        child: Text(
                          coupon.code,
                          style: const TextStyle(
                            color: AppTheme.goldDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProductsHeading() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Sản phẩm nổi bật',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 60, height: 3, color: AppTheme.goldColor),
            const SizedBox(height: 8),
            const Text(
              'Khám phá bộ sưu tập mới nhất của chúng tôi',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSections() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.goldColor),
            ),
          );
        }

        if (productProvider.categories.isEmpty) {
          // If no categories, try to show all products if any
          if (productProvider.products.isNotEmpty) {
            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Tất cả sản phẩm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: productProvider.products.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                      itemBuilder: (ctx, i) {
                        return _buildProductCard(productProvider.products[i]);
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final category = productProvider.categories[index];
            // Filter products for this category
            final categoryProducts = productProvider.products
                .where((p) => p.categoryId == category.id)
                .take(10) // Limit to 10
                .toList();

            if (categoryProducts.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryProducts.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                    itemBuilder: (ctx, i) {
                      return _buildProductCard(categoryProducts[i]);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }, childCount: productProvider.categories.length),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Builder(
                builder: (context) {
                  final imageUrl = product.fullImageUrl;
                  // Debug print URL
                  // print('Product ID: ${product.id}, URL: $imageUrl');

                  if (imageUrl != null) {
                    return CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) {
                        // Debug print error
                        debugPrint(
                          'Error loading image for product ${product.id}: $url',
                        );
                        debugPrint('Error details: $error');
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Error',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                          Text(
                            'No Image',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'đ',
                  ).format(product.price),
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          const Icon(
            Icons.diamond_outlined,
            color: AppTheme.goldColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'ELEGANT SUITS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đẳng cấp quý ông',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.goldColor),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.camera_alt), // Instagram alternative
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.email),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '© 2024 Elegant Suits. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.goldColor),
      ),
      child: Icon(icon, color: AppTheme.goldColor, size: 20),
    );
  }
}
