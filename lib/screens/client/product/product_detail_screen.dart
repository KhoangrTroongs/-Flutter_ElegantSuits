import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_elegant_suits/models/product.dart';
import 'package:app_elegant_suits/config/app_theme.dart';
import 'package:app_elegant_suits/services/api_service.dart';
import 'package:app_elegant_suits/config/api_config.dart';
import 'package:app_elegant_suits/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:app_elegant_suits/providers/auth_provider.dart';
import 'package:app_elegant_suits/providers/cart_provider.dart';
import 'package:app_elegant_suits/screens/client/cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product; // Nullable to handle hot reload safely
  String? _selectedSize;
  int _quantity = 1;
  Map<String, int> _availableSizes = {};
  List<Map<String, dynamic>> _reviews = [];
  String _cleanDescription = '';

  Product get product => _product ?? widget.product; // Safe getter

  @override
  void initState() {
    super.initState();
    // Start with widget.product but fetch fresh data immediately
    // _product will be initialized in didChangeDependencies if null
    _fetchProductDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_product == null) {
      _product = widget.product;
      _parseDescription();
    }
  }

  Future<void> _fetchProductDetails() async {
    try {
      final response = await ApiService.get(
        ApiConfig.productById(widget.product.id),
      );
      final data = ApiService.parseResponse(response);

      if (data['isSuccess'] == true || data['IsSuccess'] == true) {
        print(
          "DEBUG: API Response Data: ${data['Data'] ?? data['data']}",
        ); // Logging
        if ((data['Data'] != null || data['data'] != null) && mounted) {
          setState(() {
            _product = Product.fromJson(data['Data'] ?? data['data']);
            print(
              "DEBUG: Product Description: ${_product?.description}",
            ); // Logging
            _parseDescription();
          });
        }
      }
    } catch (e) {
      print("Error fetching product details: $e");
    }
  }

  void _parseDescription() {
    final product = _product ?? widget.product;
    String description = product.description; // Use local product

    print('DEBUG: Parsing description for product ${product.id}');
    print('DEBUG: Raw description length: ${description.length}');
    // print('DEBUG: Raw description: $description'); // Uncomment if needed, can be long

    _availableSizes.clear();
    _reviews.clear();

    // Parse Sizes
    final sizeTag = "[SIZES]";
    final endSizeTag = "[/SIZES]";
    if (description.contains(sizeTag) && description.contains(endSizeTag)) {
      final startIndex = description.indexOf(sizeTag) + sizeTag.length;
      final endIndex = description.indexOf(endSizeTag);
      if (startIndex < endIndex) {
        final sizeSection = description.substring(startIndex, endIndex);
        final sizePairs = sizeSection.split(',');
        for (var pair in sizePairs) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final size = parts[0].trim();
            final qty = int.tryParse(parts[1]) ?? 0;
            if (qty > 0) {
              // Only add available sizes
              _availableSizes[size] = qty;
            }
          }
        }
        // Remove size tag from description
        description = description.replaceRange(
          description.indexOf(sizeTag),
          description.indexOf(endSizeTag) + endSizeTag.length,
          '',
        );
      }
    } else {
      // Fallback: Nếu không tìm thấy tag [SIZES], tạo size mặc định nếu sản phẩm còn hàng
      // Giả lập size S, M, L, XL, XXL với số lượng bằng tổng số lượng sản phẩm (kho chung)
      if (product.quantity > 0) {
        final defaultSizes = ['S', 'M', 'L', 'XL', 'XXL'];
        for (var size in defaultSizes) {
          _availableSizes[size] = product.quantity;
        }
      }
    }

    // Parse Reviews
    final reviewTag = "[REVIEWS]";
    final endReviewTag = "[/REVIEWS]";

    print(
      'DEBUG: Contains Review Tags? ${description.contains(reviewTag)} && ${description.contains(endReviewTag)}',
    );

    if (description.contains(reviewTag) && description.contains(endReviewTag)) {
      final startIndex = description.indexOf(reviewTag) + reviewTag.length;
      final endIndex = description.indexOf(endReviewTag);
      print('DEBUG: Review indices: $startIndex to $endIndex');

      if (startIndex < endIndex) {
        final reviewSection = description.substring(startIndex, endIndex);
        print('DEBUG: Review Section: $reviewSection');

        final reviewPairs = reviewSection.split('|');
        print('DEBUG: Found ${reviewPairs.length} potential reviews');

        for (var pair in reviewPairs) {
          if (pair.isEmpty) continue;
          final parts = pair.split('~~');
          print('DEBUG: Parsing pair: $pair -> ${parts.length} parts');

          if (parts.length >= 5) {
            _reviews.add({
              'userId': parts[0],
              'userName': parts[1],
              'rating': double.tryParse(parts[2]) ?? 5.0,
              'date': DateTime.tryParse(parts[3]) ?? DateTime.now(),
              'comment': parts[4],
            });
          }
        }
        // Remove review tag from description
        description = description.replaceRange(
          description.indexOf(reviewTag),
          description.indexOf(endReviewTag) + endReviewTag.length,
          '',
        );
      }
    }

    _cleanDescription = description.trim();
    print('DEBUG: Parsed ${_reviews.length} reviews');
  }

  Future<void> _submitReview(int rating, String comment) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await ApiService.getToken();

      if (token == null || authProvider.user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      // Convert non-string values to string for form data
      final Map<String, String> fields = {
        'userId': authProvider.user!.id,
        'productId': product.id.toString(),
        'rating': rating.toString(),
        'comment': comment,
      };

      print('DEBUG: Submitting review with fields: $fields');

      final response = await ApiService.putForm(
        ApiConfig.productReview,
        fields,
      );

      final data = ApiService.parseResponse(response);
      print('DEBUG: Review Submit Response: $data');

      bool isSuccess = false;
      String message = 'Unknown error';

      if (data is Map) {
        if (data['isSuccess'] == true || data['IsSuccess'] == true) {
          isSuccess = true;
        }
        message =
            data['message'] ?? data['Message'] ?? 'Failed to submit review';
      } else if (data is String) {
        if (data.toLowerCase().contains('success')) {
          isSuccess = true;
        }
        message = data;
      }

      if (isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
          );

          Navigator.pop(context); // Pop dialog first

          // Force refresh from API
          await _fetchProductDetails();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: $e')),
              ],
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showReviewDialog() async {
    final token = await ApiService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Viết đánh giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => selectedRating = index + 1),
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Nhập bình luận của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                _submitReview(selectedRating, commentController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Gửi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar:
          true, // Allow body to go behind app bar for transparent effect initially
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image Section (Fixed height propotional to screen)
                  Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: double.infinity,
                    color: const Color(
                      0xFFF5F5F5,
                    ), // Light gray background for contrast
                    child: product.fullImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.fullImageUrl!,
                            fit: BoxFit.contain, // SHOW FULL IMAGE
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, size: 50),
                          )
                        : const Icon(Icons.image_not_supported, size: 100),
                  ),

                  // 2. Details Section (Overlapping slightly or just below?)
                  // Let's keep it simple: Just below.
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    transform: Matrix4.translationValues(
                      0,
                      -20,
                      0,
                    ), // Slight overlap for style
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar visual
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        _buildHeader(),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        _buildSizeSelector(),

                        // If we have sizes but none selected, show error hint? No, just the selector.
                        // Only show spacer if selector is visible
                        if (_availableSizes.isNotEmpty)
                          const SizedBox(height: 24),

                        _buildDescription(),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        _buildReviews(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Bar stays pinned at bottom
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isAvailable = product.quantity > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  fontFamily:
                      'PlayfairDisplay', // Suggested serif if available, else standard
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAvailable
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAvailable ? 'Còn hàng' : 'Hết hàng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          currencyFormat.format(product.price),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.categoryName ?? 'Category',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    if (_availableSizes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Sản phẩm này hiện chưa có thông tin kích cỡ chi tiết.",
                style: TextStyle(color: Colors.orange[800]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Chọn kích cỡ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (product.linearCode != null) // Mock size guide link
              Text(
                "Bảng quy đổi kích cỡ",
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableSizes.entries.map((entry) {
            final size = entry.key;
            final qty = entry.value;
            final isSelected = _selectedSize == size;
            final isOutOfStock = qty <= 0;

            return GestureDetector(
              onTap: isOutOfStock
                  ? null
                  : () {
                      setState(() {
                        // Toggle selection if needed, or just select
                        _selectedSize = size;
                        if (_quantity > qty) _quantity = qty;
                      });
                    },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isOutOfStock ? Colors.grey[100] : Colors.white),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isOutOfStock
                              ? Colors.grey[200]!
                              : Colors.grey.shade400),
                    width: isSelected ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      size,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isOutOfStock ? Colors.grey : Colors.black87),
                        decoration: isOutOfStock
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (isSelected)
                      Text(
                        "SL: $qty",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    if (_cleanDescription.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mô tả sản phẩm",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _cleanDescription,
          style: const TextStyle(color: Colors.black87, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    if (_reviews.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Đánh giá",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "Chưa có đánh giá nào",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showReviewDialog,
                  child: const Text("Viết đánh giá đầu tiên"),
                ),
              ],
            ),
          ),
        ],
      );
    }

    double avgRating =
        _reviews.map((r) => r['rating'] as double).reduce((a, b) => a + b) /
        _reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Đánh giá",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              "${avgRating.toStringAsFixed(1)}/5.0",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              " (${_reviews.length} đánh giá)",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Spacer(),
            TextButton(
              onPressed: _showReviewDialog,
              child: const Text("Viết đánh giá"),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length, // Show all reviews for now
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final review = _reviews[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (review['userName'] as String).isNotEmpty
                              ? (review['userName'] as String)[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['userName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review['rating']
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 14,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy').format(review['date']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (review['comment'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      review['comment'],
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addToCart() async {
    final token = await ApiService.getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để mua hàng')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
      return;
    }

    if (_availableSizes.isNotEmpty && _selectedSize == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn kích cỡ')));
      }
      return;
    }

    try {
      await Provider.of<CartProvider>(
        context,
        listen: false,
      ).addToCart(product.id, _quantity, _selectedSize);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã thêm vào giỏ hàng thành công!'),
            action: SnackBarAction(
              label: 'XEM GIỎ',
              textColor: AppTheme.goldColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('401')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'),
            ),
          );
          // Optional: Logout to clear state
          // Provider.of<AuthProvider>(context, listen: false).logout();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Widget _buildBottomBar() {
    // Check stock status
    bool isOutOfStock = product.quantity <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _quantity > 1 && !isOutOfStock
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: !isOutOfStock
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isOutOfStock
                    ? null
                    : (_availableSizes.isNotEmpty && _selectedSize == null
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chọn kích cỡ'),
                                ),
                              );
                            }
                          : _addToCart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock
                      ? Colors.grey
                      : AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isOutOfStock ? "Hết hàng" : "Thêm vào giỏ hàng",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.white54 : AppTheme.goldColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
