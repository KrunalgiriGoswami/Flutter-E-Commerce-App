import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../providers/address_provider.dart';
import 'address_management_screen.dart';
import 'success_screen.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<Product, int> cartItems;
  final Product? singleProduct;
  final int? singleQuantity;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    this.singleProduct,
    this.singleQuantity,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final selectedAddress = addressProvider.selectedShippingAddress;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final orderService = OrderService();

    final bool isBuyNow =
        widget.singleProduct != null && widget.singleQuantity != null;
    final List<MapEntry<Product, int>> itemsToDisplay =
        isBuyNow
            ? [MapEntry(widget.singleProduct!, widget.singleQuantity!)]
            : widget.cartItems.entries.toList();
    final double subtotal =
        isBuyNow
            ? widget.singleProduct!.price * 0.9 * widget.singleQuantity!
            : cartProvider.getTotalPrice();
    final int totalQuantity = itemsToDisplay.fold(
      0,
      (sum, item) => sum + item.value,
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
    final double totalPrice = subtotal + deliveryCharge;

    double orderSummaryHeight = itemsToDisplay.length == 1 ? 120.0 : 240.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Checkout'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: orderSummaryHeight,
                child: ListView.builder(
                  physics: ClampingScrollPhysics(),
                  itemCount: itemsToDisplay.length,
                  itemBuilder: (context, index) {
                    final product = itemsToDisplay[index].key;
                    final quantity = itemsToDisplay[index].value;
                    final double itemTotal = product.price * 0.9 * quantity;
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  product.imageUrl != null
                                      ? Image.network(
                                        product.imageUrl!,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Quantity: $quantity',
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
              SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cart Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Items:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '$totalQuantity',
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
                            'Subtotal:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
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
                      Divider(),
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
              SizedBox(height: 24),
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              selectedAddress == null
                  ? Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'No shipping address selected. Please add one in your profile.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade600),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddressManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                  : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedAddress.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${selectedAddress.street}, ${selectedAddress.city}, ${selectedAddress.state} - ${selectedAddress.postalCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Phone: ${selectedAddress.phoneNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue.shade600,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddressManagementScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              SizedBox(height: 24),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Cash on Delivery'),
                        leading: Radio<String>(
                          value: 'Cash on Delivery',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Card'),
                        leading: Radio<String>(
                          value: 'Card',
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              GestureDetector(
                onTap:
                    selectedAddress == null || _selectedPaymentMethod == null
                        ? null
                        : () async {
                          try {
                            print('Starting checkout process...');
                            if (isBuyNow) {
                              print('Performing single product checkout...');
                              await cartProvider.checkoutSingleProduct(
                                context,
                                widget.singleProduct!,
                                widget.singleQuantity!,
                              );
                            } else {
                              print('Performing cart checkout...');
                              await cartProvider.checkout(context);
                            }
                            print('Checkout completed successfully.');

                            print(
                              'Fetching user orders with token: ${authService.token}',
                            );
                            final orders = await orderService.fetchUserOrders(
                              authService.token!,
                            );
                            final latestOrder =
                                orders.isNotEmpty
                                    ? orders.reduce(
                                      (a, b) =>
                                          a.createdAt.isAfter(b.createdAt)
                                              ? a
                                              : b,
                                    )
                                    : null;
                            print(
                              'Latest order fetched: ${latestOrder?.id ?? "null"}',
                            );

                            if (latestOrder == null) {
                              print(
                                'No latest order found, proceeding with null order.',
                              );
                            }

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        SuccessScreen(order: latestOrder),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            print('Checkout or order fetch error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Checkout or order fetch failed: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          selectedAddress == null ||
                                  _selectedPaymentMethod == null
                              ? [Colors.grey.shade400, Colors.grey.shade300]
                              : [Colors.green.shade600, Colors.green.shade400],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color:
                            selectedAddress == null ||
                                    _selectedPaymentMethod == null
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.green.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Confirm Order',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
