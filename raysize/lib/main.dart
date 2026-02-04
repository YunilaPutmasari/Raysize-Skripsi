import 'package:flutter/material.dart';
import 'package:raysize/home_page.dart';
import 'auth/register_page.dart';
import 'input_data_anak_page.dart';

void main() {
  runApp(const RaysizeApp());
}

class RaysizeApp extends StatelessWidget {
  const RaysizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: RegisterPage(),
      // home: InputDataAnakPage(),
      home: HomePage(),
    );
  }
}
