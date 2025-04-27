class Address {
  final String id; // Unique identifier for the address
  final String name;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String phoneNumber;

  Address({
    required this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'phoneNumber': phoneNumber,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name'],
      street: json['street'],
      city: json['city'],
      state: json['state'],
      postalCode: json['postalCode'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
