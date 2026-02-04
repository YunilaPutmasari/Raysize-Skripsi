import 'package:flutter/material.dart';

import 'input_data_anak_page.dart';
import 'input_data_pakaian_page.dart';
import 'riwayat_rekomendasi_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            Image.asset(
              'assets/images/raywise_logo.png',
              height: 80,
            ),

            const SizedBox(height: 16),

            const Text(
              'Home',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            _MenuCard(
              icon: Icons.child_care,
              title: 'Input Data Anak',
              subtitle: 'Masukkan data anak untuk rekomendasi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InputDataAnakPage(),
                  ),
                );
              },
            ),

            _MenuCard(
              icon: Icons.checkroom,
              title: 'Input Data Pakaian',
              subtitle: 'Kelola data pakaian & size',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InputDataPakaianPage(),
                  ),
                );
              },
            ),

            _MenuCard(
              icon: Icons.history,
              title: 'Riwayat Rekomendasi',
              subtitle: 'Lihat hasil rekomendasi sebelumnya',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiwayatRekomendasiPage(),
                  ),
                );
              },
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// 👇 TARUH DI SINI
class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE7C27D).withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFB88700),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
