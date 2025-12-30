import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/screens/admin/admin_dashboard.dart';
import 'package:clothesapp/screens/cart_screen.dart';
import 'package:clothesapp/screens/login_screen.dart';
import 'package:clothesapp/screens/my_orders_screen.dart';
import 'package:clothesapp/screens/favorites_screen.dart';
import 'package:clothesapp/screens/profile_screen.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/widgets/custom_textfield.dart';
import 'package:clothesapp/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const HomeScreen({super.key, required this.user, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> categories = [
    'All',
    'Men',
    'Women',
    'Pants',
    'Shirts',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getProducts(
      category: _selectedCategory,
      search: _searchQuery,
    );
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.user['name']),
              accountEmail: Text(widget.user['email']),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.user['name'][0],
                  style: TextStyle(
                    fontSize: 40.0,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            if (widget.user['type'] == 'admin' ||
                widget.user['email'] == 'admin@clothes.com')
              ListTile(
                leading: Icon(Icons.admin_panel_settings),
                title: Text('Trang Admin (Quản lý)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDashboard(token: widget.token),
                    ),
                  ).then((_) {
                    // Refresh products when returning from admin dashboard
                    _loadProducts();
                  });
                },
              ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Hồ sơ cá nhân'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfileScreen(user: widget.user, token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag_outlined),
              title: Text('Đơn hàng của tôi'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyOrdersScreen(token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite_outline),
              title: Text('Sản phẩm yêu thích'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FavoritesScreen(user: widget.user, token: widget.token),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Đăng xuất'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Xin chào, ${widget.user['name']}!",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
            Text(
              "Bạn muốn tìm gì?",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FavoritesScreen(user: widget.user, token: widget.token),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {},
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomTextField(
                controller: _searchController,
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: Icons.search,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadProducts(); // Simple debounce could be added
                },
              ),
            ),
            SizedBox(height: 24),

            // Categories
            SizedBox(
              height: 40,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) _onCategorySelected(category);
                      },
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedColor: Colors.black,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),

            // Product Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? Center(child: Text("Không tìm thấy sản phẩm nào"))
                  : Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _products.map((product) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return ProductCard(
                              product: product,
                              width:
                                  (MediaQuery.of(context).size.width - 64) / 2,
                              token: widget.token,
                              user: widget.user,
                            );
                          },
                        );
                      }).toList(),
                    ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            // Cart Index
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CartScreen(token: widget.token, user: widget.user),
              ),
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: "Danh mục",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: "Giỏ hàng",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Hồ sơ",
          ),
        ],
      ),
    );
  }
}
