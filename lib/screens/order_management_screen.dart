import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_order_service.dart';
import '../services/auth_service.dart';
import '../models/order.dart';
import 'package:http/http.dart' as http;

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final AdminOrderService _adminOrderService = AdminOrderService();
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.token == null) {
        throw Exception('Authentication token is missing');
      }
      final orders = await _adminOrderService.fetchAllOrders(
        authService.token!,
      );
      setState(() {
        _orders =
            orders
                .where((order) => order.status.toUpperCase() != 'CANCELLED')
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await _adminOrderService.updateOrderStatus(
        authService.token!,
        orderId,
        status,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #$orderId status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeOrder(int orderId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/api/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer ${authService.token!}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$orderId removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchOrders();
      } else {
        throw Exception(
          'Failed to remove order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
                : _orders.isEmpty
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    String normalizedStatus = order.status.toUpperCase();
                    String displayStatus = _getDisplayStatus(normalizedStatus);
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  order.createdAt.toString().substring(0, 10),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: $displayStatus',
                              style: TextStyle(
                                fontSize: 16,
                                color: _getStatusColor(normalizedStatus),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Items: ${order.items.length}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            DropdownButton<String>(
                              value: _getValidDropdownValue(normalizedStatus),
                              isExpanded: true,
                              items:
                                  <String>[
                                    'ORDER_PLACED',
                                    'PROCESSING',
                                    'OUT_FOR_DELIVERY',
                                    'SHIPPED',
                                    'DELIVERED',
                                  ].map<DropdownMenuItem<String>>((
                                    String status,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(_getDisplayStatus(status)),
                                    );
                                  }).toList(),
                              onChanged: (String? newStatus) {
                                if (newStatus != null &&
                                    newStatus != normalizedStatus) {
                                  if (order.id != null) {
                                    _updateOrderStatus(order.id!, newStatus);
                                  }
                                }
                              },
                            ),
                            if (normalizedStatus == 'CANCELLED')
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => _removeOrder(order.id!),
                                  icon: Icon(Icons.delete, size: 18),
                                  label: Text('Remove Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade100,
                                    foregroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'ORDER_PLACED':
        return 'Order Placed';
      case 'PROCESSING':
        return 'Processing';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'SHIPPED':
        return 'Shipped';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getValidDropdownValue(String status) {
    final validStatuses = <String>[
      'ORDER_PLACED',
      'PROCESSING',
      'OUT_FOR_DELIVERY',
      'SHIPPED',
      'DELIVERED',
    ];
    return validStatuses.contains(status) ? status : 'ORDER_PLACED';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ORDER_PLACED':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blueAccent;
      case 'OUT_FOR_DELIVERY':
        return Colors.purple;
      case 'SHIPPED':
        return Colors.teal;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
