import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/user_model.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _fullName;
  String? _username;
  String? _phoneNumber;
  String? _email;
  double? _balance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: user?.fullName,
                      decoration: InputDecoration(labelText: 'Full Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                      onSaved: (value) => _fullName = value,
                    ),
                    TextFormField(
                      initialValue: user?.username,
                      decoration: InputDecoration(labelText: 'Username'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                      onSaved: (value) => _username = value,
                    ),
                    TextFormField(
                      initialValue: user?.phoneNumber,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                      onSaved: (value) => _phoneNumber = value,
                    ),
                    TextFormField(
                      initialValue: user?.email,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onSaved: (value) => _email = value,
                    ),
                    TextFormField(
                      initialValue: user?.balance.toString(),
                      decoration: InputDecoration(labelText: 'Balance'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onSaved: (value) => _balance = double.tryParse(value!),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Save'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() {
                            _isLoading = true;
                          });

                          // Create a new user model with the updated data
                          final updatedUser = UserModel(
                            id: user!.id,
                            fullName: _fullName ?? user.fullName,
                            username: _username ?? user.username,
                            phoneNumber: _phoneNumber ?? user.phoneNumber,
                            email: _email ?? user.email,
                            balance: _balance ?? user.balance,
                          );

                          try {
                            // Save the updated user data to Firestore
                            await updatedUser.saveToFirestore();

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Profile updated successfully!')),
                            );

                            // Navigate back to the previous screen
                            Navigator.pop(context);
                          } catch (e) {
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('An error occurred: $e')),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
