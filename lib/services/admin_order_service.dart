import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';

class AdminOrderService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<List<Order>> fetchAllOrders(String token) async {
    print('Fetching all orders with token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Fetch All Orders Response Status: ${response.statusCode}');
    print('Fetch All Orders Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load orders: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> updateOrderStatus(
    String token,
    int orderId,
    String status,
  ) async {
    print('Updating order $orderId to status: $status with token: $token');
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status}),
    );

    print('Update Order Status Response Status: ${response.statusCode}');
    print('Update Order Status Response Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update order status: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
