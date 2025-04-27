import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../constants.dart'; // Add this import

class ProductService {
  final String baseUrl = AppConstants.baseUrl;

  Future<List<Product>> fetchProducts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print(
      'Fetch all products response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      print('Fetch all products error: ${response.body}');
      return [];
    }
  }

  Future<List<Product>> fetchProductsByCategory(
    String token,
    int categoryId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/category/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print(
      'Fetch products by category $categoryId response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      print('Fetch products by category error: ${response.body}');
      return [];
    }
  }

  Future<List<Product>> searchProducts(String token, String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/search?query=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print(
      'Search products response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      print('Search products error: ${response.body}');
      return [];
    }
  }

  Future<void> addProduct(String token, Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'categoryId': product.categoryId,
        'imageUrl': product.imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add product: ${response.body}');
    }
  }

  Future<void> updateProduct(String token, Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/products/${product.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'categoryId': product.categoryId,
        'imageUrl': product.imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }
}
