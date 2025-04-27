import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rbac_app/constant.dart';
import 'package:rbac_app/providers/address_provider.dart';
import 'package:rbac_app/providers/cart_provider.dart';
import 'package:rbac_app/providers/wishlist_provider.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/category_management_screen.dart';
import 'screens/wishlist_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider(null)),
        ChangeNotifierProvider(create: (_) => AuthService(null)),
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      builder: (context, child) {
        // Initialize dependencies after the provider scope is established
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        cartProvider.setAuthService(authService);
        authService.setCartProvider(cartProvider);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'E-commerce App',
          theme: AppTheme.theme,
          initialRoute: '/home',
          routes: {
            '/login': (context) => LoginScreen(),
            '/signup': (context) => SignupScreen(),
            '/home': (context) => HomeScreen(),
            '/cart': (context) => CartScreen(),
            '/category_management': (context) => CategoryManagementScreen(),
            '/wishlist': (context) => WishlistScreen(),
            '/profile': (context) => ProfileScreen(),
          },
        );
      },
    );
  }
}
