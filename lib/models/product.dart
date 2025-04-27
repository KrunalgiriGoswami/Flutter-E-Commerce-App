class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final int categoryId;
  final String? imageUrl;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'categoryId': categoryId,
    'imageUrl': imageUrl,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int?,
    name: json['name'] as String,
    description: json['description'] as String,
    price: json['price'] as double,
    categoryId: json['categoryId'] as int,
    imageUrl: json['imageUrl'] as String?,
  );
}
