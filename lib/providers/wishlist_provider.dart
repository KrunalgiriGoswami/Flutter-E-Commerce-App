import 'package:flutter/material.dart';
import '../models/product.dart';

class WishlistProvider with ChangeNotifier {
  final List<Product> _wishlistItems = [];

  List<Product> get wishlistItems => _wishlistItems;

  bool isInWishlist(Product product) {
    return _wishlistItems.any((item) => item.id == product.id);
  }

  void addToWishlist(Product product) {
    if (!isInWishlist(product)) {
      _wishlistItems.add(product);
      notifyListeners();
    }
  }

  void removeFromWishlist(Product product) {
    _wishlistItems.removeWhere((item) => item.id == product.id);
    notifyListeners();
  }

  void clearWishlist() {
    _wishlistItems.clear();
    notifyListeners();
  }
}
