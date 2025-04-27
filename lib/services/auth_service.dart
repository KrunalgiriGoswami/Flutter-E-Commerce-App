import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rbac_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../providers/cart_provider.dart';

class AuthService with ChangeNotifier {
  final String baseUrl = AppConstants.baseUrl;
  CartProvider? _cartProvider;

  User? _user;
  String? _token;

  AuthService(this._cartProvider);

  void setCartProvider(CartProvider cartProvider) {
    _cartProvider = cartProvider;
  }

  User? get user => _user;
  String? get token => _token;

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    print('Login Response Status: ${response.statusCode}');
    print('Login Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = User.fromJson(data);
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('username', _user!.username);
      await prefs.setString('role', _user!.role);

      if (_cartProvider != null) {
        await _cartProvider!.fetchCartItems();
      }

      notifyListeners();
    } else {
      throw Exception(
        'Failed to login: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> signup(
    String username,
    String password,
    String email,
    String role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'role': role,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to signup');
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return false;
    }
    _token = prefs.getString('token');
    _user = User(
      username: prefs.getString('username') ?? '',
      token: _token ?? '',
      role: prefs.getString('role') ?? '',
    );
    if (_cartProvider != null) {
      await _cartProvider!.fetchCartItems();
    }
    notifyListeners();
    return true;
  }
}
