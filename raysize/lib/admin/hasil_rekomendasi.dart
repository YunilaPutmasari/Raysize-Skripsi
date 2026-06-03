import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HasilRekomendasiPage extends StatefulWidget {
  final double lebarDada; // Estimasi tubuh dari fuzzy
  final double panjangBaju; // Estimasi tubuh dari fuzzy
  final String size; // Label size rekomendasi (misal: "S", "6-12m", "2")
  final String produkId; // ID produk untuk tarik data aktual
  final int umur;
  final int berat;
  final int tinggi;
  final String jenisKelamin;
  final String namaPakaian;
  const HasilRekomendasiPage({
    super.key,
    required this.lebarDada,
    required this.panjangBaju,
    required this.size,
    required this.produkId,
    required this.umur,
    required this.berat,
    required this.tinggi,
    required this.jenisKelamin,
    required this.namaPakaian,
  });

  @override
  State<HasilRekomendasiPage> createState() => _HasilRekomendasiPageState();
}

class _HasilRekomendasiPageState extends State<HasilRekomendasiPage> {
  Map<String, dynamic>? actualSizeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActualSizeFromFirestore();

    if (!sudahDisimpan) {
      simpanRiwayat();
      sudahDisimpan = true;
    }
  }

  Future<void> _loadActualSizeFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pakaian')
          .doc(widget.produkId)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final List sizes = data?['sizes'] ?? [];

      final found = sizes.firstWhere(
        (s) => s['size'] == widget.size,
        orElse: () => null,
      );

      if (found != null) {
        setState(() {
          actualSizeData = {
            "panjang": found["panjang_baju"],
            "lebar": found["lebar_dada"],
          };
        });
      }
    } catch (e) {
      print("ERROR load size: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> simpanRiwayat() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('riwayat')
          .add({
            'umur': widget.umur,
            'berat': widget.berat,
            'tinggi': widget.tinggi,
            'jenisKelamin': widget.jenisKelamin,
            'brand': 'Raywise',
            'namaPakaian': widget.namaPakaian,
            'rekomendasi': widget.size,
            'createdAt': FieldValue.serverTimestamp(),
          });

      print("✅ RIWAYAT TERSIMPAN");
    } catch (e) {
      print("❌ ERROR SIMPAN: $e");
    }
  }

  bool sudahDisimpan = false;
  @override
  Widget build(BuildContext context) {
    // Mengambil nilai aktual dari Firestore (field 'lebar' sesuai kode input sebelumnya)
    final actualPanjang = actualSizeData?['panjang']?.toDouble() ?? 0.0;
    final actualLebar = actualSizeData?['lebar']?.toDouble() ?? 0.0;

    // Hitung selisih (Baju - Tubuh)
    // Karena logika kita mencari baju yang LEBIH BESAR, selisih biasanya positif.
    final diffPanjang = actualPanjang - widget.panjangBaju;
    final diffLebar = actualLebar - widget.lebarDada;

    String rekomendasiStatus = "Sesuai / Pas";
    Color statusColor = Colors.green;

    // Penyesuaian Logika Status berdasarkan selisih (Tolerance)
    // Jika selisih panjang > 6cm atau lebar > 4cm, baru dianggap longgar
    if (diffPanjang > 6 || diffLebar > 4) {
      rekomendasiStatus = "Agak Longgar";
      statusColor = Colors.orange;
    }

    if (diffPanjang > 10 || diffLebar > 7) {
      rekomendasiStatus = "Sangat Longgar";
      statusColor = Colors.deepOrange;
    }

    // Jika ternyata hasil matching memberikan baju yang lebih kecil (kasus langka/fallback)
    if (diffPanjang < 0 || diffLebar < 0) {
      rekomendasiStatus = "Ukuran Terkecil (Mungkin Ketat)";
      statusColor = Colors.red;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB88700),
        elevation: 0,
        title: const Text(
          "Hasil Rekomendasi",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7C27D),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Rekomendasi Berhasil",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Badge Ukuran Utama
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB88700),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "UKURAN DISARANKAN",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              widget.size,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildCard("Estimasi hitungan fuzzy", [
                        "Lebar Dada : ${widget.lebarDada.toStringAsFixed(1)} cm",
                        "Panjang Baju : ${widget.panjangBaju.toStringAsFixed(1)} cm",
                      ]),

                      const SizedBox(height: 20),

                      if (actualSizeData != null) ...[
                        _buildCard("Detail Ukuran Baju ", [
                          "Lebar Dada Baju : ${actualLebar.toStringAsFixed(1)} cm",
                          "Panjang Baju : ${actualPanjang.toStringAsFixed(1)} cm",
                          "Selisih Lebar : ${diffLebar.toStringAsFixed(1)} cm",
                        ]),

                        const SizedBox(height: 16),

                        // Container(
                        //   padding: const EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     color: statusColor.withOpacity(0.2),
                        //     borderRadius: BorderRadius.circular(10),
                        //     border: Border.all(color: statusColor),
                        //   ),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Icon(
                        //         Icons.info_outline,
                        //         color: statusColor,
                        //         size: 15,
                        //       ),
                        //       const SizedBox(width: 8),
                        //       Text(
                        //         "Status: $rekomendasiStatus",
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.bold,
                        //           color: statusColor,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ] else
                        const Text(
                          "Data produk tidak ditemukan",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB88700),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            "Cek Produk Lain",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const Divider(),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.straighten, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(item, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
