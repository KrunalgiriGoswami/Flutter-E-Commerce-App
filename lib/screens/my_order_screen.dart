import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:rbac_app/screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class MyOrdersScreen extends StatefulWidget {
  final Order? newOrder;

  const MyOrdersScreen({Key? key, this.newOrder}) : super(key: key);

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchOrders();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Fetching orders with token: ${authService.token}');
      final orders = await OrderService().fetchUserOrders(authService.token!);
      setState(() {
        _orders = orders;
        if (widget.newOrder != null &&
            !_orders.any((order) => order.id == widget.newOrder!.id)) {
          _orders.insert(0, widget.newOrder!);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      print(
        'Attempting to cancel order $orderId with token: ${authService.token}',
      );
      await OrderService().cancelOrder(authService.token!, orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #$orderId cancelled successfully'),
              Icon(Icons.check_circle, color: Colors.white),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await _fetchOrders();
    } catch (e) {
      print('Failed to cancel order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestReturn(int orderId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await OrderService().requestReturn(authService.token!, orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Return request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchOrders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to request return: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
                : _orders.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_mall_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final bool isNewOrder =
                        widget.newOrder != null &&
                        order.id == widget.newOrder!.id;
                    String normalizedStatus = order.status.toUpperCase();
                    return _buildOrderCard(order, isNewOrder, normalizedStatus);
                  },
                ),
      ),
    );
  }

  Widget _buildOrderCard(
    Order order,
    bool isNewOrder,
    String normalizedStatus,
  ) {
    Color statusColor = _getStatusColor(normalizedStatus);
    String statusText = _getStatusText(normalizedStatus);

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            isNewOrder
                ? BorderSide(color: Colors.green.shade700, width: 2)
                : BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.all(16),
        leading: Icon(Icons.local_mall, color: statusColor, size: 30),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Order #${order.id}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(order.createdAt),
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          Divider(),
          _buildStatusTimeline(normalizedStatus),
          SizedBox(height: 16),
          Text(
            'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Shipping Address:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${order.shippingAddress.street}, ${order.shippingAddress.city}, ${order.shippingAddress.state} - ${order.shippingAddress.postalCode}, ${order.shippingAddress.country}',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          SizedBox(height: 16),
          Text(
            'Items:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (normalizedStatus == 'PENDING' ||
                  normalizedStatus == 'SHIPPED')
                ElevatedButton.icon(
                  onPressed: () => _cancelOrder(order.id!),
                  icon: Icon(Icons.cancel, size: 18),
                  label: Text('Cancel Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              if (normalizedStatus == 'DELIVERED')
                ElevatedButton.icon(
                  onPressed: () => _requestReturn(order.id!),
                  icon: Icon(Icons.undo, size: 18),
                  label: Text('Request Return'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status) {
    final List<String> stages = [
      'PENDING',
      'PROCESSING',
      'OUT_FOR_DELIVERY',
      'SHIPPED',
      'DELIVERED',
    ];
    final List<String> stageLabels = [
      'Order Placed',
      'Processing',
      'Out for Delivery',
      'Shipped',
      'Delivered',
    ];
    int currentIndex = stages.indexOf(status);

    if (status == 'CANCELLED' || status == 'RETURNED') {
      currentIndex = stages.length - 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Column(
          children: List.generate(stages.length, (index) {
            return TimelineTile(
              alignment: TimelineAlign.start,
              isFirst: index == 0,
              isLast: index == stages.length - 1,
              indicatorStyle: IndicatorStyle(
                width: 20,
                height: 20,
                color:
                    index <= currentIndex
                        ? _getStatusColor(status)
                        : Colors.grey.shade300,
                iconStyle:
                    index <= currentIndex
                        ? IconStyle(iconData: Icons.check, color: Colors.white)
                        : null,
              ),
              beforeLineStyle: LineStyle(
                thickness: 2,
                color:
                    index <= currentIndex
                        ? _getStatusColor(status)
                        : Colors.grey.shade300,
              ),
              afterLineStyle: LineStyle(
                thickness: 2,
                color:
                    index < currentIndex
                        ? _getStatusColor(status)
                        : Colors.grey.shade300,
              ),
              endChild: Padding(
                padding: EdgeInsets.only(left: 16, top: 8),
                child: Text(
                  stageLabels[index],
                  style: TextStyle(
                    fontSize: 14,
                    color: index <= currentIndex ? Colors.black87 : Colors.grey,
                    fontWeight:
                        index <= currentIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'RETURNED':
        return 'Returned';
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'SHIPPED':
        return 'Shipped';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
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
      case 'RETURNED':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
}
