class Order {
  final int? id;
  final int userId;
  final double totalAmount;
  final DateTime createdAt;
  final String status;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;

  Order({
    this.id,
    required this.userId,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'Pending',
    required this.shippingAddress,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      totalAmount: (json['totalPrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: 'Pending', // Backend doesn't return status; set default
      shippingAddress:
          ShippingAddress.dummy(), // Backend doesn't return shipping address; use dummy
      items:
          (json['items'] as List<dynamic>)
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class OrderItem {
  final int? id;
  final int productId;
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    this.id,
    required this.productId,
    this.name = 'Unknown Product',
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      productId: json['productId'] as int,
      name:
          'Product ${json['productId']}', // Backend doesn't return name; use placeholder
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

class ShippingAddress {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  ShippingAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });

  factory ShippingAddress.dummy() {
    return ShippingAddress(
      street: 'N/A',
      city: 'N/A',
      state: 'N/A',
      postalCode: 'N/A',
      country: 'N/A',
    );
  }
}
