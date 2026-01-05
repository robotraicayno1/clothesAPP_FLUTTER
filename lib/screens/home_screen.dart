import 'dart:async';
import 'package:clothesapp/models/product.dart';
import 'package:clothesapp/screens/cart_screen.dart';
import 'package:clothesapp/screens/favorites_screen.dart';
import 'package:clothesapp/screens/notification_screen.dart';
import 'package:clothesapp/screens/profile_screen.dart';
import 'package:clothesapp/services/notification_service.dart';
import 'package:clothesapp/services/product_service.dart';
import 'package:clothesapp/services/user_service.dart';
import 'package:clothesapp/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:clothesapp/screens/my_orders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clothesapp/screens/admin/admin_dashboard.dart';
import 'package:clothesapp/screens/chat_screen.dart';
import 'package:clothesapp/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const HomeScreen({super.key, required this.user, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentPage = 0;
  int _unreadCount = 0;
  Timer? _notificationTimer;

  List<Product> _products = [];
  List<Product> _bestSellers = [];
  bool _isLoading = true;
  String _selectedCategoryId = 'All';
  String _searchQuery = '';

  // Dynamic user state
  Map<String, dynamic>? _currentUser;

  // Filter values
  double _minPrice = 0;
  double _maxPrice = 2000000;
  String _selectedGender = 'All';

  List<String> _recentSearches = [];

  final List<Map<String, String>> categoryList = [
    {'id': 'All', 'name': 'Tất cả'},
    {'id': 'Men', 'name': 'Nam'},
    {'id': 'Women', 'name': 'Nữ'},
    {'id': 'Pants', 'name': 'Quần'},
    {'id': 'Shirts', 'name': 'Áo'},
    {'id': 'Accessories', 'name': 'Phụ kiện'},
  ];

  final List<Map<String, String>> banners = [
    {
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&q=80&w=1000',
      'title': 'Bộ sưu tập Mùa Đông',
      'subtitle': 'Giảm giá lên đến 50%',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1441984969133-35d1383e221e?auto=format&fit=crop&q=80&w=1000',
      'title': 'Thời trang Nam mới',
      'subtitle': 'Phong cách & Lịch lãm',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&q=80&w=1000',
      'title': 'Ưu đãi cuối năm',
      'subtitle': 'Mua 1 tặng 1',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user; // Init with passed user
    _refreshUser(); // Fetch latest to ensure sync
    _loadRecentSearches();
    _loadProducts();
    _checkNotifications();
    // Poll for notifications every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNotifications();
    });
  }

  Future<void> _refreshUser() async {
    final updatedUser = await _userService.getProfile(widget.token);
    if (updatedUser != null && mounted) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkNotifications() async {
    final notifications = await _notificationService.getNotifications(
      widget.token,
    );
    if (mounted) {
      setState(() {
        _unreadCount = notifications
            .where((n) => n['status'] == 'unread')
            .length;
      });
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList('recentSearches') ?? [];
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 5) searches = searches.sublist(0, 5);
    await prefs.setStringList('recentSearches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  void _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getProducts(
      category: _selectedCategoryId,
      search: _searchQuery,
      minPrice: _minPrice > 0 ? _minPrice : null,
      maxPrice: _maxPrice < 2000000 ? _maxPrice : null,
      gender: _selectedGender,
    );
    if (mounted) {
      setState(() {
        _products = products;
        _bestSellers = products.where((p) => p.isBestSeller).toList();
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadProducts();
  }

  void _resetFilters() {
    setState(() {
      _minPrice = 0;
      _maxPrice = 2000000;
      _selectedGender = 'All';
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      endDrawer: _buildFilterDrawer(),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(
                    theme,
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  if (_searchQuery.isEmpty && _recentSearches.isNotEmpty)
                    _buildRecentSearches(theme),
                  const SizedBox(height: 24),
                  _buildCarousel().animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 32),
                  _buildCategories(theme).animate().fadeIn(delay: 200.ms),
                  if (_bestSellers.isNotEmpty &&
                      _selectedCategoryId == 'All') ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      "Sản phẩm bán chạy",
                      () {},
                      theme,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 16),
                    _buildBestSellers().animate().fadeIn(delay: 400.ms),
                  ],
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    _selectedCategoryId == 'All'
                        ? "Sản phẩm mới"
                        : "Danh mục ${categoryList.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => {'name': ''})['name']}",
                    () {},
                    theme,
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                  _buildProductGrid(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Xin chào,",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          Text(widget.user['name'], style: theme.textTheme.headlineMedium),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationScreen(token: widget.token),
                  ),
                ).then((_) => _checkNotifications());
              },
              icon: Icon(
                Icons.notifications_none_outlined,
                color: theme.iconTheme.color,
                size: 26,
              ),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(right: 8, left: 4),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FavoritesScreen(user: widget.user, token: widget.token),
                ),
              );
            },
            icon: Icon(
              Icons.favorite_outline,
              color: theme.iconTheme.color,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      theme
                          .inputDecorationTheme
                          .enabledBorder
                          ?.borderSide
                          .color ??
                      Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) {
                  _saveSearch(value);
                  _loadProducts();
                },
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _loadProducts();
                },
                style: theme.textTheme.bodyLarge,
                cursorColor: theme.colorScheme.primary,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm phong cách...",
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.iconTheme.color?.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary, // Gold
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.tune,
                color: theme.colorScheme.onPrimary, // Black
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tìm kiếm gần đây",
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _recentSearches
                .map(
                  (search) => GestureDetector(
                    onTap: () {
                      _searchController.text = search;
                      setState(() => _searchQuery = search);
                      _loadProducts();
                    },
                    child: Chip(
                      label: Text(
                        search,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: theme.cardTheme.color,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDrawer() {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 0.8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Bộ lọc", style: theme.textTheme.headlineMedium),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.iconTheme.color),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text("Khoảng giá", style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 2000000,
                divisions: 20,
                activeColor: theme.colorScheme.primary,
                inactiveColor: theme.colorScheme.secondary.withOpacity(0.2),
                labels: RangeLabels(
                  currencyFormat.format(_minPrice),
                  currencyFormat.format(_maxPrice),
                ),
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(_minPrice),
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    currencyFormat.format(_maxPrice),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text("Giới tính", style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: ['All', 'Nam', 'Nữ']
                    .map(
                      (gender) => ChoiceChip(
                        label: Text(gender == 'All' ? 'Tất cả' : gender),
                        selected: _selectedGender == gender,
                        onSelected: (s) =>
                            setState(() => _selectedGender = gender),
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: theme.cardTheme.color,
                        labelStyle: TextStyle(
                          color: _selectedGender == gender
                              ? theme.colorScheme.onPrimary
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight: _selectedGender == gender
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedGender == gender
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.secondary),
                        foregroundColor: theme.textTheme.bodyLarge?.color,
                      ),
                      child: const Text("Đặt lại"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadProducts();
                      },
                      child: const Text("Áp dụng"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(banner['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner['title']!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          banner['subtitle']!,
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategories(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: categoryList.length,
        itemBuilder: (context, index) {
          final category = categoryList[index];
          final isSelected = category['id'] == _selectedCategoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  category['name']!,
                  style: GoogleFonts.outfit(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              "Xem tất cả",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellers() {
    return SizedBox(
      height: 310,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _bestSellers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ProductCard(
              product: _bestSellers[index],
              width: 180,
              token: widget.token,
              user: _currentUser ?? widget.user,
              onReturn: _refreshUser,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Không tìm thấy sản phẩm nào",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) => ProductCard(
          product: _products[index],
          token: widget.token,
          user: _currentUser ?? widget.user,
          onReturn: _refreshUser,
        ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(
          0.4,
        ),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CartScreen(token: widget.token, user: widget.user),
              ),
            );
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProfileScreen(user: widget.user, token: widget.token),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final user = _currentUser ?? widget.user;
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.cardTheme.color),
            accountName: Text(
              user['name'],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              user['email'],
              style: theme.textTheme.bodyMedium,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                user['name'][0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Trang chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Đơn hàng của tôi'),
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
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Giỏ hàng'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CartScreen(token: widget.token, user: widget.user),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Sản phẩm yêu thích'),
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
          if (widget.user['type'] == 'admin') ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboard(token: widget.token),
                  ),
                );
              },
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Chat hỗ trợ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(user: widget.user, token: widget.token),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Gọi Hotline'),
            onTap: () async {
              Navigator.pop(context);
              final Uri url = Uri.parse('tel:0966209249');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
