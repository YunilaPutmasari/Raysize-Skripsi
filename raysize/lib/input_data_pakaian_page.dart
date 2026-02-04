import 'package:flutter/material.dart';

class InputDataPakaianPage extends StatelessWidget {
  const InputDataPakaianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Image.asset('assets/images/raywise_logo.png', height: 70),
            const SizedBox(height: 16),
            const Text(
              'Input Data Pakaian',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
