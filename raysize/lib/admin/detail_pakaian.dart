import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raysize/admin/home_admin_page.dart';

class DetailPakaianPage extends StatefulWidget {
  final String brand;
  final String nama;
  final String jenis;
  final String jenisBahan;
  final String sizeType;
  final List<String> sizes;
  final int currentIndex;
  final List<Map<String, dynamic>> sizeData;

  const DetailPakaianPage({
    super.key,
    required this.brand,
    required this.nama,
    required this.jenis,
    required this.jenisBahan,
    required this.sizeType,
    required this.sizes,
    required this.currentIndex,
    required this.sizeData,
  });

  @override
  State<DetailPakaianPage> createState() => _DetailPakaianPageState();
}

class _DetailPakaianPageState extends State<DetailPakaianPage> {
  final lebarDadaController = TextEditingController();
  final panjangBajuController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),

      // 🔥 Bottom Navigation
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(color: Color(0xFFB88700)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _NavItem(icon: Icons.home, label: "Home"),
            _NavItem(icon: Icons.history, label: "History"),
            _NavItem(icon: Icons.person, label: "Profile"),
          ],
        ),
      ),

      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  Image.asset('assets/images/raywise_logo.png', height: 80),

                  const SizedBox(height: 16),

                  const Text(
                    'Input Detail Size',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7C27D).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Informasi Progress
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6CC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Kategori : ${widget.sizeType}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Jenis Bahan : ${widget.jenisBahan}"),
                                const SizedBox(height: 4),
                                Text(
                                  "Range : ${widget.sizes.first} sampai ${widget.sizes.last}",
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Size ${widget.currentIndex + 1} dari ${widget.sizes.length}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            "Ukuran Saat Ini",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB88700),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.sizes[widget.currentIndex],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _field("Lebar Dada", lebarDadaController),
                          const SizedBox(height: 16),
                          _field("Panjang Baju", panjangBajuController),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (lebarDadaController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lebar dada wajib diisi"),
                            ),
                          );
                          return;
                        }

                        if (panjangBajuController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Panjang baju wajib diisi"),
                            ),
                          );
                          return;
                        }

                        final updatedSizeData = List<Map<String, dynamic>>.from(
                          widget.sizeData,
                        );

                        final ld = int.tryParse(
                          lebarDadaController.text.trim(),
                        );
                        final pb = int.tryParse(
                          panjangBajuController.text.trim(),
                        );

                        if (ld == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lebar dada harus berupa angka"),
                            ),
                          );
                          return;
                        }

                        if (pb == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Panjang baju harus berupa angka"),
                            ),
                          );
                          return;
                        }
                        updatedSizeData.add({
                          'size': widget.sizes[widget.currentIndex],
                          'lebar_dada': ld,
                          'panjang_baju': pb,
                        });
                        if (ld <= 0 || pb <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Ukuran harus lebih dari 0"),
                            ),
                          );
                          return;
                        }
                        // Kalau masih ada size berikutnya
                        if (widget.currentIndex < widget.sizes.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPakaianPage(
                                brand: widget.brand,
                                nama: widget.nama,
                                jenis: widget.jenis,
                                jenisBahan: widget.jenisBahan,
                                sizeType: widget.sizeType,
                                sizes: widget.sizes,
                                currentIndex: widget.currentIndex + 1,
                                sizeData: updatedSizeData,
                              ),
                            ),
                          );
                        } else {
                          // 🔥 SIZE TERAKHIR → SIMPAN SEKALI SAJA KE FIRESTORE

                          await FirebaseFirestore.instance
                              .collection('pakaian')
                              .add({
                                'brand': widget.brand,
                                'nama': widget.nama,
                                'jenis': widget.jenis,
                                'jenisBahan': widget.jenisBahan,
                                'sizeType': widget.sizeType,
                                'sizes': updatedSizeData,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Berhasil simpan semua data"),
                            ),
                          );

                          // Kembali ke HomeAdminPage, bukan ke root (AuthChecker)
                          // supaya AuthChecker tidak re-run & trigger redirect ke login
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeAdminPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB88700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 210),
                ],
              ),
            ),
          ),

          // 🔥 Boneka kiri bawah
          Positioned(
            left: -57,
            bottom: -40, // bisa kamu atur lebih bawah lagi
            child: IgnorePointer(
              child: Image.asset('assets/images/boneka2.png', height: 180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFFF6CC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
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

  const _NavItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
