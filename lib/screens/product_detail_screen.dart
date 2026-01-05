import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/models/review.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/services/review_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/widgets/add_review_dialog.dart';
import 'package:clothesapp/widgets/review_card.dart';
import 'package:clothesapp/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String token;
  final Map<String, dynamic> user;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.token,
    required this.user,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final UserService _userService = UserService();
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();

  bool isFavorite = false;
  int quantity = 1;
  bool isAddingToCart = false;
  String? selectedSize;
  String? selectedColor;

  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  List<Product> _recommendations = [];
  bool _isLoadingRecommendations = true;
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _checkIsFavorite();
    _loadReviews();
    _loadRecommendations();
  }

  void _checkIsFavorite() async {
    // 1. Initial check with passed data
    _processFavorites(widget.user['favorites']);

    // 2. Fetch fresh data from server to be sure
    final freshProfile = await _userService.getProfile(widget.token);
    if (freshProfile != null && mounted) {
      _processFavorites(freshProfile['favorites']);
    }
  }

  void _processFavorites(dynamic favorites) {
    if (favorites is List) {
      bool found = false;
      for (var item in favorites) {
        if (item is String && item == widget.product.id) {
          found = true;
          break;
        }
        if (item is Map && item['_id'] == widget.product.id) {
          found = true;
          break;
        }
      }
      setState(() {
        isFavorite = found;
      });
    }
  }

  void _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    final reviews = await _reviewService.getReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  void _loadRecommendations() async {
    setState(() => _isLoadingRecommendations = true);
    final recommendations = await _productService.getRecommendations(
      widget.product.id,
    );
    if (mounted) {
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    }
  }

  void _reloadProduct() async {
    final products = await _productService.getProducts();
    final updatedProduct = products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );
    if (mounted) {
      setState(() {
        _currentProduct = updatedProduct;
      });
    }
  }

  void _showAddReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        onSubmit: (rating, comment) async {
          final success = await _reviewService.addReview(
            widget.product.id,
            rating,
            comment,
            widget.token,
          );
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đánh giá thành công!')),
            );
            _loadReviews();
            _reloadProduct();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi khi gửi đánh giá')),
            );
          }
        },
      ),
    );
  }

  void _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reviewService.deleteReview(
        review.id,
        widget.token,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa đánh giá')));
        _loadReviews();
        _reloadProduct();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa đánh giá này')),
        );
      }
    }
  }

  bool _hasReviewed() {
    return _reviews.any((review) => review.userId == widget.user['_id']);
  }

  void _addToCart() async {
    if (selectedColor == null || selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn màu sắc và kích thước")),
      );
      return;
    }

    setState(() => isAddingToCart = true);
    final success = await _userService.addToCart(
      widget.product.id,
      quantity,
      selectedColor!,
      selectedSize!,
      widget.token,
    );
    if (!mounted) return;
    setState(() => isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã thêm vào giỏ hàng!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi thêm vào giỏ hàng!")));
    }
  }

  void _toggleFavorite() async {
    setState(() => isFavorite = !isFavorite);
    await _userService.toggleFavorite(widget.product.id, widget.token);
  }

  String? _getSelectedVariantPrice() {
    if (selectedColor != null && selectedSize != null) {
      final variant = _currentProduct.variants.firstWhere(
        (v) => v.color == selectedColor && v.size == selectedSize,
        orElse: () => _currentProduct.variants.first,
      );
      return NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
      ).format(variant.sellingPrice);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 500,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${_currentProduct.id}',
                child: Image.network(
                  _currentProduct.fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.parallax,
            ),
            leading: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.4),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              const SizedBox(width: 12),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentProduct.category.toUpperCase(),
                      style: GoogleFonts.outfit(
                        letterSpacing: 2,
                        color: theme.colorScheme.primary, // Gold
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentProduct.name,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _getSelectedVariantPrice() ?? _currentProduct.priceRange,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentProduct.averageRating > 0
                                ? _currentProduct.averageRating.toStringAsFixed(
                                    1,
                                  )
                                : "N/A",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " (${_currentProduct.reviewCount} đánh giá)",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  "Mô tả",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentProduct.description.isEmpty
                      ? "Không có mô tả cho sản phẩm này."
                      : _currentProduct.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                Divider(color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 24),
                ...(_renderColorSection(theme)),
                ...(_renderSizeSection(theme)),
                const SizedBox(height: 48),
                _buildRecommendationsSection(theme),
                const Divider(height: 64, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đánh giá khách hàng',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _isLoadingReviews
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: _hasReviewed()
                                ? null
                                : _showAddReviewDialog,
                            child: Text(
                              _hasReviewed() ? 'Đã đánh giá' : 'Viết đánh giá',
                              style: TextStyle(
                                color: _hasReviewed()
                                    ? Colors.grey
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingReviews
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                    ? _buildEmptyReviews(theme)
                    : Column(
                        children: _reviews
                            .map(
                              (review) => ReviewCard(
                                review: review,
                                showDeleteButton: true,
                                onDelete: () => _deleteReview(review),
                              ),
                            )
                            .toList(),
                      ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomPanel(currencyFormat, theme),
    );
  }

  List<Widget> _renderColorSection(ThemeData theme) {
    final availableColors = _currentProduct.variants
        .map((v) => v.color)
        .toSet()
        .toList();
    if (availableColors.isEmpty) return [];
    return [
      _buildSectionTitle("Màu sắc", theme),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: availableColors
            .map(
              (color) =>
                  _buildChoiceChip(color, selectedColor == color, theme, (s) {
                    setState(() {
                      selectedColor = s ? color : null;
                      if (selectedColor != null && selectedSize != null) {
                        final exists = _currentProduct.variants.any(
                          (v) =>
                              v.color == selectedColor &&
                              v.size == selectedSize &&
                              v.stock > 0,
                        );
                        if (!exists) selectedSize = null;
                      }
                    });
                  }),
            )
            .toList(),
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _renderSizeSection(ThemeData theme) {
    final availableSizes = _currentProduct.variants
        .where((v) => selectedColor == null || v.color == selectedColor)
        .map((v) => v.size)
        .toSet()
        .toList();
    if (availableSizes.isEmpty) return [];
    return [
      _buildSectionTitle("Kích thước", theme),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: availableSizes
            .map(
              (size) => _buildChoiceChip(size, selectedSize == size, theme, (
                s,
              ) {
                final variant = _currentProduct.variants.firstWhere(
                  (v) =>
                      (selectedColor == null || v.color == selectedColor) &&
                      v.size == size,
                  orElse: () => _currentProduct.variants.first,
                );
                if (variant.stock > 0) {
                  setState(() => selectedSize = s ? size : null);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sản phẩm này đã hết hàng")),
                  );
                }
              }),
            )
            .toList(),
      ),
    ];
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    ThemeData theme,
    Function(bool) onSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: theme.cardColor,
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : Colors.white.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    if (!_isLoadingRecommendations && _recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sản phẩm tương tự",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingRecommendations
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendations.length,
                  itemBuilder: (context, index) {
                    final product = _recommendations[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ProductCard(
                        product: product,
                        width: 180,
                        token: widget.token,
                        user: widget.user,
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyReviews(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá nào. Hãy là người đầu tiên!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(NumberFormat currencyFormat, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () =>
                      quantity > 1 ? setState(() => quantity--) : null,
                  splashRadius: 20,
                ),
                Text(
                  "$quantity",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () => setState(() => quantity++),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: isAddingToCart ? null : _addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isAddingToCart
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "THÊM VÀO GIỎ",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
