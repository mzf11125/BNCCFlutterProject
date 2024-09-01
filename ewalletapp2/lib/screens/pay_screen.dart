import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _recipientEmailController = TextEditingController();

  Future<void> _makePayment() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final recipientEmail = _recipientEmailController.text.trim();

    if (recipientEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the recipient\'s email.')),
      );
      return;
    }

    if (recipientEmail == user!.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot transfer money to yourself!')),
      );
      return;
    }

    try {
      // Retrieve recipient data from Firestore
      final recipientSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: recipientEmail)
          .limit(1)
          .get();

      if (recipientSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipient not found.')),
        );
        return;
      }

      final recipientData = recipientSnapshot.docs.first;
      final recipientBalance = recipientData['balance'] ?? 0.0;

      if (user.balance > 0) {
        // Update sender's balance
        final senderDoc =
            FirebaseFirestore.instance.collection('users').doc(user.id);
        senderDoc
            .update({'balance': user.balance - 10}); // Example payment amount

        // Update recipient's balance
        final recipientDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(recipientData.id);
        recipientDoc.update({'balance': recipientBalance + 10});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful to $recipientEmail!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Insufficient balance! Please top up.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text('Payment'),
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
              controller: _recipientEmailController,
              decoration: InputDecoration(
                labelText: 'Recipient\'s Email',
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _makePayment,
              child: Text('Send Payment'),
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
