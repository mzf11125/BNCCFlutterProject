import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _recipientEmailController = TextEditingController();
  final _amountController = TextEditingController();

  Future<void> _makePayment() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    final recipientEmail = _recipientEmailController.text.trim();
    final paymentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (recipientEmail.isEmpty) {
      _showErrorSnackBar('Please enter the recipient\'s email.');
      return;
    }

    if (recipientEmail == user?.email) {
      _showErrorSnackBar('You cannot transfer money to yourself!');
      return;
    }

    if (paymentAmount <= 0) {
      _showErrorSnackBar('Please enter a valid payment amount.');
      return;
    }

    try {
      final recipient = await authService.getUserByEmail(recipientEmail);

      if (recipient == null) {
        _showErrorSnackBar('Recipient not found.');
        return;
      }

      final userBalance = await authService.getBalance();

      if (userBalance >= paymentAmount) {
        final confirm =
            await _showConfirmationDialog(recipientEmail, paymentAmount);

        if (confirm == true) {
          // Update sender's balance
          await authService.updateBalance(-paymentAmount);

          // Update recipient's balance
          await authService.updateRecipientBalance(recipient.id, paymentAmount);

          _showSuccessSnackBar('Payment successful to $recipientEmail!');

          _amountController.clear();
          _recipientEmailController.clear();
        }
      } else {
        _showErrorSnackBar('Insufficient balance! Please top up.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<bool?> _showConfirmationDialog(
      String recipientEmail, double paymentAmount) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Payment'),
          content: Text(
            'Are you sure you want to transfer \$${paymentAmount.toStringAsFixed(2)} to $recipientEmail?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                textStyle: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                textStyle: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        leading: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: IconThemeData(color: Colors.white),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Text('Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Current Balance',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${user?.balance.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildTextField(
                  controller: _recipientEmailController,
                  label: 'Recipient\'s Email',
                  icon: Icons.email,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _amountController,
                  label: 'Payment Amount',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _makePayment,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Send Payment',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
      ),
      keyboardType: keyboardType,
    );
  }
}
