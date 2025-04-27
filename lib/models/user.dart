class User {
  final String username;
  final String token;
  final String role;

  User({required this.username, required this.token, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      token: json['token'],
      role: json['role'],
    );
  }
}
