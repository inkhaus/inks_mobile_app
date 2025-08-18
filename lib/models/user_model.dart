class UserModel {
  final String? id;
  final String email;
  final String accountType;
  final String createdAt;
  final String? password;

  UserModel({
    this.id,
    required this.email,
    required this.accountType,
    required this.createdAt,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      accountType: json['accountType'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'accountType': accountType,
      'createdAt': createdAt,
    };
    
    if (password != null) {
      data['password'] = password;
    }
    
    return data;
  }
}