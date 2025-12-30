import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/models/review.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/services/review_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/widgets/add_review_dialog.dart';
import 'package:clothesapp/widgets/review_card.dart';
import 'package:flutter/material.dart';
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
  late Product _currentProduct;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _checkIsFavorite();
    _loadReviews();
  }

  void _checkIsFavorite() {
    final favorites = widget.user['favorites'] as List?;
    if (favorites != null) {
      setState(() {
        isFavorite = favorites.contains(widget.product.id);
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

  // Reload product to get updated rating/count
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
          if (success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Đánh giá thành công!')));
            _loadReviews();
            _reloadProduct();
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Lỗi khi gửi đánh giá')));
          }
        },
      ),
    );
  }

  void _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa đánh giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reviewService.deleteReview(
        review.id,
        widget.token,
      );
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa đánh giá')));
        _loadReviews();
        _reloadProduct();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xóa đánh giá này')));
      }
    }
  }

  void _addToCart() async {
    setState(() => isAddingToCart = true);
    final success = await _userService.addToCart(
      widget.product.id,
      quantity,
      widget.token,
    );
    setState(() => isAddingToCart = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã thêm vào giỏ hàng!")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi thêm vào giỏ hàng!")));
    }
  }

  void _toggleFavorite() async {
    setState(() => isFavorite = !isFavorite);
    await _userService.toggleFavorite(widget.product.id, widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                _currentProduct.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image, size: 100, color: Colors.grey),
              ),
            ),
            leading: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.black,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _currentProduct.name,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      currencyFormat.format(_currentProduct.price),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentProduct.gender,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 4),
                    Text(
                      _currentProduct.averageRating > 0
                          ? _currentProduct.averageRating.toStringAsFixed(1)
                          : "Chưa có",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "(${_currentProduct.reviewCount} ${_currentProduct.reviewCount == 1 ? 'Review' : 'Reviews'})",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Description
                Text(
                  "Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _currentProduct.description.isEmpty
                      ? "No description available."
                      : _currentProduct.description,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
                SizedBox(height: 24),

                // Colors
                if (_currentProduct.colors.isNotEmpty) ...[
                  Text(
                    "Select Color",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _currentProduct.colors.map((color) {
                      return ChoiceChip(
                        label: Text(color),
                        selected: selectedColor == color,
                        onSelected: (selected) {
                          setState(() {
                            selectedColor = selected ? color : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                ],

                // Sizes
                if (_currentProduct.sizes.isNotEmpty) ...[
                  Text(
                    "Select Size",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _currentProduct.sizes.map((size) {
                      return ChoiceChip(
                        label: Text(size),
                        selected: selectedSize == size,
                        onSelected: (selected) {
                          setState(() {
                            selectedSize = selected ? size : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                // Reviews Section
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đánh Giá (${_reviews.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddReviewDialog,
                      icon: Icon(Icons.rate_review),
                      label: Text('Viết đánh giá'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _isLoadingReviews
                    ? Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chưa có đánh giá nào',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Hãy là người đầu tiên đánh giá sản phẩm này!',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _reviews.map((review) {
                          return ReviewCard(
                            review: review,
                            showDeleteButton: true,
                            onDelete: () => _deleteReview(review),
                          );
                        }).toList(),
                      ),
                SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (quantity > 1) setState(() => quantity--);
                    },
                  ),
                  Text(
                    "$quantity",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      setState(() => quantity++);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isAddingToCart
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Add to Cart",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
