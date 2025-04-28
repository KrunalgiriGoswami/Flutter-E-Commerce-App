class Order {
  final int? id;
  final int userId;
  final double totalAmount;
  final DateTime createdAt;
  final String status;
  final ShippingAddress shippingAddress;
  final List<OrderItem> items;
  final List<StatusHistory> statusHistory;

  Order({
    this.id,
    required this.userId,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'Pending',
    required this.shippingAddress,
    required this.items,
    required this.statusHistory,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      userId: json['userId'] as int,
      totalAmount: (json['totalPrice'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'ORDER_PLACED',
      shippingAddress: ShippingAddress.fromJson(
        json['shippingAddress'] as Map<String, dynamic>? ?? {},
      ),
      items:
          (json['items'] as List<dynamic>? ?? [])
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList(),
      statusHistory:
          (json['statusHistory'] as List<dynamic>? ?? [])
              .map(
                (history) =>
                    StatusHistory.fromJson(history as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;

  StatusHistory({required this.status, required this.timestamp});

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
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

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street'] as String? ?? 'N/A',
      city: json['city'] as String? ?? 'N/A',
      state: json['state'] as String? ?? 'N/A',
      postalCode: json['postalCode'] as String? ?? 'N/A',
      country: json['country'] as String? ?? 'N/A',
    );
  }
}

class OrderItem {
  final int? id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl; // New field

  OrderItem({
    this.id,
    required this.productId,
    this.name = 'Unknown Product',
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      productId: json['productId'] as int,
      name: json['name'] as String? ?? 'Product ${json['productId']}',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
