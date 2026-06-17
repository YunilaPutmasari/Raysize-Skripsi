import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';

class AuthService {

  // Logout saja
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // Logout + langsung kembali ke LoginPage
  static Future<void> logoutAndRedirect(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
