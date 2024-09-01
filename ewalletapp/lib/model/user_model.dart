class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String email;
  double balance;

  UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.email,
    this.balance = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['fullName'],
      username: map['username'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      balance: map['balance']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'phoneNumber': phoneNumber,
      'email': email,
      'balance': balance,
    };
  }
}
