import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);

  CartService() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cart');
    if (cartData != null) {
      final List<dynamic> json = jsonDecode(cartData);
      _cartItems = json.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = jsonEncode(
      _cartItems.map((item) => item.toJson()).toList(),
    );
    await prefs.setString('cart', cartData);
  }

  void addToCart(CartItem item) {
    final existingItem = _cartItems.firstWhere(
      (i) => i.productId == item.productId,
      orElse: () => item,
    );
    if (_cartItems.contains(existingItem)) {
      existingItem.quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    _saveCart();
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final item = _cartItems.firstWhere((i) => i.productId == productId);
    if (quantity <= 0) {
      _cartItems.remove(item);
    } else {
      item.quantity = quantity;
    }
    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCart();
    notifyListeners();
  }
}
