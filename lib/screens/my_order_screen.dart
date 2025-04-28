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

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        _animationController.forward(from: 0);
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
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
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

  Future<void> _deleteOrder(int orderId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      print(
        'Attempting to delete order $orderId with token: ${authService.token}',
      );
      await OrderService().deleteOrder(authService.token!, orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchOrders();
    } catch (e) {
      print('Failed to delete order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete order: $e'),
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
    String statusMessage = _getStatusMessage(normalizedStatus);

    double subtotal = order.items.fold(
      0.0,
      (sum, item) => sum + (item.price * 0.9 * item.quantity),
    );
    double deliveryCharge = 0;
    double originalDeliveryCharge = 0;
    if (subtotal < 100) {
      deliveryCharge = 50;
      originalDeliveryCharge = 50;
    } else if (subtotal < 300) {
      deliveryCharge = 30;
      originalDeliveryCharge = 30;
    } else {
      deliveryCharge = 0;
      originalDeliveryCharge = 30;
    }
    double totalPrice = subtotal + deliveryCharge;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            isNewOrder
                ? BorderSide(color: Colors.green.shade700, width: 2)
                : BorderSide.none,
      ),
      color:
          Colors.white, // Ensure card background is white to avoid black lines
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent), // Remove default divider
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.all(16),
          leading: Icon(
            Icons.local_mall,
            color: _getStatusColor(normalizedStatus),
            size: 30,
          ),
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
                Text(
                  statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(normalizedStatus),
                  ),
                ),
              ],
            ),
          ),
          children: [
            Divider(
              color: Colors.grey.shade300,
              thickness: 1,
            ), // Custom divider with light color
            _buildStatusTimeline(order, normalizedStatus),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white, // Ensure card background is white
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      height: order.items.length == 1 ? 120.0 : 240.0,
                      child: ListView.builder(
                        physics: ClampingScrollPhysics(),
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          final double itemTotal =
                              item.price * 0.9 * item.quantity;
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color:
                                Colors.white, // Ensure card background is white
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        item.imageUrl != null &&
                                                item.imageUrl!.isNotEmpty
                                            ? Image.network(
                                              item.imageUrl!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons.error,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            )
                                            : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Quantity: ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Total: ₹${itemTotal.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          '₹${subtotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Charge:',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Row(
                          children: [
                            if (deliveryCharge == 0 && subtotal >= 300)
                              Text(
                                '₹$originalDeliveryCharge',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            SizedBox(width: 4),
                            Text(
                              deliveryCharge == 0
                                  ? 'Free Delivery ₹0'
                                  : '₹${deliveryCharge.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    deliveryCharge == 0
                                        ? Colors.green.shade700
                                        : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(
                      color: Colors.grey.shade300,
                      thickness: 1,
                    ), // Custom divider with light color
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '₹${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white, // Ensure card background is white
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      order.shippingAddress.street == 'N/A' &&
                              order.shippingAddress.city == 'N/A' &&
                              order.shippingAddress.state == 'N/A' &&
                              order.shippingAddress.postalCode == 'N/A' &&
                              order.shippingAddress.country == 'N/A'
                          ? 'Address not available'
                          : '${order.shippingAddress.street}, ${order.shippingAddress.city}, ${order.shippingAddress.state} - ${order.shippingAddress.postalCode}, ${order.shippingAddress.country}',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (normalizedStatus == 'ORDER_PLACED' ||
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
                SizedBox(width: 8),
                if (normalizedStatus == 'DELIVERED' ||
                    normalizedStatus == 'CANCELLED') ...[
                  ElevatedButton.icon(
                    onPressed:
                        normalizedStatus == 'DELIVERED'
                            ? () => _requestReturn(order.id!)
                            : null,
                    icon: Icon(Icons.undo, size: 18),
                    label: Text('Request Return'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _deleteOrder(order.id!),
                    icon: Icon(Icons.delete, size: 18),
                    label: Text('Delete Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(Order order, String currentStatus) {
    final List<String> allStatuses = [
      'ORDER_PLACED',
      'PROCESSING',
      'OUT_FOR_DELIVERY',
      'SHIPPED',
      'DELIVERED',
    ];

    final Map<String, String> stageLabels = {
      'ORDER_PLACED': 'Order Placed',
      'PROCESSING': 'Processing',
      'OUT_FOR_DELIVERY': 'Out for Delivery',
      'SHIPPED': 'Shipped',
      'DELIVERED': 'Delivered',
    };

    final List<StatusHistory> history = order.statusHistory.reversed.toList();
    final Set<String> completedStatuses =
        history.map((h) => h.status.toUpperCase()).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children:
                allStatuses.map((status) {
                  final isCompleted = completedStatuses.contains(status);
                  final matchingHistory = history.firstWhere(
                    (h) => h.status.toUpperCase() == status,
                    orElse:
                        () => StatusHistory(
                          status: status,
                          timestamp: order.createdAt,
                        ),
                  );
                  final isLast = status == currentStatus;

                  return TimelineTile(
                    alignment: TimelineAlign.start,
                    isFirst: status == allStatuses.first,
                    isLast: status == allStatuses.last,
                    indicatorStyle: IndicatorStyle(
                      width: 20,
                      height: 20,
                      color:
                          isCompleted
                              ? _getStatusColor(status)
                              : Colors.grey.shade300,
                      iconStyle:
                          isCompleted
                              ? IconStyle(
                                iconData: Icons.check,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    beforeLineStyle: LineStyle(
                      thickness: 2,
                      color:
                          isCompleted ||
                                  (allStatuses.indexOf(status) <
                                      allStatuses.indexOf(currentStatus))
                              ? _getStatusColor(status)
                              : Colors.grey.shade300,
                    ),
                    afterLineStyle: LineStyle(
                      thickness: 2,
                      color:
                          isCompleted ||
                                  (allStatuses.indexOf(status) <=
                                      allStatuses.indexOf(currentStatus))
                              ? _getStatusColor(status)
                              : Colors.grey.shade300,
                    ),
                    endChild: Padding(
                      padding: EdgeInsets.only(left: 16, top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stageLabels[status] ?? status,
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompleted ? Colors.black87 : Colors.grey,
                              fontWeight:
                                  isLast ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(matchingHistory.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted ? Colors.black54 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'DELIVERED':
        return 'Order Completed and Delivered';
      case 'CANCELLED':
        return 'Order Cancelled';
      case 'RETURNED':
        return 'Order Returned';
      case 'ORDER_PLACED':
      case 'SHIPPED':
        return 'Order can be Cancelled';
      default:
        return 'Order in Progress: $status';
    }
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
      case 'RETURNED':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
}
