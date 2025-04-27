import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/cart_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _recommendedProducts = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  String _sortOption = 'Default';
  bool _isLoading = true;
  String? _errorMessage;

  // Static data for featured brands slider
  final List<Map<String, String>> _featuredBrands = [
    {
      'name': 'LG',
      'image':
          'https://1000logos.net/wp-content/uploads/2017/03/LG-Logo-2014.png',
      'niche': 'Electronics',
    },
    {
      'name': 'Puma',
      'image': 'https://1000logos.net/wp-content/uploads/2017/05/PUMA-logo.jpg',
      'niche': 'Fashion',
    },
    {
      'name': 'Nike',
      'image': 'https://pngimg.com/d/nike_PNG6.png',
      'niche': 'Shoes',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _fetchCategories();
    await _fetchProducts();
    _updateRecommendations();
  }

  Future<void> _fetchCategories() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final categories = await CategoryService().fetchCategories(
        authService.token!,
      );
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _fetchProducts() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final products = await ProductService().fetchProducts(authService.token!);
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
        _errorMessage = null;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Product> tempProducts = List.from(_products);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      tempProducts =
          tempProducts
              .where(
                (product) => product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      tempProducts =
          tempProducts
              .where((product) => product.categoryId == _selectedCategoryId)
              .toList();
    }

    // Apply sorting
    if (_sortOption == 'Price: Low to High') {
      tempProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortOption == 'Price: High to Low') {
      tempProducts.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortOption == 'Top Selling') {
      tempProducts.sort((a, b) => b.id!.compareTo(a.id!));
    }

    setState(() {
      _filteredProducts = tempProducts;
    });
    _updateRecommendations();
  }

  void _updateRecommendations() {
    List<Product> tempRecommendations = [];

    if (_selectedCategoryId != null) {
      // Recommend products from the same category
      tempRecommendations =
          _products
              .where((product) => product.categoryId == _selectedCategoryId)
              .toList();
    } else {
      // Recommend top-selling products (simulated by highest IDs)
      tempRecommendations = List.from(_products)
        ..sort((a, b) => b.id!.compareTo(a.id!));
    }

    // Limit to 5 recommendations and exclude products already in filtered list
    tempRecommendations =
        tempRecommendations
            .where(
              (product) =>
                  !_filteredProducts.any(
                    (filtered) => filtered.id == product.id,
                  ),
            )
            .take(5)
            .toList();

    setState(() {
      _recommendedProducts = tempRecommendations;
    });
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onSortChanged(String? value) {
    setState(() {
      _sortOption = value ?? 'Default';
    });
    _applyFilters();
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _applyFilters();
  }

  void _addToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(product);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('All Products'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _searchProducts,
                decoration: InputDecoration(
                  hintText: 'Search products by name...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade600),
                  ),
                ),
              ),
            ),
          ),
          // Dropdown for Sorting
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButton<String>(
                value: _sortOption,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                onChanged: _onSortChanged,
                items:
                    <String>[
                      'Default',
                      'Price: Low to High',
                      'Price: High to Low',
                      'Top Selling',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                style: TextStyle(color: Colors.black87, fontSize: 16),
                underline: Container(height: 1, color: Colors.grey.shade300),
              ),
            ),
          ),
          // Top Featured Brands Heading
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Top Featured Brands',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Featured Brands Slider
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 120.0,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                ),
                items:
                    _featuredBrands.map((brand) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: MediaQuery.of(context).size.width,
                            margin: EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    brand['image']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            brand['name']!,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            brand['niche']!,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
          ),
          // Space Between Slider and Categories
          SliverToBoxAdapter(child: SizedBox(height: 24.0)),
          // Categories for Filtering (Sticky Header)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60.0,
              maxHeight: 60.0,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategoryId == null;
                      return GestureDetector(
                        onTap: () => _onCategorySelected(null),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.blue.shade600
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.blue.shade600
                                      : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'All',
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final category = _categories[index - 1];
                    final isSelected = _selectedCategoryId == category.id;
                    return GestureDetector(
                      onTap: () => _onCategorySelected(category.id),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.blue.shade600 : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Product Grid
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver:
                _isLoading
                    ? SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
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
                    : _filteredProducts.isEmpty
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
                        final product = _filteredProducts[index];
                        return ProductCard(
                          product: product,
                          isAdmin: false,
                          onAddToCart: () => _addToCart(product),
                        );
                      }, childCount: _filteredProducts.length),
                    ),
          ),
          // Recommended for You Section
          SliverToBoxAdapter(
            child:
                _recommendedProducts.isNotEmpty
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'Recommended for You',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          height:
                              280.0, // Adjusted height for ProductCard in horizontal list
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _recommendedProducts.length,
                            itemBuilder: (context, index) {
                              final product = _recommendedProducts[index];
                              return Container(
                                width:
                                    160.0, // Adjusted width for horizontal display
                                margin: EdgeInsets.only(right: 16.0),
                                child: ProductCard(
                                  product: product,
                                  isAdmin: false,
                                  onAddToCart: () => _addToCart(product),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 16.0),
                      ],
                    )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for sticky categories
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
