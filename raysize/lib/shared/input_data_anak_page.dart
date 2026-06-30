import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:raysize/shared/hasil_rekomendasi.dart';

class InputDataAnakPage extends StatefulWidget {
  const InputDataAnakPage({super.key});

  @override
  State<InputDataAnakPage> createState() => _InputDataAnakPageState();
}

class _InputDataAnakPageState extends State<InputDataAnakPage> {
  // ==========================================================================
  // SECTION 1: STATE VARIABLES
  // Variabel-variabel untuk menyimpan state UI dan data
  // ==========================================================================

  // --- Controller untuk input field ---
  final TextEditingController _usiaController = TextEditingController();
  final TextEditingController _bbController = TextEditingController();
  final TextEditingController _tbController = TextEditingController();

  // --- Variabel untuk menyimpan input user ---
  String? _selectedGender; // Jenis kelamin anak
  String? _selectedPakaian; // ID produk pakaian yang dipilih
  String? _namaProduk; // Nama produk pakaian
  String? _selectedSatuanUsia; // Satuan usia (Bulan/Tahun)

  // --- Data standar dari antro.json ---
  Map<String, dynamic> _standarBB = {}; // Standar berat badan
  Map<String, dynamic> _standarTB = {}; // Standar tinggi badan

  // --- Flag status loading ---
  bool _isDataLoaded = false; // Status data antro.json sudah dimuat
  bool _isLoading = true; // Status sedang loading

  // --- Nilai BB & TB yang dipilih (untuk mode slider) ---
  double? _selectedBB;
  double? _selectedTB;

  // --- Rentang minimum & maximum untuk slider ---
  double _minBB = 0;
  double _maxBB = 0;
  double _minTB = 0;
  double _maxTB = 0;

  // ==========================================================================
  // SECTION 2: LIFECYCLE METHODS
  // Method yang dijalankan saat lifecycle widget berubah
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    _loadAntroJson(); // Memuat data standar antropometri saat init
  }

  // ==========================================================================
  // SECTION 3: UI HELPER METHODS
  // Method untuk membantu pembuatan UI/components
  // ==========================================================================

  /// Membuat decoration untuk dropdown field
  InputDecoration _buildDropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFFFF6CC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// Membuat field input text dengan label
  Widget _buildInputField(String label, TextEditingController controller) {
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

  /// Mengecek apakah mode antro (usia <= 60 bulan / 5 tahun)
  bool _isAntroMode() {
    final int usia = int.tryParse(_usiaController.text) ?? 0;
    final int usiaBulan = _selectedSatuanUsia == "Tahun" ? usia * 12 : usia;
    return usiaBulan <= 60;
  }

  // ==========================================================================
  // SECTION 4: DATA LOADING METHODS
  // Method untuk memuat data dari JSON dan Firestore
  // ==========================================================================

  /// Memuat data standar antropometri dari assets/antro.json
  Future<void> _loadAntroJson() async {
    try {
      // Baca file JSON dari assets
      final String response = await rootBundle.loadString('assets/antro.json');
      final Map<String, dynamic> data = json.decode(response);

      setState(() {
        _standarBB = data['standar_bb'] ?? {};
        _standarTB = data['standar_tb'] ?? {};
        _isDataLoaded = true;
        _isLoading = false;
      });
      debugPrint("✅ antro.json berhasil dimuat");
    } catch (e) {
      debugPrint("❌ Gagal memuat antro.json: $e");
      setState(() => _isLoading = false);
    }
  }

  /// Mengambil parameter standar berdasarkan usia dan gender
  ///
  /// Parameters:
  /// - umurBulan: usia anak dalam bulan
  /// - gender: jenis kelamin (Laki-laki/Perempuan)
  /// - jenis: jenis standar (bb=berat badan, tb=tinggi badan)
  ///
  /// Returns: Map berisi parameter standar (minus3, minus2, median, plus2, plus3)
  Map<String, dynamic> _getStandarParams(
    int umurBulan,
    String gender,
    String jenis,
  ) {
    // Normalisasi gender ke lowercase
    final String g = gender.toLowerCase() == "laki-laki"
        ? "laki-laki"
        : "perempuan";

    // Ambil data berdasarkan jenis (bb/tb) dan gender
    final Map<String, dynamic> data =
        (jenis == "bb" ? _standarBB : _standarTB)[g] ?? {};

    if (data.isEmpty) return {};

    // Urutkan key (usia dalam bulan) dan cari yang paling mendekati
    final List<int> sortedKeys =
        data.keys.map((k) => int.tryParse(k.toString()) ?? 0).toList()..sort();

    // Cari usia terbesar yang masih <= umurBulan
    for (final int k in sortedKeys.reversed) {
      if (k <= umurBulan) {
        return data[k.toString()] ?? {};
      }
    }

    // Default ke data usia 0 bulan jika tidak ditemukan
    return data["0"] ?? {};
  }

  /// Mengambil data sizes dari Firestore berdasarkan ID produk
  ///
  /// Parameters:
  /// - idProduk: ID dokumen produk di Firestore
  ///
  /// Returns: List of maps berisi data size (size, panjang, lebarDada)
  Future<List<Map<String, dynamic>>> _getSizes(String idProduk) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("pakaian")
          .doc(idProduk)
          .get();

      if (!doc.exists) return [];

      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      final List<dynamic> sizes = data?['sizes'] ?? [];

      return sizes.map((s) {
        return {
          "size": s["size"],
          "panjang": (s["panjang_baju"] as num?)?.toDouble() ?? 0.0,
          "lebarDada": (s["lebar_dada"] as num?)?.toDouble() ?? 0.0,
        };
      }).toList();
    } catch (e) {
      debugPrint("ERROR getSizes: $e");
      return [];
    }
  }

  // ==========================================================================
  // SECTION 5: VALIDATION METHODS
  // Method untuk validasi input data anak
  // ==========================================================================

  /// Validasi nilai BB & TB anak
  ///
  /// Return null jika valid, atau record berisi info pelanggaran jika tidak valid
  /// Untuk usia 0-5 tahun: cek terhadap standar antro.json (±3 SD)
  /// Untuk usia > 5 tahun: cek rentang wajar hardcode
  ({
    String jenis,
    double nilai,
    double minIdeal,
    double maxIdeal,
    double minAbs,
    double maxAbs,
  })?
  _validateNilaiAnak({
    required double bb,
    required double tb,
    required int usiaBulan,
    required String gender,
  }) {
    // 1. Cek nilai tidak valid (negatif atau nol)
    if (bb <= 0) {
      return (
        jenis: "Berat Badan",
        nilai: bb,
        minIdeal: 0,
        maxIdeal: 0,
        minAbs: 0,
        maxAbs: 0,
      );
    }
    if (tb <= 0) {
      return (
        jenis: "Tinggi Badan",
        nilai: tb,
        minIdeal: 0,
        maxIdeal: 0,
        minAbs: 0,
        maxAbs: 0,
      );
    }

    // 2. Untuk usia 0-5 tahun: cek terhadap standar antro.json (±3 SD)
    if (usiaBulan <= 60) {
      final Map<String, dynamic> bbParams = _getStandarParams(
        usiaBulan,
        gender,
        "bb",
      );
      final Map<String, dynamic> tbParams = _getStandarParams(
        usiaBulan,
        gender,
        "tb",
      );

      if (bbParams.isNotEmpty) {
        final double minBB = (bbParams["minus3"] ?? bbParams["minus2"] ?? 0)
            .toDouble();
        final double maxBB = (bbParams["plus3"] ?? bbParams["plus2"] ?? 0)
            .toDouble();
        final double idealMinBB = (bbParams["minus2"] ?? 0).toDouble();
        final double idealMaxBB = (bbParams["plus2"] ?? 0).toDouble();

        if (bb < minBB || bb > maxBB) {
          return (
            jenis: "Berat Badan",
            nilai: bb,
            minIdeal: idealMinBB,
            maxIdeal: idealMaxBB,
            minAbs: minBB,
            maxAbs: maxBB,
          );
        }
      }

      if (tbParams.isNotEmpty) {
        final double minTB = (tbParams["minus3"] ?? tbParams["minus2"] ?? 0)
            .toDouble();
        final double maxTB = (tbParams["plus3"] ?? tbParams["plus2"] ?? 0)
            .toDouble();
        final double idealMinTB = (tbParams["minus2"] ?? 0).toDouble();
        final double idealMaxTB = (tbParams["plus2"] ?? 0).toDouble();

        if (tb < minTB || tb > maxTB) {
          return (
            jenis: "Tinggi Badan",
            nilai: tb,
            minIdeal: idealMinTB,
            maxIdeal: idealMaxTB,
            minAbs: minTB,
            maxAbs: maxTB,
          );
        }
      }
      return null;
    }

    // 3. Untuk usia > 5 tahun: hardcode batas longgar (sanity check)
    const double minAbsBB = 2.0, maxAbsBB = 80.0;
    const double minAbsTB = 60.0, maxAbsTB = 200.0;

    if (bb < minAbsBB || bb > maxAbsBB) {
      return (
        jenis: "Berat Badan",
        nilai: bb,
        minIdeal: 0,
        maxIdeal: 0,
        minAbs: minAbsBB,
        maxAbs: maxAbsBB,
      );
    }

    if (tb < minAbsTB || tb > maxAbsTB) {
      return (
        jenis: "Tinggi Badan",
        nilai: tb,
        minIdeal: 0,
        maxIdeal: 0,
        minAbs: minAbsTB,
        maxAbs: maxAbsTB,
      );
    }

    return null;
  }

  /// Dialog peringatan: nilai BB/TB di luar jangkauan standar
  ///
  /// Return true jika user memilih "Lanjut Paksa", false jika "Input Ulang"
  Future<bool> _showValidationDialog(
    BuildContext context, {
    required String jenis,
    required double nilai,
    required double minIdeal,
    required double maxIdeal,
    required double minAbs,
    required double maxAbs,
    required int usiaBulan,
    required String gender,
  }) async {
    final bool isAnakKecil = usiaBulan <= 60;
    final String rentangText = isAnakKecil
        ? "Standar WHO usia ${(usiaBulan / 12).toStringAsFixed(1)} tahun ($gender):\n"
              "  • Ideal (±2 SD): ${minIdeal.toStringAsFixed(1)} – ${maxIdeal.toStringAsFixed(1)}\n"
              "  • Batas wajar (±3 SD): ${minAbs.toStringAsFixed(1)} – ${maxAbs.toStringAsFixed(1)}"
        : "Rentang wajar: ${minAbs.toStringAsFixed(1)} – ${maxAbs.toStringAsFixed(1)}";

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFFF1C1),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Nilai Di Luar Jangkauan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$jenis yang dimasukkan: ${nilai.toStringAsFixed(1)} "
              "${jenis == 'Berat Badan' ? 'kg' : 'cm'}",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rentangText,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Nilai ini mungkin tidak akurat atau di luar jangkauan wajar. "
              "Silakan periksa kembali input Anda atau lanjutkan dengan nilai saat ini.",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            child: const Text("Input Ulang"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB88700),
              foregroundColor: Colors.white,
            ),
            child: const Text("Lanjut Paksa"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ==========================================================================
  // SECTION 6: FUZZY LOGIC METHODS
  // Method untuk logika fuzzy (pendukung validasi)
  // ==========================================================================

  /// Fungsi keanggotaan triangular (segitiga)
  ///
  /// Parameters:
  /// - x: nilai yang akan dihitung
  /// - a, b, c: parameter triangular (a<=b<=c)
  ///
  /// Returns: derajat keanggotaan (0.0 - 1.0)
  double _triangular(double x, double a, double b, double c) {
    if (x <= a || x >= c) return 0.0;
    if (x <= b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }

  /// Fungsi keanggotaan trapezoid kiri (untuk kategori "kurus" atau "pendek")
  double _trapezoidLeft(double x, double a, double b, double c) {
    if (x <= b) return 1.0;
    if (x > b && x < c) return (c - x) / (c - b);
    return 0.0;
  }

  /// Fungsi keanggotaan trapezoid kanan (untuk kategori "berat" atau "tinggi")
  double _trapezoidRight(double x, double a, double b, double c) {
    if (x <= a) return 0.0;
    if (x >= b) return 1.0;
    return (x - a) / (b - a);
  }

  /// Fuzzifikasi Berat Badan
  /// Menghitung derajat keanggotaan BB ke kategori: kurus, normal, berat
  Map<String, double> _fuzzifyBB(double bb, Map<String, dynamic> params) {
    if (params.isEmpty) return {"kurus": 0.0, "normal": 0.0, "berat": 0.0};

    final double m2 = (params["minus2"] ?? 0).toDouble();
    final double med = (params["median"] ?? 0).toDouble();
    final double p2 = (params["plus2"] ?? 0).toDouble();

    return {
      "kurus": _trapezoidLeft(bb, m2 - 1, m2, med),
      "normal": _triangular(bb, m2, med, p2),
      "berat": _trapezoidRight(bb, med, p2, p2 + 1),
    };
  }

  /// Fuzzifikasi Tinggi Badan
  /// Menghitung derajat keanggotaan TB ke kategori: pendek, normal, tinggi
  Map<String, double> _fuzzifyTB(double tb, Map<String, dynamic> params) {
    if (params.isEmpty) return {"pendek": 0.0, "normal": 0.0, "tinggi": 0.0};

    final double m3 = (params["minus2"] ?? 0).toDouble();
    final double med = (params["median"] ?? 0).toDouble();
    final double p3 = (params["plus2"] ?? 0).toDouble();

    final double tbRange = p3 - m3;

    return {
      "pendek": _trapezoidLeft(tb, m3 - (tbRange * 0.15), m3, med),
      "normal": _triangular(tb, m3, med, p3),
      "tinggi": _trapezoidRight(tb, med, p3, p3 + (tbRange * 0.15)),
    };
  }

  // ==========================================================================
  // SECTION 7: SIZE MATCHING METHODS
  // Method untuk logika pencocokan ukuran
  // ==========================================================================

  /// Mengatur rentang slider BB & TB berdasarkan data antropometri
  ///
  /// Parameters:
  /// - usiaBulan: usia anak dalam bulan
  /// - gender: jenis kelamin anak
  void _setRangeFromAntro(int usiaBulan, String gender) {
    final Map<String, dynamic> bbParams = _getStandarParams(
      usiaBulan,
      gender,
      "bb",
    );
    final Map<String, dynamic> tbParams = _getStandarParams(
      usiaBulan,
      gender,
      "tb",
    );

    if (bbParams.isEmpty || tbParams.isEmpty) return;

    setState(() {
      // Batas slider mengikuti standar WHO: ±3 SD
      // Fallback ke ±2 SD jika ±3 SD tidak tersedia
      _minBB = (bbParams["minus3"] ?? bbParams["minus2"] ?? 0).toDouble();
      _maxBB = (bbParams["plus3"] ?? bbParams["plus2"] ?? 0).toDouble();

      _minTB = (tbParams["minus3"] ?? tbParams["minus2"] ?? 0).toDouble();
      _maxTB = (tbParams["plus3"] ?? tbParams["plus2"] ?? 0).toDouble();

      // Default pilih nilai tengah
      _selectedBB = (_minBB + _maxBB) / 2;
      _selectedTB = (_minTB + _maxTB) / 2;
    });
  }

  /// Handle perubahan untuk update range antropometri
  void _handleAntroRange() {
    if (_usiaController.text.isEmpty || _selectedGender == null) return;

    final int usia = int.tryParse(_usiaController.text) ?? 0;
    final int usiaBulan = _selectedSatuanUsia == "Tahun" ? usia * 12 : usia;

    if (usiaBulan <= 60) {
      _setRangeFromAntro(usiaBulan, _selectedGender!);
    }
  }

  /// Menghitung estimasi lebar dada & panjang baju
  /// Dari BB & TB anak menggunakan rumus proporsional sederhana
  ({double lebarDada, double panjangBaju}) _estimasiTubuhDariAntro(
    double berat,
    double tinggi,
    String jenisBahan,
    Map<String, dynamic> bbParams,
  ) {
    // Stretchy
    if (jenisBahan == "Stretchy") {
      return (lebarDada: tinggi * 0.30, panjangBaju: tinggi * 0.32);
    }
    final double medianBB = (bbParams["median"] as num).toDouble();
    double koreksiBB = (berat - medianBB) * 0.10;

    double ld = (tinggi * 0.30) + koreksiBB;
    // Non Stretchy
    final double bb = berat.clamp(6.0, 60.0);
    final double tb = tinggi.clamp(50.0, 160.0);

    // final double ld = (0.20 * tb) - (0.15 * bb) + 12.5;

    final double pb = (0.43 * tb) + 4.0;

    return (lebarDada: ld, panjangBaju: pb);
  }

  /// Mengambil `jenisBahan` produk dari Firestore.
  /// Default ke "Stretchy" untuk produk lama yang belum punya field ini.
  Future<String> _getJenisBahan(String idProduk) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("pakaian")
          .doc(idProduk)
          .get();
      if (!doc.exists) return "Stretchy";
      final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return (data?['jenisBahan'] as String?) ?? "Stretchy";
    } catch (e) {
      debugPrint("ERROR getJenisBahan: $e");
      return "Stretchy";
    }
  }

  /// Menghitung ease allowance (cm) berdasarkan jenis bahan pakaian.
  /// Non-stretchy butuh ruang lebih supaya tidak terlalu ketat saat dipakai.
  /// - Stretchy (kaos, legging, spandex): LD +2, PB +4 (pas, mengikuti tubuh)
  /// - Non-Stretchy (sweater, jaket, denim): LD +5, PB +7 (longgar, untuk layering)
  ({double easeLebar, double easePanjang}) _getEase(String jenisBahan) {
    switch (jenisBahan) {
      case "Non-Stretchy":
        return (easeLebar: 3.0, easePanjang: 6.0);
      default: // "Stretchy" atau null (backward compatibility)
        return (easeLebar: 1.0, easePanjang: 1.0);
    }
  }

  /// Mencari size yang cocok dengan ukuran tubuh anak
  /// dengan pendekatan best-fit (paling dekat ke target) plus ease allowance
  /// yang disesuaikan dengan jenis bahan pakaian.
  ///
  /// Parameters:
  /// - sizes: list size produk (sudah di-fetch)
  /// - targetPanjang / targetLebar: estimasi ukuran tubuh anak
  /// - jenisBahan: "Stretchy" | "Non-Stretchy"
  String? _cariSizeFirestore(
    List<Map<String, dynamic>> sizes,
    double targetPanjang,
    double targetLebar,
    String jenisBahan,
  ) {
    if (sizes.isEmpty) return "-";

    // Urutkan berdasarkan panjang secara ascending
    sizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));

    // Ease allowance dinamis berdasarkan jenis bahan
    final ({double easeLebar, double easePanjang}) ease = _getEase(jenisBahan);
    final double minP = targetPanjang + ease.easePanjang;
    final double minL = targetLebar + ease.easeLebar;

    debugPrint("--- MULAI MATCHING SIZE (bahan=$jenisBahan) ---");
    debugPrint("Target Tubuh -> P: $targetPanjang, LD: $targetLebar");
    debugPrint(
      "Min Pakaian (ease L=${ease.easeLebar}, P=${ease.easePanjang}) -> "
      "P: $minP, LD: $minL",
    );

    // Cari semua size yang muat (dengan ease), lalu pilih yang
    // paling dekat (best-fit) ke target.
    Map<String, dynamic>? bestFit;
    double bestScore = double.infinity;

    for (final Map<String, dynamic> s in sizes) {
      final double p = s['panjang'] as double;
      final double l = s['lebarDada'] as double;
      debugPrint("Cek Size ${s['size']}: P($p) LD($l)");

      if (p >= minP && l >= minL) {
        // Selisih antara size pakaian dan target (semakin kecil = semakin pas)
        final double score = (p - targetPanjang) + (l - targetLebar);
        if (score < bestScore) {
          bestScore = score;
          bestFit = s;
        }
      }
    }

    if (bestFit != null) {
      debugPrint("✅ BEST FIT: Size ${bestFit['size']} (score=$bestScore)");
      return bestFit['size'] as String;
    }

    // Tidak ada size yang muat, cek apakah produk terlalu kecil.
    // Hanya fallback ke size TERBESAR (bukan terkecil!) supaya anak
    // tidak terjepit di ujung bawah range.
    final Map<String, dynamic> terbesar = sizes.last;
    final double selisihPanjang = terbesar['panjang'] - targetPanjang;
    final double selisihLebar = terbesar['lebarDada'] - targetLebar;

    const double batasTolakPanjang = -10.0;
    const double batasTolakLebar = -8.0;

    if (selisihPanjang < batasTolakPanjang || selisihLebar < batasTolakLebar) {
      debugPrint("❌ DITOLAK: Ukuran tubuh terlalu besar untuk produk ini.");
      return null;
    }

    debugPrint(
      "⚠️ Tidak ada size yang muat sempurna, fallback ke size terbesar: "
      "${terbesar['size']} (ΔP=$selisihPanjang, ΔL=$selisihLebar)",
    );
    return terbesar['size'] as String;
  }

  // ==========================================================================
  // SECTION 8: RECOMMENDATION PROCESSING
  // Method utama untuk proses rekomendasi
  // ==========================================================================

  void _prosesRekomendasi() async {
    // Cek apakah data sudah dimuat
    if (!_isDataLoaded) return;

    // Ambil dan konversi nilai usia
    final int inputUsia = int.tryParse(_usiaController.text) ?? 0;
    int usiaBulan = _selectedSatuanUsia == "Tahun" ? inputUsia * 12 : inputUsia;

    // Validasi input tidak boleh kosong
    if (_usiaController.text.isEmpty ||
        _selectedGender == null ||
        _selectedPakaian == null ||
        (usiaBulan > 60 &&
            (_bbController.text.isEmpty || _tbController.text.isEmpty)) ||
        (usiaBulan <= 60 && (_selectedBB == null || _selectedTB == null))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua data harus diisi")));
      return;
    }

    final double usiaTahun = usiaBulan / 12.0;

    // Ambil nilai BB & TB
    double bb;
    double tb;

    if (usiaBulan <= 60) {
      bb = double.parse((_selectedBB ?? 0).toStringAsFixed(1));
      tb = double.parse((_selectedTB ?? 0).toStringAsFixed(1));
    } else {
      // Mode input manual
      bb = double.tryParse(_bbController.text) ?? 0;
      tb = double.tryParse(_tbController.text) ?? 0;
    }

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 0: Validasi BB & TB (universal untuk semua usia)          │
    // └─────────────────────────────────────────────────────────────────┘
    final validation = _validateNilaiAnak(
      bb: bb,
      tb: tb,
      usiaBulan: usiaBulan,
      gender: _selectedGender!,
    );

    if (validation != null) {
      final bool lanjutPaksa = await _showValidationDialog(
        context,
        jenis: validation.jenis,
        nilai: validation.nilai,
        minIdeal: validation.minIdeal,
        maxIdeal: validation.maxIdeal,
        minAbs: validation.minAbs,
        maxAbs: validation.maxAbs,
        usiaBulan: usiaBulan,
        gender: _selectedGender!,
      );

      if (!lanjutPaksa) return; // User pilih Input Ulang
      if (!mounted) return;
    }

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 1: Ambil Data Standar dari JSON                            │
    // └─────────────────────────────────────────────────────────────────┘
    final Map<String, dynamic> bbParams = _getStandarParams(
      usiaBulan,
      _selectedGender!,
      "bb",
    );
    final Map<String, dynamic> tbParams = _getStandarParams(
      usiaBulan,
      _selectedGender!,
      "tb",
    );

    if (bbParams.isEmpty || tbParams.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data standar tidak ditemukan")),
      );
      return;
    }

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 2: Fuzzifikasi BB & TB (untuk validasi data)              │
    // └─────────────────────────────────────────────────────────────────┘
    final Map<String, double> muBB = _fuzzifyBB(bb, bbParams);
    final Map<String, double> muTB = _fuzzifyTB(tb, tbParams);

    final double totalAlpha =
        muBB.values.fold(0.0, (a, b) => a + b) +
        muTB.values.fold(0.0, (a, b) => a + b);

    if (totalAlpha <= 0.001) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data tubuh di luar jangkauan")),
      );
      return;
    }

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 3: Ambil Size Produk + Jenis Bahan                         │
    // └─────────────────────────────────────────────────────────────────┘
    final List<Map<String, dynamic>> allSizes = await _getSizes(
      _selectedPakaian!,
    );
    if (allSizes.isEmpty) return;

    // Filter usia dinonaktifkan: matching murni berdasarkan BB & TB.
    // (Filter berdasarkan usia pernah menyebabkan size XL terpotong dari
    //  list untuk anak usia muda, sehingga rekomendasi terjepit ke size
    //  terkecil. BB & TB sudah cukup merepresentasikan usia.)
    final List<Map<String, dynamic>> filteredSizes = allSizes;

    // Ambil jenis bahan produk (default "Stretchy" untuk produk lama)
    final String jenisBahan = await _getJenisBahan(_selectedPakaian!);

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 4: Estimasi Ukuran Tubuh Anak                              │
    // └─────────────────────────────────────────────────────────────────┘
    final ({double lebarDada, double panjangBaju}) tubuh =
        _estimasiTubuhDariAntro(bb, tb, jenisBahan, bbParams);
    final double estimasiLebar = tubuh.lebarDada;
    final double estimasiPanjang = tubuh.panjangBaju;

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 5: Matching ke Size Produk                                 │
    // └─────────────────────────────────────────────────────────────────┘
    final String? sizeRekomendasi = _cariSizeFirestore(
      filteredSizes,
      estimasiPanjang,
      estimasiLebar,
      jenisBahan,
    );

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 5.5: Validasi akhir — size baju harus >= tubuh (no ease)   │
    // │ Jika baju lebih kecil dari tubuh, berarti sudah melampaui      │
    // │ rentang size produk. Tolak & jangan kasih rekomendasi.         │
    // └─────────────────────────────────────────────────────────────────┘
    if (sizeRekomendasi != null) {
      final Map<String, dynamic>? sizeDipilih = filteredSizes
          .cast<Map<String, dynamic>?>()
          .firstWhere((s) => s?['size'] == sizeRekomendasi, orElse: () => null);
      if (sizeDipilih != null && sizeDipilih.isNotEmpty) {
        final double pBaju = (sizeDipilih['panjang'] as num).toDouble();
        final double lBaju = (sizeDipilih['lebarDada'] as num).toDouble();
        // Tolak jika baju lebih kecil dari tubuh pada dimensi APAPUN
        // (mengabaikan ease allowance — kalau tanpa ease sudah lebih kecil,
        //  sudah pasti tidak muat).
        if (pBaju < estimasiPanjang || lBaju < estimasiLebar) {
          debugPrint(
            "❌ Size $sizeRekomendasi lebih kecil dari tubuh: "
            "ΔP=${(pBaju - estimasiPanjang).toStringAsFixed(1)}, "
            "ΔL=${(lBaju - estimasiLebar).toStringAsFixed(1)}",
          );
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFFE7C27D),
              title: const Text(
                "Ukuran Tidak Tersedia",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Ukuran tubuh anak (Lebar Dada ${estimasiLebar.toStringAsFixed(1)} cm, "
                "Panjang Baju ${estimasiPanjang.toStringAsFixed(1)} cm) "
                "melebihi rentang size produk \"${_namaProduk ?? 'ini'}\". "
                "Silakan pilih produk dengan rentang ukuran yang lebih besar.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Color(0xFFB88700)),
                  ),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 6: Handle jika tidak ada size yang muat                   │
    // └─────────────────────────────────────────────────────────────────┘
    if (sizeRekomendasi == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFE7C27D),
          title: const Text(
            "Ukuran Tidak Tersedia",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Ukuran tubuh anak (Lebar Dada ${estimasiLebar.toStringAsFixed(1)} cm, "
            "Panjang Baju ${estimasiPanjang.toStringAsFixed(1)} cm) "
            "terlalu besar untuk produk \"${_namaProduk ?? 'ini'}\". "
            "Silakan pilih produk dengan rentang ukuran yang lebih besar.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFFB88700)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // ┌─────────────────────────────────────────────────────────────────┐
    // │ STEP 7: Navigasi ke Halaman Hasil                               │
    // └─────────────────────────────────────────────────────────────────┘
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilRekomendasiPage(
          lebarDada: estimasiLebar,
          panjangBaju: estimasiPanjang,
          size: sizeRekomendasi,
          produkId: _selectedPakaian!,
          umur: usiaTahun.toInt(),
          berat: bb.toInt(),
          tinggi: tb.toInt(),
          jenisKelamin: _selectedGender!,
          namaPakaian: _namaProduk ?? "-",
          jenisBahan: jenisBahan,
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION 9: MAIN BUILD METHOD
  // Membangun UI utama halaman
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double cardWidth = size.width * 0.85;

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

                  // Header: Logo dan Judul
                  Image.asset('assets/images/raywise_logo.png', height: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Input Data Anak',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),

                  // ┌────────────────────────────────────────────────────────────┐
                  // │ FORM INPUT DATA                                            │
                  // └────────────────────────────────────────────────────────────┘
                  Center(
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7C27D).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Dropdown Satuan Usia ---
                          const Text(
                            "Satuan Usia",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedSatuanUsia,
                            hint: const Text("Pilih Satuan"),
                            items: const ["Bulan", "Tahun"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSatuanUsia = v),
                            decoration: _buildDropdownDecoration(),
                          ),

                          const SizedBox(height: 16),

                          // --- Input Usia ---
                          TextField(
                            controller: _usiaController,
                            onChanged: (_) => _handleAntroRange(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFFFF6CC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // --- Dropdown Jenis Kelamin ---
                          const Text(
                            "Jenis Kelamin",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            hint: const Text("Pilih Jenis Kelamin"),
                            items: const ["Laki-laki", "Perempuan"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() => _selectedGender = v);
                              _handleAntroRange();
                            },
                            decoration: _buildDropdownDecoration(),
                          ),

                          const SizedBox(height: 20),

                          // --- Input Berat Badan ---
                          if (_isAntroMode()) ...[
                            // Mode Slider (usia <= 5 tahun)
                            const Text(
                              "Berat Badan (kg)",
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Slider(
                              value: (_selectedBB ?? _minBB).clamp(
                                _minBB,
                                _maxBB == 0 ? 1 : _maxBB,
                              ),
                              min: _minBB,
                              max: _maxBB == 0 ? 1 : _maxBB,
                              onChanged: (val) {
                                setState(() => _selectedBB = val);
                              },
                            ),
                            Text(
                              "Dipilih: ${_selectedBB?.toStringAsFixed(1)} kg",
                            ),
                          ] else ...[
                            // Mode Input Manual (usia > 5 tahun)
                            _buildInputField("Berat Badan (kg)", _bbController),
                          ],

                          const SizedBox(height: 16),

                          // --- Input Tinggi Badan ---
                          if (_isAntroMode()) ...[
                            // Mode Slider
                            const Text(
                              "Tinggi Badan (cm)",
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Slider(
                              value: _selectedTB ?? _minTB,
                              min: _minTB,
                              max: _maxTB,
                              onChanged: (val) {
                                setState(() => _selectedTB = val);
                              },
                            ),
                            Text(
                              "Dipilih: ${_selectedTB?.toStringAsFixed(1)} cm",
                            ),
                          ] else ...[
                            // Mode Input Manual
                            _buildInputField(
                              "Tinggi Badan (cm)",
                              _tbController,
                            ),
                          ],

                          const SizedBox(height: 20),

                          // --- Dropdown Pilih Produk ---
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
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              return DropdownButtonFormField<String>(
                                value: _selectedPakaian,
                                hint: const Text("Pilih Produk"),
                                items: snapshot.data!.docs.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(doc["nama"] ?? "Produk"),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  final QueryDocumentSnapshot doc = snapshot
                                      .data!
                                      .docs
                                      .firstWhere((d) => d.id == v);
                                  setState(() {
                                    _selectedPakaian = v; // Simpan ID
                                    _namaProduk = doc["nama"]; // Simpan Nama
                                  });
                                },
                                decoration: _buildDropdownDecoration(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ┌────────────────────────────────────────────────────────────┐
                  // │ TOMBOL PROSES REKOMENDASI                                  │
                  // └────────────────────────────────────────────────────────────┘
                  SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isDataLoaded ? _prosesRekomendasi : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB88700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isLoading
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

          // Decorative Image (boneka di pojok kiri bawah)
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
}
