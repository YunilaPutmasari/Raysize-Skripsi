import 'package:flutter/material.dart';
import 'admin/input_data_anak_page.dart';
import 'admin/riwayat_rekomendasi_page.dart';
import '../widgets/bottom_navbar.dart';
import '/profile.dart';

class HomeHostPage extends StatelessWidget {
  const HomeHostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),

      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB88700), Color(0xFFFFD54F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/raywise_logo.png', height: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Halo Host 👋",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Siap membantu menemukan size terbaik hari ini?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(179, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= ILUSTRASI =================
            Image.asset('assets/images/boneka2.png', height: 150),

            const SizedBox(height: 30),

            // ================= MENU CARD =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _FeatureCard(
                icon: Icons.child_care,
                title: "Rekomendasi Size",
                subtitle: "Masukkan data anak untuk mendapatkan size terbaik",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InputDataAnakPage(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _FeatureCard(
                icon: Icons.history,
                title: "Riwayat Rekomendasi",
                subtitle: "Lihat hasil rekomendasi sebelumnya",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiwayatRekomendasiPage(),
                    ),
                  );
                },
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ================= FEATURE CARD =================
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: const Color(0xFFB88700),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
