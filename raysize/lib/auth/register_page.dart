import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final cardWidth = size.width * 0.82;
    final cardHeight = size.height * 0.50;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
      body: Stack(
        children: [
          // ===== MAIN CONTENT =====
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 39),

                // LOGO (LEBIH KECIL & RAPI)
                Image.asset(
                  'assets/images/raywise_logo.png',
                  height: 80,
                ),

                const SizedBox(height: 10),

                // REGISTER TITLE
                const Text(
                  'REGISTER',
                  style: TextStyle(
                    fontSize: 27,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 28),

                // ===== CARD =====
                Center(
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                 padding: EdgeInsets.fromLTRB(20, 50, 20, 50),

                    decoration: BoxDecoration(
                      color: const Color(0xFFE7C27D).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        // BONEKA BESAR (LEBIH BESAR & PAS)
                        Align(
                          alignment: const Alignment(0, 0.4),
                          child: Opacity(
                            opacity: 0.30,
                            child: Image.asset(
                              'assets/images/boneka2.png',
                              width: cardWidth * 0.98, // 🔥 diperbesar
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // FORM
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field('Username'),
                            const SizedBox(height: 12),
                            _field('Password'),
                            const SizedBox(height: 12),
                            _field('Re-Enter Password'),
                            const Spacer(),

                            // BUTTON
                            Center(
                              child: SizedBox(
                                width: 150,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFB88700),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(24),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ===== BOTTOM NAV =====
                Container(
                  height: 64,
                  color: const Color(0xFFB88700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _NavItem(Icons.home, 'Home'),
                      _NavItem(Icons.history, 'History'),
                      _NavItem(Icons.person, 'Profile'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== BONEKA KECIL (MEPET KIRI & KEPOTONG) =====
          Positioned(
            left: -57, // 🔥 bikin kepotong
            bottom: 43, // di atas bottom nav
            child: Image.asset(
              'assets/images/boneka2.png',
              height: 180,
            ),
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
  style: TextStyle(
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
