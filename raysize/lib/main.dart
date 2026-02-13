import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raysize/admin/admin_main_page.dart';
import 'package:raysize/host/host_main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'auth/login_page.dart';
import '/home_admin_page.dart';
import '/home_host_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RaysizeApp());
}

class RaysizeApp extends StatelessWidget {
  const RaysizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthChecker(),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

Future<void> checkLogin() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  } else {
    // 🔥 Ambil role langsung dari Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String role = doc['role'];

  if (role == "admin") {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const AdminMainPage()),
  );
} else {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const HostMainPage()),
  );
}

  }
}


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
