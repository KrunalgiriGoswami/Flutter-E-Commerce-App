import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../providers/address_provider.dart';

class CartProvider with ChangeNotifier {
  final Map<Product, int> _cartItems = {};
  AuthService? _authService;

  CartProvider(this._authService);

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  Map<Product, int> get cartItems => _cartItems;

  int getTotalQuantity() {
    return _cartItems.values.fold(0, (sum, quantity) => sum + quantity);
  }

  double getTotalPrice() {
    double total = 0;
    _cartItems.forEach((product, quantity) {
      total += (product.price * 0.9) * quantity; // Apply 10% discount
    });
    return total;
  }

  Future<void> fetchCartItems() async {
    final token = _authService?.token;
    if (token == null || _authService == null) {
      print('Error: No token or AuthService available for fetchCartItems');
      return;
    }

    print('Fetching cart items with token: $token');
    try {
      final response = await http.get(
        Uri.parse('${_authService!.baseUrl}/api/cart'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fetch Cart Response Status: ${response.statusCode}');
      print('Fetch Cart Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _cartItems.clear();
        print('Decoded cart data: $data');

        for (var item in data) {
          final productId = item['productId'] as int? ?? 0;
          final quantity = item['quantity'] as int? ?? 0;

          if (productId == 0 || quantity == 0) {
            print(
              'Skipping invalid cart item: productId=$productId, quantity=$quantity',
            );
            continue;
          }

          try {
            final productResponse = await http.get(
              Uri.parse('${_authService!.baseUrl}/api/products/$productId'),
              headers: {'Authorization': 'Bearer $token'},
            );

            if (productResponse.statusCode == 200) {
              final productData = jsonDecode(productResponse.body);
              final product = Product.fromJson(productData);
              _cartItems[product] = quantity;
              print(
                'Successfully added to cart: ${product.name}, quantity: $quantity',
              );
            } else {
              print(
                'Failed to fetch product $productId: Status ${productResponse.statusCode}, Body ${productResponse.body}',
              );
              final placeholderProduct = Product(
                id: productId,
                name: 'Product Not Found (ID: $productId)',
                description: 'This product is no longer available.',
                price: 0.0,
                categoryId: 0,
                imageUrl: '',
              );
              _cartItems[placeholderProduct] = quantity;
            }
          } catch (e) {
            print('Error fetching product $productId: $e');
            final placeholderProduct = Product(
              id: productId,
              name: 'Error Loading Product (ID: $productId)',
              description: 'Unable to load product details.',
              price: 0.0,
              categoryId: 0,
              imageUrl: '',
            );
            _cartItems[placeholderProduct] = quantity;
          }
        }
        print(
          'Cart state after fetch: ${_cartItems.entries.map((e) => "${e.key.name}: ${e.value}").toList()}',
        );
        notifyListeners();
      } else {
        print(
          'Failed to fetch cart: Status ${response.statusCode}, Body ${response.body}',
        );
        throw Exception('Failed to load cart items: ${response.body}');
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      throw e;
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final token = _authService?.token;
    if (token == null || _authService == null) {
      print('Error: No token or AuthService available for addToCart');
      return;
    }

    try {
      print(
        'Attempting to add to cart: ${product.name}, quantity: $quantity, productId: ${product.id}',
      );

      Product? existingProduct;
      int existingQuantity = 0;
      _cartItems.forEach((p, q) {
        if (p.id == product.id) {
          existingProduct = p;
          existingQuantity = q;
        }
      });

      if (existingProduct != null) {
        final newQuantity = existingQuantity + quantity;
        final response = await http.put(
          Uri.parse('${_authService!.baseUrl}/api/cart/update'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'productId': product.id, 'quantity': newQuantity}),
        );

        print('Update Cart Response Status: ${response.statusCode}');
        print('Update Cart Response Body: ${response.body}');

        if (response.statusCode == 200) {
          _cartItems[existingProduct!] = newQuantity;
          print(
            'Successfully updated quantity for ${product.name} to $newQuantity',
          );
        } else {
          throw Exception('Failed to update cart item: ${response.body}');
        }
      } else {
        final response = await http.post(
          Uri.parse('${_authService!.baseUrl}/api/cart/add'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'productId': product.id, 'quantity': quantity}),
        );

        print('Add Cart Response Status: ${response.statusCode}');
        print('Add Cart Response Body: ${response.body}');

        if (response.statusCode == 200) {
          _cartItems[product] = quantity;
          print(
            'Successfully added new product ${product.name} with quantity: $quantity',
          );
        } else {
          throw Exception('Failed to add item to cart: ${response.body}');
        }
      }
      print(
        'Cart state after add: ${_cartItems.entries.map((e) => "${e.key.name}: ${e.value}").toList()}',
      );
      notifyListeners();
    } catch (e) {
      print('Error adding to cart: $e');
      throw e;
    }
  }

  Future<void> removeFromCart(Product product) async {
    final token = _authService?.token;
    if (token == null ||
        _authService == null ||
        !_cartItems.containsKey(product))
      return;

    try {
      final currentQuantity = _cartItems[product]!;
      final newQuantity = currentQuantity - 1;

      if (newQuantity <= 0) {
        final response = await http.delete(
          Uri.parse('${_authService!.baseUrl}/api/cart/remove/${product.id}'),
          headers: {'Authorization': 'Bearer $token'},
        );

        print('Remove Cart Response Status: ${response.statusCode}');
        print('Remove Cart Response Body: ${response.body}');

        if (response.statusCode == 200) {
          _cartItems.remove(product);
        } else {
          throw Exception('Failed to remove item from cart: ${response.body}');
        }
      } else {
        final response = await http.put(
          Uri.parse('${_authService!.baseUrl}/api/cart/update'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'productId': product.id, 'quantity': newQuantity}),
        );

        print('Update Cart Response Status: ${response.statusCode}');
        print('Update Cart Response Body: ${response.body}');

        if (response.statusCode == 200) {
          _cartItems[product] = newQuantity;
        } else {
          throw Exception('Failed to update cart item: ${response.body}');
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error removing from cart: $e');
      throw e;
    }
  }

  Future<void> clearCart() async {
    final token = _authService?.token;
    if (token == null || _authService == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${_authService!.baseUrl}/api/cart/clear'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Clear Cart Response Status: ${response.statusCode}');
      print('Clear Cart Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _cartItems.clear();
        print('Cart cleared successfully');
        notifyListeners();
      } else {
        throw Exception('Failed to clear cart: ${response.body}');
      }
    } catch (e) {
      print('Error clearing cart: $e');
      throw e;
    }
  }

  Future<void> checkout(BuildContext context) async {
    final token = _authService?.token;
    if (token == null || _authService == null) {
      throw Exception('User not authenticated');
    }

    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    try {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );
      final selectedAddress = addressProvider.selectedShippingAddress;
      if (selectedAddress == null) {
        throw Exception('No shipping address selected');
      }

      final orderItems =
          _cartItems.entries.map((entry) {
            return {
              'productId': entry.key.id,
              'quantity': entry.value,
              'price': entry.key.price * 0.9,
              'imageUrl': entry.key.imageUrl,
            };
          }).toList();

      final orderData = {
        'totalPrice': getTotalPrice(),
        'items': orderItems,
        'shippingAddress': {
          'street': selectedAddress.street,
          'city': selectedAddress.city,
          'state': selectedAddress.state,
          'postalCode': selectedAddress.postalCode,
        },
      };

      print('Sending checkout request with data: $orderData');

      final response = await http.post(
        Uri.parse('${_authService!.baseUrl}/api/orders/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      print('Checkout Response Status: ${response.statusCode}');
      print('Checkout Response Body: ${response.body}');

      if (response.statusCode == 200) {
        await clearCart();
        print('Checkout successful, cart cleared');
      } else {
        throw Exception('Checkout failed: ${response.body}');
      }
    } catch (e) {
      print('Error during checkout: $e');
      throw e;
    }
  }

  Future<void> checkoutSingleProduct(
    BuildContext context,
    Product product,
    int quantity,
  ) async {
    final token = _authService?.token;
    if (token == null || _authService == null) {
      throw Exception('User not authenticated');
    }

    try {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );
      final selectedAddress = addressProvider.selectedShippingAddress;
      if (selectedAddress == null) {
        throw Exception('No shipping address selected');
      }

      final orderItems = [
        {
          'productId': product.id,
          'quantity': quantity,
          'price': product.price * 0.9,
          'imageUrl': product.imageUrl,
        },
      ];

      final orderData = {
        'totalPrice': product.price * 0.9 * quantity,
        'items': orderItems,
        'shippingAddress': {
          'street': selectedAddress.street,
          'city': selectedAddress.city,
          'state': selectedAddress.state,
          'postalCode': selectedAddress.postalCode,
        },
      };

      print('Sending single product checkout request with data: $orderData');

      final response = await http.post(
        Uri.parse('${_authService!.baseUrl}/api/orders/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      print('Single Product Checkout Response Status: ${response.statusCode}');
      print('Single Product Checkout Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Checkout failed: ${response.body}');
      }
    } catch (e) {
      print('Error during single product checkout: $e');
      throw e;
    }
  }
}
