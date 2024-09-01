import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class TopUpScreen extends StatefulWidget {
  @override
  _TopUpScreenState createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountController = TextEditingController();

  Future<void> _topUpBalance() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final topUpAmount = double.tryParse(_amountController.text.trim());

    if (topUpAmount == null || topUpAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    try {
      // Update user's balance in Firestore
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user!.id);
      await userDoc.update({'balance': user.balance + topUpAmount});

      // Update local user balance
      user.balance += topUpAmount;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Top-up successful! Your new balance is \$${user.balance.toStringAsFixed(2)}.'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the input field
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your current balance is \$${user?.balance.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24.0),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Amount to Top Up',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _topUpBalance,
              child: Text('Top Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
