import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Copy with method to create a new instance with updated properties
  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? email,
    double? balance,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      balance: balance ?? this.balance,
    );
  }

  // Fetch user data from Firestore
  static Future<UserModel?> getUserById(String userId) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      return UserModel.fromMap(docSnapshot.data()!);
    }
    return null;
  }

  // Save user data to Firestore
  Future<void> saveToFirestore() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(id);
    await docRef.set(toMap());
  }
}
