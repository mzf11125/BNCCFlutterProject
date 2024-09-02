import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;

  UserModel? get user => _user;

  Future<bool> signUp({
    required String fullName,
    required String username,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        id: result.user!.uid,
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        email: email,
        balance: 0, // Initialize balance
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      _user = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await fetchAndSetUser(result.user!.uid);
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // Fetch and set the latest user data
  Future<void> fetchAndSetUser(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      _user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      notifyListeners();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Update user balance
  Future<void> updateBalance(double amount) async {
    if (_user != null) {
      final userDocRef = _firestore.collection('users').doc(_user!.id);
      final userDoc = await userDocRef.get();
      final currentBalance = userDoc['balance']?.toDouble() ?? 0.0;
      final newBalance = currentBalance + amount;

      try {
        await userDocRef.update({'balance': newBalance});
        _user = _user!.copyWith(balance: newBalance); // Update local UserModel
        notifyListeners();
      } catch (e) {
        print('Error updating balance: $e');
      }
    }
  }

  // Fetch user balance
  Future<double> getBalance() async {
    if (_user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(_user!.id).get();
      return doc['balance']?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user by email: $e');
      return null;
    }
  }

  // Update recipient balance
  Future<void> updateRecipientBalance(String recipientId, double amount) async {
    try {
      final recipientDocRef = _firestore.collection('users').doc(recipientId);
      final recipientDoc = await recipientDocRef.get();
      final recipientBalance = recipientDoc['balance']?.toDouble() ?? 0.0;
      final newRecipientBalance = recipientBalance + amount;

      await recipientDocRef.update({'balance': newRecipientBalance});
    } catch (e) {
      print('Error updating recipient balance: $e');
    }
  }

  Future<void> updateProfile(
      String fullName, String username, String phoneNumber) async {
    final user = _user;
    if (user == null) throw Exception('No user is logged in');

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'fullName': fullName,
        'username': username,
        'phoneNumber': phoneNumber,
      });

      // Update the user object if needed
      _user = _user!.copyWith(
          fullName: fullName, username: username, phoneNumber: phoneNumber);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}
