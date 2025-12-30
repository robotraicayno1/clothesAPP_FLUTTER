import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/services/upload_service.dart';
import 'package:clothesapp/widgets/custom_button.dart';
import 'package:clothesapp/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  final String token;
  const AddProductScreen({super.key, required this.token});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();

  final List<String> categories = [
    'Men',
    'Women',
    'Pants',
    'Shirts',
    'Accessories',
  ];
  String selectedCategory = 'Men';
  String selectedGender = 'Unisex';
  final _colorsController = TextEditingController();
  final List<String> availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  List<String> selectedSizes = [];
  bool isFeatured = false;
  bool isBestSeller = false;

  final ProductService _productService = ProductService();
  final UploadService _uploadService = UploadService();
  bool _isLoading = false;
  File? _pickedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
        _imageController.text = image.path; // Just for display or fallback
      });
    }
  }

  void _submit() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Vui lòng nhập đủ thông tin")));
      return;
    }

    setState(() => _isLoading = true);

    String finalImageUrl = _imageController.text;

    if (_pickedImage != null) {
      String? uploadUrl = await _uploadService.uploadImage(_pickedImage!);
      if (uploadUrl != null) {
        finalImageUrl = uploadUrl;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload ảnh thất bại, dùng Link mặc định")),
        );
      }
    }

    final product = Product(
      id: '', // Backend generats ID
      name: _nameController.text,
      description: _descController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      imageUrl: finalImageUrl.isEmpty
          ? 'https://via.placeholder.com/150'
          : finalImageUrl,
      category: selectedCategory,
      isFeatured: isFeatured,
      isBestSeller: isBestSeller,
      gender: selectedGender,
      colors: _colorsController.text.split(',').map((e) => e.trim()).toList(),
      sizes: selectedSizes,
    );

    final success = await _productService.createProduct(product, widget.token);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Thêm sản phẩm thành công!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi thêm sản phẩm")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thêm Sản Phẩm"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: "Tên sản phẩm",
              prefixIcon: Icons.label,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              hintText: "Giá bán (VNĐ)",
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _descController,
              hintText: "Mô tả sản phẩm",
              prefixIcon: Icons.description,
            ),
            SizedBox(height: 16),
            SizedBox(height: 16),

            // Image Picker UI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_pickedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: Colors.grey,
                          ),
                          Text(
                            "Chọn ảnh từ thư viện",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Hoặc nhập Link ảnh (Optional):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            CustomTextField(
              controller: _imageController,
              hintText: "Link ảnh (URL)",
              prefixIcon: Icons.link,
            ),
            SizedBox(height: 20),

            Text("Danh mục:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items: categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
            SizedBox(height: 16),

            Text("Giới tính:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedGender,
              isExpanded: true,
              items: [
                'Men',
                'Women',
                'Unisex',
                'Kids',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => selectedGender = v!),
            ),
            SizedBox(height: 16),

            CustomTextField(
              controller: _colorsController,
              hintText: "Màu sắc (phân cách bằng dấu phẩy, vd: Red, Blue)",
              prefixIcon: Icons.color_lens,
            ),
            SizedBox(height: 16),

            Text("Size:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: availableSizes.map((size) {
                return FilterChip(
                  label: Text(size),
                  selected: selectedSizes.contains(size),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedSizes.add(size);
                      } else {
                        selectedSizes.remove(size);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),

            SwitchListTile(
              title: Text("Nổi bật (Featured)"),
              value: isFeatured,
              onChanged: (v) => setState(() => isFeatured = v),
            ),
            SwitchListTile(
              title: Text("Bán chạy (Best Seller)"),
              value: isBestSeller,
              onChanged: (v) => setState(() => isBestSeller = v),
            ),

            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : CustomButton(text: "Lưu Sản Phẩm", onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
