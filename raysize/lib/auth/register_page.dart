import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raysize/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedRole;

  Future<void> register() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email wajib diisi")));
      return;
    }

    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password wajib diisi")));
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal 6 karakter")),
      );
      return;
    }

    if (confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konfirmasi password wajib diisi")),
      );
      return;
    }

    if (selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Role belum dipilih")));
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password tidak sama")));
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({'email': emailController.text.trim(), 'role': selectedRole!});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Register Berhasil, silakan login")),
      );

      // 🔥 Delay sedikit supaya snackbar terlihat
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;

        case 'invalid-email':
          message = 'Format email tidak valid';
          break;

        case 'weak-password':
          message = 'Password minimal 6 karakter';
          break;

        default:
          message = e.message ?? 'Terjadi kesalahan';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.82;
    final cardHeight = size.height * 0.55;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 39),

                Image.asset('assets/images/raywise_logo.png', height: 80),

                const SizedBox(height: 10),

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

                Center(
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7C27D).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: const Alignment(0, 0.4),
                          child: Opacity(
                            opacity: 0.30,
                            child: Image.asset(
                              'assets/images/boneka2.png',
                              width: cardWidth * 0.98,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _field("Email", emailController),
                            const SizedBox(height: 12),

                            _field(
                              "Password",
                              passwordController,
                              isPassword: true,
                            ),
                            const SizedBox(height: 12),

                            _field(
                              "Re-Enter Password",
                              confirmPasswordController,
                              isPassword: true,
                            ),
                            const SizedBox(height: 12),

                            const Text(
                              "Role",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),

                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              hint: const Text("Pilih Role"),
                              items: const [
                                DropdownMenuItem(
                                  value: "admin",
                                  child: Text("Admin"),
                                ),
                                DropdownMenuItem(
                                  value: "hostlive",
                                  child: Text("Host Live"),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value;
                                });
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFFFF6CC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const Spacer(),

                            Center(
                              child: SizedBox(
                                width: 150,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB88700),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
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
              ],
            ),
          ),

          Positioned(
            left: -57,
            bottom: -30,
            child: Image.asset('assets/images/boneka2.png', height: 250),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
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
            controller: controller,
            obscureText: isPassword,
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
