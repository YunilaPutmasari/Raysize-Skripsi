import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:raysize/admin/detail_pakaian.dart';

class InputDataPakaianPage extends StatefulWidget {
  const InputDataPakaianPage({super.key});

  @override
  State<InputDataPakaianPage> createState() => _InputDataPakaianPageState();
}

class _InputDataPakaianPageState extends State<InputDataPakaianPage> {
  final brandController = TextEditingController();
  final namaController = TextEditingController();
  final jenisController = TextEditingController();

  // 🔹 MASTER LIST
  final List<String> hurufSizes = [
    "NB",
    "XS",
    "S",
    "M",
    "L",
    "XL",
    "XXL",
    "3XL",
    "4XL",
  ];

  final List<String> angkaSizes = [
    "70",
    "80",
    "90",
    "100",
    "110",
    "120",
    "130",
    "140",
    "150",
  ];

  final List<String> bulanSingle = [
    "3M",
    "6M",
    "9M",
    "12M",
    "18M",
    "24M",
    "36M",
  ];

  final List<String> bulanRange = [
    "0-3M",
    "3-6M",
    "6-9M",
    "9-12M",
    "12-18M",
    "18-24M",
    "24-36M",
  ];

  final List<String> tahunSizes = [
    "1Y",
    "2Y",
    "3Y",
    "4Y",
    "5Y",
    "6Y",
    "7Y",
    "8Y",
    "9Y",
    "10Y",
  ];

  String selectedCategory = "Huruf";
  String? bulanType;
  String? startSize;
  String? endSize;
  String? selectedJenisBahan; // "Stretchy" | "Non-Stretchy"

  List<String> generatedSizes = [];

  // 🔹 Ambil list sesuai kategori
  List<String> getCurrentList() {
    switch (selectedCategory) {
      case "Huruf":
        return hurufSizes;
      case "Angka":
        return angkaSizes;
      case "Bulan":
        if (bulanType == "Range") {
          return bulanRange;
        }
        return bulanSingle;
      case "Tahun":
        return tahunSizes;
      default:
        return [];
    }
  }

  // 🔹 Generate range
  void generateSizeRange() {
    final list = getCurrentList();

    if (startSize != null && endSize != null) {
      final startIndex = list.indexOf(startSize!);
      final endIndex = list.indexOf(endSize!);

      if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
        setState(() {
          generatedSizes = list.sublist(startIndex, endIndex + 1);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
      body: Stack(
        clipBehavior: Clip.none, // 🔥 ini penting biar bisa keluar batas
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
                    'Input Data Pakaian',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 24),

                  // CARD kamu tetap di sini
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
                          _field("Brand", brandController),
                          const SizedBox(height: 16),

                          _field("Nama Pakaian", namaController),
                          const SizedBox(height: 16),

                          _field("Jenis Pakaian", jenisController),
                          const SizedBox(height: 16),

                          // 🔹 Dropdown Jenis Bahan (menentukan ease allowance saat rekomendasi)
                          const Text(
                            "Jenis Bahan",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedJenisBahan,
                            hint: const Text("Pilih Jenis Bahan"),
                            items: const ["Stretchy", "Non-Stretchy"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => selectedJenisBahan = val),
                            decoration: _dropdownDecoration(),
                          ),
                          const SizedBox(height: 20),

                          // 🔹 Tipe Size
                          const Text(
                            "Tipe Size",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),

                          DropdownButtonFormField(
                            value: selectedCategory,
                            items: ["Huruf", "Angka", "Bulan", "Tahun"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedCategory = val!;
                                bulanType = null;
                                startSize = null;
                                endSize = null;
                                generatedSizes = [];
                              });
                            },
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 16),

                          // 🔹 Tipe Bulan (jika kategori Bulan)
                          if (selectedCategory == "Bulan") ...[
                            const Text(
                              "Tipe Bulan",
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),

                            DropdownButtonFormField(
                              value: bulanType,
                              hint: const Text("Pilih Tipe Bulan"),
                              items: ["Single", "Range"]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  bulanType = val!;
                                  startSize = null;
                                  endSize = null;
                                  generatedSizes = [];
                                });
                              },
                              decoration: _dropdownDecoration(),
                            ),

                            const SizedBox(height: 16),
                          ],

                          // 🔹 Size Awal
                          const Text(
                            "Size Awal",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),

                          DropdownButtonFormField(
                            value: startSize,
                            hint: const Text("Pilih Size Awal"),
                            items: getCurrentList()
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                startSize = val!;
                              });
                              generateSizeRange();
                            },
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 16),

                          // 🔹 Size Akhir
                          const Text(
                            "Size Akhir",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),

                          DropdownButtonFormField(
                            value: endSize,
                            hint: const Text("Pilih Size Akhir"),
                            items: getCurrentList()
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                endSize = val!;
                              });
                              generateSizeRange();
                            },
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 20),

                          // 🔹 Daftar Size
                          const Text(
                            "Daftar Size",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: generatedSizes
                                .map((size) => _sizeChip(size))
                                .toList(),
                          ),
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
                        if (brandController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Brand wajib diisi")),
                          );
                          return;
                        }

                        if (namaController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Nama pakaian wajib diisi"),
                            ),
                          );
                          return;
                        }

                        if (jenisController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Jenis pakaian wajib diisi"),
                            ),
                          );
                          return;
                        }

                        if (selectedJenisBahan == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Jenis bahan wajib dipilih"),
                            ),
                          );
                          return;
                        }

                        if (generatedSizes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Minimal pilih satu ukuran"),
                            ),
                          );
                          return;
                        }
                        final cek = await FirebaseFirestore.instance
                            .collection("pakaian")
                            .where(
                              "brand",
                              isEqualTo: brandController.text.trim(),
                            )
                            .where(
                              "nama",
                              isEqualTo: namaController.text.trim(),
                            )
                            .get();

                        if (cek.docs.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Data pakaian sudah ada"),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => DetailPakaianPage(
                              brand: brandController.text,
                              nama: namaController.text,
                              jenis: jenisController.text,
                              jenisBahan: selectedJenisBahan!,
                              sizeType: selectedCategory,
                              sizes: generatedSizes,
                              currentIndex: 0,
                              sizeData: [],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB88700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Simpan Pakaian',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // 🔥 kasih ruang kosong
                ],
              ),
            ),
          ),

          // 🔥 Boneka bebas keluar
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

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFFF6CC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _sizeChip(String size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB88700),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        size,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
