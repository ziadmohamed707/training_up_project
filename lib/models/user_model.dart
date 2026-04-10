class UserModel {
  final int? id;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String fullName;
  final String? token;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    required this.fullName,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      fullName: json['full_name'] ?? '',
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'full_name': fullName,
      'token': token,
    };
  }
}
