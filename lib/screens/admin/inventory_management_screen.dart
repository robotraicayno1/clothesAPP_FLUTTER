import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class InventoryManagementScreen extends StatefulWidget {
  final String token;
  const InventoryManagementScreen({super.key, required this.token});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final products = await _productService.getInventory(widget.token);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _editVariant(Product product, int variantIndex) {
    final variant = product.variants[variantIndex];
    final stockController = TextEditingController(
      text: variant.stock.toString(),
    );
    final purchaseController = TextEditingController(
      text: variant.purchasePrice.toString(),
    );
    final sellingController = TextEditingController(
      text: variant.sellingPrice.toString(),
    );

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          "Cập nhật Biến thể\n${product.name} (${variant.color} - ${variant.size})",
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(stockController, "Số lượng tồn kho", theme),
            SizedBox(height: 12),
            _buildTextField(purchaseController, "Giá nhập (VNĐ)", theme),
            SizedBox(height: 12),
            _buildTextField(sellingController, "Giá bán (VNĐ)", theme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hủy", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedVariant = ProductVariant(
                color: variant.color,
                size: variant.size,
                stock: int.tryParse(stockController.text) ?? 0,
                purchasePrice: double.tryParse(purchaseController.text) ?? 0,
                sellingPrice: double.tryParse(sellingController.text) ?? 0,
              );

              final updatedVariants = List<ProductVariant>.from(
                product.variants,
              );
              updatedVariants[variantIndex] = updatedVariant;

              final updatedProduct = Product(
                id: product.id,
                name: product.name,
                description: product.description,
                price: product.price,
                imageUrl: product.imageUrl,
                category: product.category,
                isFeatured: product.isFeatured,
                isBestSeller: product.isBestSeller,
                gender: product.gender,
                variants: updatedVariants,
                averageRating: product.averageRating,
                reviewCount: product.reviewCount,
              );

              final success = await _productService.updateProduct(
                updatedProduct,
                widget.token,
              );
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Cập nhật kho thành công!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Navigator.pop(context);
              _loadInventory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    ThemeData theme,
  ) {
    return TextField(
      controller: controller,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Quản Lý Kho Hàng",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(onPressed: _loadInventory, icon: Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      collapsedIconColor: Colors.white70,
                      iconColor: theme.colorScheme.primary,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.fullImageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: Colors.white10,
                            child: Icon(Icons.image, color: Colors.white24),
                          ),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "${product.variants.length} biến thể",
                        style: TextStyle(color: Colors.white54),
                      ),
                      children: product.variants.asMap().entries.map((entry) {
                        final vIndex = entry.key;
                        final v = entry.value;
                        return Container(
                          color: Colors.black12,
                          child: ListTile(
                            title: Text(
                              "${v.color} - Size ${v.size}",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "Tồn kho: ",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      "${v.stock}",
                                      style: TextStyle(
                                        color: v.stock < 5
                                            ? Colors.redAccent
                                            : Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Nhập: ${currencyFormat.format(v.purchasePrice)} | Bán: ${currencyFormat.format(v.sellingPrice)}",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                if (v.sellingPrice > v.purchasePrice)
                                  Text(
                                    "Lợi nhuận: ${currencyFormat.format(v.sellingPrice - v.purchasePrice)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey[200],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.edit_note,
                              color: theme.colorScheme.secondary,
                            ),
                            onTap: () => _editVariant(product, vIndex),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
              },
            ),
    );
  }
}
