import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/services/order_service.dart';
import 'package:clothesapp/services/review_service.dart';
import 'package:clothesapp/widgets/add_review_dialog.dart';
import 'package:flutter/material.dart';

class OrderReviewListDialog extends StatefulWidget {
  final Order order;
  final String token;

  const OrderReviewListDialog({
    super.key,
    required this.order,
    required this.token,
  });

  @override
  State<OrderReviewListDialog> createState() => _OrderReviewListDialogState();
}

class _OrderReviewListDialogState extends State<OrderReviewListDialog> {
  final ReviewService _reviewService = ReviewService();
  final Set<String> _reviewedProductIds = {};

  void _showAddReviewDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        onSubmit: (rating, comment) async {
          final success = await _reviewService.addReview(
            product.id,
            rating,
            comment,
            widget.token,
          );
          if (success && mounted) {
            setState(() {
              _reviewedProductIds.add(product.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đánh giá sản phẩm ${product.name} thành công!'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đánh giá sản phẩm'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.order.products.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final product = widget.order.products[index];
            final isReviewed = _reviewedProductIds.contains(product.id);

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.network(
                product.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
              title: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(isReviewed ? 'Đã đánh giá' : 'Chưa đánh giá'),
              trailing: ElevatedButton(
                onPressed: isReviewed
                    ? null
                    : () => _showAddReviewDialog(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReviewed ? Colors.grey : Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(isReviewed ? 'Xong' : 'Đánh giá'),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
