import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class OrderService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<List<Order>> fetchUserOrders(String token) async {
    print('Making request to fetch user orders...');
    print('Token used: $token');
    print('Full URL: $baseUrl/api/orders/user');
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Fetch User Orders Response Status: ${response.statusCode}');
    print('Fetch User Orders Response Headers: ${response.headers}');
    print('Fetch User Orders Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load orders: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> cancelOrder(String token, int orderId) async {
    print('Attempting to cancel order $orderId with token: $token');
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/cancel'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('Cancel Order Response Status: ${response.statusCode}');
    print('Cancel Order Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to cancel order: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> requestReturn(String token, int orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/return'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to request return: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteOrder(String token, int orderId) async {
    print('Attempting to delete order $orderId with token: $token');
    final response = await http.delete(
      Uri.parse('$baseUrl/api/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Delete Order Response Status: ${response.statusCode}');
    print('Delete Order Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete order: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
