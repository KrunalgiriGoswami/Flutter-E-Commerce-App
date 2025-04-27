import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rbac_app/constant.dart';
import 'package:rbac_app/providers/cart_provider.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/address_provider.dart';
import 'product_form_screen.dart';
import 'cart_screen.dart';
import 'category_management_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'product_list_screen.dart';
import 'address_management_screen.dart';
import 'order_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  late int _currentIndex;

  // Carousel items (static for now)
  final List<Map<String, String>> _carouselItems = [
    {
      'title': 'New Arrivals',
      'image':
          'https://t4.ftcdn.net/jpg/03/26/99/77/360_F_326997723_KC8cOqw2SEdlYxjKzvRzbRWnoGAsFdrQ.jpg',
    },
    {
      'title': 'Top Selling',
      'image':
          'https://t3.ftcdn.net/jpg/05/75/66/88/360_F_575668898_05nhhqdSNoUtbnNcupJyRcDONlibzSHr.jpg',
    },
    {
      'title': 'Special Offer',
      'image':
          'https://t4.ftcdn.net/jpg/05/75/66/89/360_F_575668954_S1gEB20aXo6jiZInbD2rURWZyYK8ZMww.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500), () async {
      // Ensure shimmer lasts at least 500ms
      await _fetchCategories();
      if (_categories.isNotEmpty) {
        await _fetchProducts();
      } else {
        setState(() {
          _errorMessage =
              'Failed to load categories. Please try again or add categories as admin.';
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchCategories() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final categories = await CategoryService().fetchCategories(
        authService.token!,
      );
      print('Categories fetched: ${categories.length} - $categories');
      setState(() {
        _categories = categories;
        _selectedCategoryId = categories.isNotEmpty ? categories[0].id : null;
      });
    } catch (e) {
      print('Categories error: $e');
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _fetchProducts() async {
    if (_categories.isEmpty) {
      setState(() {
        _errorMessage = 'No categories available to load products';
        _isLoading = false;
      });
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      List<Product> products;
      if (_searchQuery.isNotEmpty) {
        products = await ProductService().searchProducts(
          authService.token!,
          _searchQuery,
        );
      } else if (_selectedCategoryId == null ||
          (_categories.isNotEmpty &&
              _selectedCategoryId == _categories[0].id)) {
        products = await ProductService().fetchProducts(authService.token!);
      } else {
        products = await ProductService().fetchProductsByCategory(
          authService.token!,
          _selectedCategoryId!,
        );
      }
      print('Products fetched: ${products.length}');
      setState(() {
        _products = products;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Products error: $e');
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductFormScreen()),
    );
    if (result == true) {
      _fetchData();
    }
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
    if (result == true) {
      _fetchData();
    }
  }

  void _deleteProduct(int id) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await ProductService().deleteProduct(authService.token!, id);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
    }
  }

  void _addToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(product);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }

  void _manageCategories() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoryManagementScreen()),
    );
    _fetchData();
  }

  void _manageOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderManagementScreen()),
    );
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });
    _fetchProducts();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WishlistScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CartScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final selectedAddress = addressProvider.selectedShippingAddress;
    final isAdmin = authService.user?.role == 'ADMIN';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 2,
            pinned: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome, ${authService.user?.username ?? "User"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      authService.user?.role ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isAdmin) ...[
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressManagementScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            selectedAddress != null
                                ? 'Deliver to: ${selectedAddress.street}, ${selectedAddress.city}, ${selectedAddress.state} - ${selectedAddress.postalCode}'
                                : 'Deliver to: No address selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (isAdmin) ...[
                IconButton(
                  icon: Icon(Icons.category),
                  onPressed: _manageCategories,
                ),
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.red),
                  onPressed: () async {
                    await authService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ],
          ),
          // Sticky Search Bar and Categories
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: TextField(
                      onChanged: _searchProducts,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Categories
                  Container(
                    height: 100,
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child:
                        _isLoading
                            ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 5, // Placeholder for 5 categories
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  );
                                },
                              ),
                            )
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected =
                                    _selectedCategoryId == category.id;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId = category.id;
                                      _searchQuery = '';
                                      _isLoading = true;
                                    });
                                    _fetchProducts();
                                  },
                                  child: Container(
                                    width: 100,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? AppColors.secondary
                                                      : AppColors.primary,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child:
                                              category.imageUrl != null
                                                  ? ClipOval(
                                                    child: Image.network(
                                                      category.imageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Icon(
                                                            Icons.category,
                                                            color:
                                                                AppColors
                                                                    .primary,
                                                          ),
                                                    ),
                                                  )
                                                  : Icon(
                                                    Icons.category,
                                                    color: AppColors.primary,
                                                  ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color:
                                                isSelected
                                                    ? AppColors.secondary
                                                    : AppColors.textPrimary,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Marquee Effect for Non-Admins
                if (!isAdmin)
                  Container(
                    height: 40,
                    color: Colors.black,
                    child: Marquee(
                      text:
                          '🎉 Special Offer: Get 10% OFF on all products! Shop Now! 🎉   ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: 20.0,
                      velocity: 50.0,
                      pauseAfterRound: Duration(seconds: 1),
                      startPadding: 10.0,
                      accelerationDuration: Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                    ),
                  ),
                // Carousel Slider for Non-Admins
                if (!isAdmin)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child:
                        _isLoading
                            ? Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                            : CarouselSlider(
                              options: CarouselOptions(
                                height: 150.0,
                                autoPlay: true,
                                autoPlayInterval: Duration(seconds: 3),
                                enlargeCenterPage: true,
                                viewportFraction: 0.9,
                              ),
                              items:
                                  _carouselItems.map((item) {
                                    return Builder(
                                      builder: (BuildContext context) {
                                        return Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 5.0,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.network(
                                                  item['image']!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  bottom: 10,
                                                  left: 10,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black54,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      item['title']!,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                            ),
                  ),
                // Popular Products Heading with View All Button
                if (!isAdmin)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductListScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Admin Add Product and Manage Orders Buttons
                if (isAdmin)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _addProduct,
                          child: Text('Add New Product'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _manageOrders,
                          child: Text('Manage Orders'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Product Grid
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver:
                _isLoading
                    ? SliverToBoxAdapter(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: 4, // Placeholder for 4 products
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    : _errorMessage != null
                    ? SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                    : _products.isEmpty
                    ? SliverToBoxAdapter(
                      child: Center(child: Text('No products available')),
                    )
                    : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          isAdmin: isAdmin,
                          onEdit: isAdmin ? () => _editProduct(product) : null,
                          onDelete:
                              isAdmin
                                  ? () => _deleteProduct(product.id!)
                                  : null,
                          onAddToCart:
                              !isAdmin ? () => _addToCart(product) : null,
                        );
                      }, childCount: _products.length),
                    ),
          ),
        ],
      ),
      bottomNavigationBar:
          !isAdmin
              ? BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _onNavBarTap,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.secondary,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Wishlist',
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      children: [
                        Icon(Icons.shopping_cart),
                        if (cartProvider.getTotalQuantity() > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cartProvider.getTotalQuantity()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    label: 'Cart',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              )
              : null,
    );
  }
}

// Delegate for the sticky header
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: child);
  }

  @override
  double get maxExtent => 172; // Adjusted: 56 (search bar) + 16 (padding) + 100 (categories)

  @override
  double get minExtent => 172;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class ProductSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildProductList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildProductList(context);

  Widget _buildProductList(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.user?.role == 'ADMIN';

    return FutureBuilder<List<Product>>(
      future: ProductService().searchProducts(authService.token!, query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        return products.isEmpty
            ? Center(child: Text('No products found'))
            : GridView.builder(
              padding: EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  isAdmin: isAdmin,
                  onEdit:
                      isAdmin
                          ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ProductFormScreen(product: product),
                            ),
                          ).then((result) {
                            if (result == true) {
                              close(context, null);
                            }
                          })
                          : null,
                  onDelete:
                      isAdmin
                          ? () async {
                            await ProductService().deleteProduct(
                              authService.token!,
                              product.id!,
                            );
                            close(context, null);
                          }
                          : null,
                  onAddToCart:
                      !isAdmin
                          ? () {
                            final cartProvider = Provider.of<CartProvider>(
                              context,
                              listen: false,
                            );
                            cartProvider.addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                              ),
                            );
                          }
                          : null,
                );
              },
            );
      },
    );
  }
}
