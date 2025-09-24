import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart'; // <-- Add this

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance; // <-- Add this

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (usernameController.text.isEmpty || email.isEmpty || password.isEmpty) {
      _showDialog("Please fill all fields.");
      return;
    }

    setState(() => isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showDialog("Invalid username or password.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showDialog("Please enter your email to reset password.");
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Reset Password?"),
        content: Text("We’ll send a reset link to $email. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Firebase password reset email
                await _auth.sendPasswordResetEmail(email: email);

                // Call Cloud Function to send custom email & SMS
                final HttpsCallable sendCustomEmail = _functions.httpsCallable('sendEmail');
                final HttpsCallable sendCustomSMS = _functions.httpsCallable('sendSMS');

                await sendCustomEmail.call(<String, dynamic>{
                  'to': email,
                  'subject': 'Password Reset Request',
                  'message': 'You requested a password reset. Please check Firebase email to reset your password.'
                });

                await sendCustomSMS.call(<String, dynamic>{
                  'to': '+91XXXXXXXXXX', // <-- Replace with user phone if stored in DB
                  'message': 'Your password reset request has been processed. Check your email!'
                });

                _showDialog("✅ Password reset link sent to $email (and SMS notified).");
              } catch (e) {
                _showDialog("❌ Error sending reset email/SMS: $e");
              }
            },
            child: Text("Send"),
          )
        ],
      ),
    );
  }

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: EdgeInsets.all(24),
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 60, color: Colors.red),
                  SizedBox(height: 10),
                  Text("Login to Continue",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: Text("Forgot Password?"),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Login"),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: Text("New user? Create an account"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
