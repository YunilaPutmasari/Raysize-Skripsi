import 'package:flutter/material.dart';

class RiwayatRekomendasiPage extends StatelessWidget {
  const RiwayatRekomendasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Image.asset('assets/images/raywise_logo.png', height: 70),
            const SizedBox(height: 16),
            const Text(
              'RIWAYAT REKOMENDASI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFFFF6CC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

        
          ],
        ),
      ),
    );
  }
}
