import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raysize/admin/hasil_rekomendasi.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // Untuk rootBundle

class InputDataAnakPage extends StatefulWidget {
  const InputDataAnakPage({super.key});

  @override
  State<InputDataAnakPage> createState() => _InputDataAnakPageState();
}

class _InputDataAnakPageState extends State<InputDataAnakPage> {
  final usiaController = TextEditingController();
  final bbController = TextEditingController();
  final tbController = TextEditingController();

  String? selectedGender;
  String? selectedPakaian;

  // Data standar dari antro.json
  Map<String, dynamic> standarBB = {};
  Map<String, dynamic> standarTB = {};

  bool isDataLoaded = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAntroJson();
  }

  // --- FUNGSI HELPER FUZZY ---

  double triangular(double x, double a, double b, double c) {
    if (x <= a || x >= c) return 0.0;
    if (x <= b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }

  // Tambahkan fungsi ini agar tidak error lagi
  double trapezoidLeft(double x, double a, double b, double c) {
    if (x <= b) return 1.0;
    if (x > b && x < c) return (c - x) / (c - b);
    return 0.0;
  }

  // Tambahkan fungsi ini agar tidak error lagi
  double trapezoidRight(double x, double a, double b, double c) {
    if (x <= a) return 0.0;
    if (x >= b) return 1.0;
    return (x - a) / (b - a);
  }

  // --- LOGIKA DATA ---

  Future<void> _loadAntroJson() async {
    try {
      final String response = await rootBundle.loadString('assets/antro.json');
      final Map<String, dynamic> data = json.decode(response);

      setState(() {
        standarBB = data['standar_bb'] ?? {};
        standarTB = data['standar_tb'] ?? {};
        isDataLoaded = true;
        isLoading = false;
      });
      print("✅ antro.json berhasil dimuat");
    } catch (e) {
      print("❌ Gagal memuat antro.json: $e");
      setState(() => isLoading = false);
    }
  }

  Map<String, dynamic> getStandarParams(
    int umurBulan,
    String gender,
    String jenis,
  ) {
    // Normalisasi gender ke lowercase agar cocok dengan key di JSON
    String g = gender.toLowerCase() == "laki-laki" ? "laki-laki" : "perempuan";

    final data = (jenis == "bb" ? standarBB : standarTB)[g] ?? {};
    if (data.isEmpty) return {};

    final sortedKeys =
        data.keys.map((k) => int.tryParse(k.toString()) ?? 0).toList()..sort();

    for (var k in sortedKeys.reversed) {
      if (k <= umurBulan) {
        return data[k.toString()] ?? {};
      }
    }
    return data["0"] ?? {};
  }

  Map<String, double> fuzzifyBB(double bb, Map<String, dynamic> params) {
    if (params.isEmpty) return {"kurus": 0.0, "normal": 0.0, "berat": 0.0};

    final double m3 = (params["minus3"] ?? 0).toDouble();
    final double med = (params["median"] ?? 0).toDouble();
    final double p3 = (params["plus3"] ?? 0).toDouble();

    return {
      "kurus": trapezoidLeft(bb, m3 - 2, m3, med),
      "normal": triangular(bb, m3, med, p3),
      "berat": trapezoidRight(bb, med, p3, p3 + 2),
    };
  }

  Map<String, double> fuzzifyTB(double tb, Map<String, dynamic> params) {
    if (params.isEmpty) return {"pendek": 0.0, "normal": 0.0, "tinggi": 0.0};

    final double m3 = (params["minus3"] ?? 0).toDouble();
    final double med = (params["median"] ?? 0).toDouble();
    final double p3 = (params["plus3"] ?? 0).toDouble();

    return {
      "pendek": trapezoidLeft(tb, m3 - 5, m3, med),
      "normal": triangular(tb, m3, med, p3),
      "tinggi": trapezoidRight(tb, med, p3, p3 + 5),
    };
  }

  List<Map<String, dynamic>> filterByUsia(
    int usiaTahun,
    List<Map<String, dynamic>> sizes,
  ) {
    sizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));
    int n = sizes.length;

    if (n == 0) return [];

    if (usiaTahun <= 1) {
      return sizes.sublist(0, (n * 0.25).ceil()); // bayi → kecil saja
    } else if (usiaTahun <= 3) {
      return sizes.sublist(0, (n * 0.6).ceil()); // balita
    } else if (usiaTahun <= 5) {
      return sizes.sublist((n * 0.25).floor(), n); // prasekolah
    } else {
      return sizes.sublist((n * 0.4).floor(), n);
    }
  }

  Future<List<Map<String, dynamic>>> getSizes(String idProduk) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("pakaian")
          .doc(idProduk)
          .get();

      if (!doc.exists) return [];

      final data = doc.data();
      final List sizes = data?['sizes'] ?? [];

      return sizes.map((s) {
        return {
          "size": s["size"],
          "panjang": (s["panjang_baju"] as num?)?.toDouble() ?? 0.0,
          "lebarDada": (s["lebar_dada"] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (e) {
      print("ERROR getSizes: $e");
      return [];
    }
  }

  Future<String> cariSizeFirestore(
    String idProduk,
    double targetPanjang,
    double targetLebar,
  ) async {
    final sizes = await getSizes(idProduk);
    if (sizes.isEmpty) return "-";

    // URUTKAN berdasarkan panjang secara ascending (kecil ke besar)
    sizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));

    print("--- MULAI MATCHING SIZE ---");
    print("Target Tubuh -> P: $targetPanjang, LD: $targetLebar");

    for (var s in sizes) {
      print("Cek Size ${s['size']}: P(${s['panjang']}) LD(${s['lebarDada']})");

      // Cek apakah baju ini lebih besar atau sama dengan target tubuh
      if (s['panjang'] >= targetPanjang && s['lebarDada'] >= targetLebar) {
        print("✅ COCOK! Menggunakan Size: ${s['size']}");
        return s['size'];
      }
    }

    // Jika sampai akhir tidak ada yang >= target, artinya anak sangat besar
    print("⚠️ Tidak ada yang muat, ambil size terbesar");
    return sizes.last['size'];
  }

  void prosesRekomendasi() async {
    if (!isDataLoaded) return;

    if (usiaController.text.isEmpty ||
        bbController.text.isEmpty ||
        tbController.text.isEmpty ||
        selectedGender == null ||
        selectedPakaian == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua data harus diisi")));
      return;
    }

    final double usiaTahun = double.tryParse(usiaController.text) ?? 0;
    final int usiaBulan = (usiaTahun * 12).round();
    final double bb = double.tryParse(bbController.text) ?? 0;
    final double tb = double.tryParse(tbController.text) ?? 0;

    final bbParams = getStandarParams(usiaBulan, selectedGender!, "bb");
    final tbParams = getStandarParams(usiaBulan, selectedGender!, "tb");

    if (bbParams.isEmpty || tbParams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data standar tidak ditemukan")),
      );
      return;
    }

    final muBB = fuzzifyBB(bb, bbParams);
    final muTB = fuzzifyTB(tb, tbParams);

    double alphaBesar = [
      muBB["berat"]!,
      muTB["tinggi"]!,
    ].reduce((a, b) => a < b ? a : b);
    double alphaSedang = [
      muBB["normal"]!,
      muTB["normal"]!,
    ].reduce((a, b) => a < b ? a : b);
    double alphaKecil = [
      muBB["kurus"]!,
      muTB["pendek"]!,
    ].reduce((a, b) => a < b ? a : b);

    final double totalAlpha = alphaBesar + alphaSedang + alphaKecil;

    if (totalAlpha <= 0.001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data tubuh di luar jangkauan")),
      );
      return;
    }

    final allSizes = await getSizes(selectedPakaian!);
    if (allSizes.isEmpty) return;

    // 🔥 TAMBAHKAN INI
    final filteredSizes = filterByUsia(usiaTahun.toInt(), allSizes);

    if (filteredSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada size sesuai usia")),
      );
      return;
    }

    // pakai ini selanjutnya
    filteredSizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));
    // URUTKAN berdasarkan panjang dari kecil ke besar
    allSizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));
    int n = filteredSizes.length;
    int k = (n / 3).ceil();

    var kecil = filteredSizes.sublist(0, k);
    var sedang = filteredSizes.sublist(k, (2 * k > n ? n : 2 * k));
    var besar = filteredSizes.sublist((2 * k > n ? n : 2 * k), n);

    // fungsi rata-rata
    double avg(List list, String key) {
      if (list.isEmpty) return 0;
      return list.map((e) => e[key]).reduce((a, b) => a + b) / list.length;
    }

    double zKecilP = avg(kecil, 'panjang');
    double zSedangP = avg(sedang, 'panjang');
    double zBesarP = avg(besar, 'panjang');

    double zKecilLD = avg(kecil, 'lebarDada');
    double zSedangLD = avg(sedang, 'lebarDada');
    double zBesarLD = avg(besar, 'lebarDada');

    // Hitung estimasi tubuh (Hasil ini harusnya berada di antara size terkecil dan terbesar baju tersebut)
    double estimasiPanjang;
    double estimasiLebar;

    // ✅ jika hanya 1 kategori aktif → langsung ambil
    if (alphaBesar > 0 && alphaSedang == 0 && alphaKecil == 0) {
      estimasiPanjang = zBesarP;
      estimasiLebar = zBesarLD;
    } else if (alphaSedang > 0 && alphaBesar == 0 && alphaKecil == 0) {
      estimasiPanjang = zSedangP;
      estimasiLebar = zSedangLD;
    } else if (alphaKecil > 0 && alphaBesar == 0 && alphaSedang == 0) {
      estimasiPanjang = zKecilP;
      estimasiLebar = zKecilLD;
    } else {
      double totalAlpha = alphaKecil + alphaSedang + alphaBesar;

      estimasiPanjang =
          ((alphaKecil * zKecilP) +
              (alphaSedang * zSedangP) +
              (alphaBesar * zBesarP)) /
          totalAlpha;

      estimasiLebar =
          ((alphaKecil * zKecilLD) +
              (alphaSedang * zSedangLD) +
              (alphaBesar * zBesarLD)) /
          totalAlpha;
    }
    double estP =
        ((alphaKecil * zKecilP) +
            (alphaSedang * zSedangP) +
            (alphaBesar * zBesarP)) /
        totalAlpha;
    double estLD =
        ((alphaKecil * zKecilLD) +
            (alphaSedang * zSedangLD) +
            (alphaBesar * zBesarLD)) /
        totalAlpha;

    // Di bagian matching, gunakan nilai murni hasil estimasi dulu untuk testing
    final sizeRekomendasi = await cariSizeFirestore(
      selectedPakaian!,
      estimasiPanjang, // Jangan ditambah dulu
      estimasiLebar, // Jangan ditambah dulu
    );
    String kategoriUsia;
    if (usiaTahun <= 1) {
      kategoriUsia = "bayi";
    } else if (usiaTahun <= 3) {
      kategoriUsia = "balita";
    } else {
      kategoriUsia = "prasekolah";
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilRekomendasiPage(
          lebarDada: estLD,
          panjangBaju: estP,
          size: sizeRekomendasi,
          produkId: selectedPakaian!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width * 0.85;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
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
                    'Input Data Anak',
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
                          _field("Usia (Tahun)", usiaController),
                          const SizedBox(height: 16),
                          _field("Berat Badan (kg)", bbController),
                          const SizedBox(height: 16),
                          _field("Tinggi Badan (cm)", tbController),
                          const SizedBox(height: 20),

                          const Text(
                            "Jenis Kelamin",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedGender,
                            hint: const Text("Pilih Jenis Kelamin"),
                            items: ["Laki-laki", "Perempuan"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedGender = v),
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Pilih Produk",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("pakaian")
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData)
                                return const CircularProgressIndicator();
                              return DropdownButtonFormField<String>(
                                value: selectedPakaian,
                                hint: const Text("Pilih Produk"),
                                items: snapshot.data!.docs
                                    .map(
                                      (doc) => DropdownMenuItem(
                                        value: doc.id,
                                        child: Text(doc["nama"] ?? "Produk"),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedPakaian = v),
                                decoration: _dropdownDecoration(),
                              );
                            },
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
                      onPressed: isDataLoaded ? prosesRekomendasi : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB88700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Proses Rekomendasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          Positioned(
            left: -57,
            bottom: -40,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
}
