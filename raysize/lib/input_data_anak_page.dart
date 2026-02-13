import 'package:flutter/material.dart';

class InputDataAnakPage extends StatelessWidget {
  const InputDataAnakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.82;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
      body: Stack(
        children: [
          // ===== MAIN CONTENT =====
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // LOGO
                Image.asset('assets/images/raywise_logo.png', height: 80),

                const SizedBox(height: 16),

                const Text(
                  'Input Data Anak',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 24),

                // ===== CARD FORM =====
                Center(
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7C27D).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        // BONEKA WATERMARK
                        Align(
                          alignment: const Alignment(0, 0.5),
                          child: Opacity(
                            opacity: 0.25,
                            child: Image.asset(
                              'assets/images/boneka2.png',
                              width: cardWidth * 0.9,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field('Usia'),
                            const SizedBox(height: 10),
                            _field('Berat Badan'),
                            const SizedBox(height: 10),
                            _field('Tinggi Badan'),
                            const SizedBox(height: 10),
                            _field('Jenis Kelamin'),
                            const SizedBox(height: 10),
                            _field('Brand / Nama Pakaian'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // BUTTON
                SizedBox(
                  width: 200,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: ke halaman hasil rekomendasi
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB88700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Proses Rekomendasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),

          // ===== BONEKA KECIL KIRI BAWAH =====
          Positioned(
            left: -57,
            bottom: -30,
            child: Image.asset('assets/images/boneka2.png', height: 200),
          ),
        ],
      ),
    );
  }

  Widget _field(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFFF6CC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
