import 'package:flutter/material.dart';

class InputDataPakaianPage extends StatefulWidget {
  const InputDataPakaianPage({super.key});

  @override
  State<InputDataPakaianPage> createState() => _InputDataPakaianPageState();
}

class _InputDataPakaianPageState extends State<InputDataPakaianPage> {
  final brandController = TextEditingController();
  final namaController = TextEditingController();
  final jenisController = TextEditingController();

  String selectedSizeType = "XS - XL";
  List<String> generatedSizes = [];

  final Map<String, List<String>> sizeOptions = {
    "XS - XL": ["XS", "S", "M", "L", "XL"],
    "S - XXL": ["S", "M", "L", "XL", "XXL"],
    "NB - XXL": ["NB", "S", "M", "L", "XL", "XXL"],
    "90 - 150": ["90", "100", "110", "120", "130", "140", "150"],
    "0 - 36 Month": ["0M", "6M", "12M", "18M", "24M", "36M"],
    "2 - 8 Years": ["2Y", "3Y", "4Y", "5Y", "6Y", "7Y", "8Y"],
  };

  @override
  void initState() {
    super.initState();
    generatedSizes = sizeOptions[selectedSizeType]!;
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
                          const SizedBox(height: 12),

                          _field("Nama Pakaian", namaController),
                          const SizedBox(height: 12),

                          _field("Jenis Pakaian", jenisController),
                          const SizedBox(height: 12),

                          const Text(
                            "Tipe Size",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),

                          DropdownButtonFormField(
                            value: selectedSizeType,
                            items: sizeOptions.keys
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedSizeType = value.toString();
                                generatedSizes = sizeOptions[selectedSizeType]!;
                              });
                            },
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Daftar Size",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),

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
                      onPressed: () {},
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
