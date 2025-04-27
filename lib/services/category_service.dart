import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryService extends ChangeNotifier {
  final String baseUrl = 'http://10.0.2.2:8080/api/categories';

  Future<List<Category>> fetchCategories(String token) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print(
      'Fetch categories response: ${response.statusCode} - ${response.body}',
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      print('Fetch categories error: ${response.body}');
      return [];
    }
  }

  Future<void> addCategory(String token, String name, String imageUrl) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'imageUrl': imageUrl}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add category: ${response.body}');
    }
  }

  Future<void> updateCategory(
    String token,
    int id,
    String name,
    String imageUrl,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'imageUrl': imageUrl}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  Future<void> deleteCategory(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }
}
