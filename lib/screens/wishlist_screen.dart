import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rbac_app/constant.dart';
import '../services/auth_service.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class WishlistScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isAdmin = authService.user?.role == 'ADMIN';
    final wishlistItems = wishlistProvider.wishlistItems;

    return Scaffold(
      appBar: AppBar(title: Text('Wishlist')),
      body:
          wishlistItems.isEmpty
              ? Center(child: Text('Your wishlist is empty'))
              : GridView.builder(
                padding: EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: wishlistItems.length,
                itemBuilder: (context, index) {
                  final product = wishlistItems[index];
                  return ProductCard(
                    product: product,
                    isAdmin: false, // Wishlist is only for non-admins
                    onAddToCart: () {
                      cartProvider.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                        ),
                      );
                    },
                    onEdit: null,
                    onDelete: () {
                      wishlistProvider.removeFromWishlist(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product.name} removed from wishlist',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      bottomNavigationBar:
          !isAdmin
              ? BottomNavigationBar(
                currentIndex: 1,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(initialIndex: 0),
                        ),
                      );
                      break;
                    case 1:
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
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(),
                        ),
                      );
                      break;
                  }
                },
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
                    icon: Icon(Icons.shopping_cart),
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
