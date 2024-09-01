import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(authService.user!.id)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data();
      setState(() {
        authService.user!.balance = userData!['balance']?.toDouble() ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName ?? 'User'}!',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Your balance is \$${user?.balance.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  _buildButton(context, 'Payment', Icons.payment, '/payment'),
                  _buildButton(context, 'Top Up', Icons.add_card, '/topup'),
                  _buildButton(context, 'Edit Profile', Icons.edit, '/profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, String label, IconData icon, String route) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Colors.blueAccent, // Use backgroundColor instead of primary
        foregroundColor:
            Colors.white, // Use foregroundColor instead of onPrimary
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32.0),
          const SizedBox(height: 8.0),
          Text(label),
        ],
      ),
    );
  }
}
