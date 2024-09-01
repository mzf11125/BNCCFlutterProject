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
  final _amountController = TextEditingController();
  late Future<double> _userBalanceFuture;

  @override
  void initState() {
    super.initState();
    _userBalanceFuture = _fetchUserBalance();
  }

  Future<double> _fetchUserBalance() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.id)
        .get();
    return userDoc['balance']?.toDouble() ?? 0.0;
  }

  Future<void> _makePayment() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final recipientEmail = _recipientEmailController.text.trim();
    final paymentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;

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

    if (paymentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid payment amount.')),
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
      final recipientBalance = recipientData['balance']?.toDouble() ?? 0.0;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();
      final userBalance = userDoc['balance']?.toDouble() ?? 0.0;

      if (userBalance >= paymentAmount) {
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirm Payment'),
              content: Text(
                'Are you sure you want to transfer \$${paymentAmount.toStringAsFixed(2)} to ${recipientEmail}?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            );
          },
        );

        if (confirm == true) {
          // Update sender's balance by subtracting the payment amount
          final senderDoc =
              FirebaseFirestore.instance.collection('users').doc(user.id);
          await senderDoc.update({'balance': userBalance - paymentAmount});

          // Update recipient's balance by adding the payment amount
          final recipientDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(recipientData.id);
          await recipientDoc
              .update({'balance': recipientBalance + paymentAmount});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment successful to $recipientEmail!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the user's balance
          setState(() {
            _userBalanceFuture = _fetchUserBalance();
          });
        }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<double>(
              future: _userBalanceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final balance = snapshot.data ?? 0.0;
                  return Text(
                    'Your current balance is \$${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.grey[600],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24.0),
            TextField(
              controller: _recipientEmailController,
              decoration: InputDecoration(
                labelText: 'Recipient\'s Email',
              ),
            ),
            const SizedBox(height: 24.0),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
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
