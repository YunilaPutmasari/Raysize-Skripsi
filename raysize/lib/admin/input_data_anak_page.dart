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
  String? namaProduk;
  String? selectedSatuanUsia;
  // Data standar dari antro.json
  Map<String, dynamic> standarBB = {};
  Map<String, dynamic> standarTB = {};

  bool isDataLoaded = false;
  bool isLoading = true;
  double? selectedBB;
  double? selectedTB;

  double minBB = 0;
  double maxBB = 0;

  double minTB = 0;
  double maxTB = 0;
  bool isAntroMode() {
    int usia = int.tryParse(usiaController.text) ?? 0;

    int usiaBulan = selectedSatuanUsia == "Tahun" ? usia * 12 : usia;

    return usiaBulan <= 60;
  }

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

  // Fungsi trapezoid kiri (untuk kategori "kurus" atau "pendek")
  double trapezoidLeft(double x, double a, double b, double c) {
    if (x <= b) return 1.0;
    if (x > b && x < c) return (c - x) / (c - b);
    return 0.0;
  }

  // Fungsi trapezoid kanan (untuk kategori "berat" atau "tinggi")
  double trapezoidRight(double x, double a, double b, double c) {
    if (x <= a) return 0.0;
    if (x >= b) return 1.0;
    return (x - a) / (b - a);
  }

  void setRangeFromAntro(int usiaBulan, String gender) {
    final bbParams = getStandarParams(usiaBulan, gender, "bb");
    final tbParams = getStandarParams(usiaBulan, gender, "tb");

    if (bbParams.isEmpty || tbParams.isEmpty) return;

    setState(() {
      // Batas slider mengikuti standar WHO: ±3 SD agar anak-anak di
      // ekstrem (sangat kurus/pendek atau sangat gemuk/tinggi) tetap
      // bisa dijangkau. Rentang ±2 SD tetap dipakai sebagai referensi "ideal".
      // Fallback ke ±2 SD jika ±3 SD tidak tersedia di JSON.
      minBB = (bbParams["minus3"] ?? bbParams["minus2"] ?? 0).toDouble();
      maxBB = (bbParams["plus3"] ?? bbParams["plus2"] ?? 0).toDouble();

      minTB = (tbParams["minus3"] ?? tbParams["minus2"] ?? 0).toDouble();
      maxTB = (tbParams["plus3"] ?? tbParams["plus2"] ?? 0).toDouble();

      // default pilih tengah
      selectedBB = (minBB + maxBB) / 2;
      selectedTB = (minTB + maxTB) / 2;
    });
  }

  /// Validasi nilai BB & TB anak.
  /// Return null jika valid, atau record berisi info pelanggaran.
  /// Untuk usia 0-5 tahun: cek terhadap standar antro.json (±3 SD)
  /// Untuk usia > 5 tahun: cek rentang wajar hardcode (sanity check)
  ({String jenis, double nilai, double minIdeal, double maxIdeal, double minAbs, double maxAbs})?
  validateNilaiAnak({
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
      final bbParams = getStandarParams(usiaBulan, gender, "bb");
      final tbParams = getStandarParams(usiaBulan, gender, "tb");

      if (bbParams.isNotEmpty) {
        final minBB = (bbParams["minus3"] ?? bbParams["minus2"] ?? 0).toDouble();
        final maxBB = (bbParams["plus3"] ?? bbParams["plus2"] ?? 0).toDouble();
        final idealMinBB = (bbParams["minus2"] ?? 0).toDouble();
        final idealMaxBB = (bbParams["plus2"] ?? 0).toDouble();
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
        final minTB = (tbParams["minus3"] ?? tbParams["minus2"] ?? 0).toDouble();
        final maxTB = (tbParams["plus3"] ?? tbParams["plus2"] ?? 0).toDouble();
        final idealMinTB = (tbParams["minus2"] ?? 0).toDouble();
        final idealMaxTB = (tbParams["plus2"] ?? 0).toDouble();
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

  /// Dialog peringatan: nilai BB/TB di luar jangkauan standar.
  /// Return true jika user memilih "Lanjut Paksa", false jika "Input Ulang".
  Future<bool> showValidasiDialog(
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

    final result = await showDialog<bool>(
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
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

  void handleAntroRange() {
    if (usiaController.text.isEmpty || selectedGender == null) return;

    int usia = int.tryParse(usiaController.text) ?? 0;

    int usiaBulan = selectedSatuanUsia == "Tahun" ? usia * 12 : usia;

    if (usiaBulan <= 60) {
      setRangeFromAntro(usiaBulan, selectedGender!);
    }
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
      debugPrint("✅ antro.json berhasil dimuat");
    } catch (e) {
      debugPrint("❌ Gagal memuat antro.json: $e");
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

    final double m2 = (params["minus2"] ?? 0).toDouble();
    final double med = (params["median"] ?? 0).toDouble();
    final double p2 = (params["plus2"] ?? 0).toDouble();

    return {
      "kurus": trapezoidLeft(bb, m2 - 1, m2, med),
      "normal": triangular(bb, m2, med, p2),
      "berat": trapezoidRight(bb, med, p2, p2 + 1),
    };
  }

  Map<String, double> fuzzifyTB(double tb, Map<String, dynamic> params) {
    if (params.isEmpty) return {"pendek": 0.0, "normal": 0.0, "tinggi": 0.0};

    final double m3 = (params["minus2"] ?? 0).toDouble();
    final double med = (params["median"] ?? 0).toDouble();
    final double p3 = (params["plus2"] ?? 0).toDouble();

    double tbRange = p3 - m3;

    return {
      "pendek": trapezoidLeft(tb, m3 - (tbRange * 0.15), m3, med),
      "normal": triangular(tb, m3, med, p3),
      "tinggi": trapezoidRight(tb, med, p3, p3 + (tbRange * 0.15)),
    };
  }

  // Estimasi ukuran tubuh anak (LD & PB) dari BB & TB anak.
  //
  // Pendekatan: setiap size di baju (Lily, Uniqlo, dll) punya LD & PB
  // sendiri. Yang harus diestimasi adalah TUBUH ANAK, bukan baju.
  // Jadi estimasi ini independen dari produk.
  //
  // Proporsi standar tubuh balita:
  //   - Lebar dada ≈ 30% dari tinggi badan
  //   - Panjang baju (sebatas pinggang) ≈ 35% dari tinggi badan
  //
  // Contoh: anak TB 88cm → LD ≈ 26.4 cm, PB ≈ 30.8 cm
  ({double lebarDada, double panjangBaju}) estimasiTubuhDariAntro(
    double berat,
    double tinggi,
  ) {
    final double ld = tinggi * 0.30;
    final double pb = tinggi * 0.35;

    debugPrint(
      "📐 Estimasi tubuh: BB=$berat kg, TB=$tinggi cm → LD=${ld.toStringAsFixed(1)}, PB=${pb.toStringAsFixed(1)}",
    );

    return (lebarDada: ld, panjangBaju: pb);
  }

  // Filter kumpulan size berdasarkan rentang usia (safety, tidak agresif).
  // Hanya memotong 1-2 size paling ekstrem, bukan membagi kategori.
  // Misal: usia 2 tahun tidak boleh dapat size XXL.
  List<Map<String, dynamic>> filterByUsia(
    int usiaTahun,
    List<Map<String, dynamic>> sizes,
  ) {
    sizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));
    int n = sizes.length;

    if (n == 0) return [];
    if (n == 1) return [sizes.first];

    int clampIdx(int i) => i.clamp(0, n);

    if (usiaTahun <= 1) {
      // bayi: 2 size terkecil (skip size dewasa)
      int end = clampIdx(2);
      return sizes.sublist(0, end);
    } else if (usiaTahun <= 2) {
      // anak 1-2 tahun: skip 1 size paling besar
      int end = n >= 4 ? n - 1 : n;
      return sizes.sublist(0, clampIdx(end));
    } else if (usiaTahun <= 3) {
      // anak 2-3 tahun: tidak exclude (semua size mungkin)
      return sizes;
    } else if (usiaTahun <= 5) {
      // anak 3-5 tahun: tidak exclude
      return sizes;
    } else {
      // > 5 tahun: skip 1 size paling kecil (baby size)
      int start = n >= 4 ? 1 : 0;
      return sizes.sublist(clampIdx(start), n);
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
      debugPrint("ERROR getSizes: $e");
      return [];
    }
  }

  Future<String?> cariSizeFirestore(
    String idProduk,
    double targetPanjang,
    double targetLebar,
  ) async {
    final sizes = await getSizes(idProduk);
    if (sizes.isEmpty) return "-";

    // URUTKAN berdasarkan panjang secara ascending (kecil ke besar)
    sizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));

    debugPrint("--- MULAI MATCHING SIZE ---");
    debugPrint("Target Tubuh -> P: $targetPanjang, LD: $targetLebar");

    // Aturan matching:
    // - Baju yang panjang ATAU lebarnya LEBIH KECIL dari tubuh = TIDAK MUAT,
    //   langsung di-skip, TIDAK disimpan sebagai kandidat.
    // - Hanya baju yang panjang >= target DAN lebar >= target yang lolos
    //   (diambil yang terkecil, agar tidak "loncat" ke size terlalu besar).
    // - Jika TIDAK ADA satu pun baju yang muat (bahkan size terbesar
    //   masih lebih kecil dari tubuh) = produk DITOLAK.
    for (var s in sizes) {
      debugPrint("Cek Size ${s['size']}: P(${s['panjang']}) LD(${s['lebarDada']})");

      // Baju yang muat (tidak ada selisih minus)
      if (s['panjang'] >= targetPanjang && s['lebarDada'] >= targetLebar) {
        debugPrint("✅ COCOK! Menggunakan Size: ${s['size']}");
        return s['size'];
      }
    }

    // Tidak ada satu pun size yang muat. Cek apakah size TERBESAR
    // masih jauh lebih kecil dari tubuh (produk tidak cocok untuk anak ini).
    final terbesar = sizes.last;
    final selisihPanjang = terbesar['panjang'] - targetPanjang; // negatif jika baju kekecilan
    final selisihLebar = terbesar['lebarDada'] - targetLebar;

    // Batas toleransi penolakan: jika size terbesar saja selisih minus
    // > 10cm panjang atau > 8cm lebar, produk terlalu kecil untuk anak.
    // (Sesuai aturan: TOLAK SEMUA selisih minus; ambang batas ini hanya
    // untuk membedakan "tidak ada yang muat" vs "tidak ada size tepat".)
    const double batasTolakPanjang = -10.0;
    const double batasTolakLebar = -8.0;

    if (selisihPanjang < batasTolakPanjang || selisihLebar < batasTolakLebar) {
      debugPrint("❌ DITOLAK: Ukuran tubuh terlalu besar untuk produk ini.");
      debugPrint("   Size terbesar: P(${terbesar['panjang']}) LD(${terbesar['lebarDada']})");
      debugPrint("   Target tubuh : P($targetPanjang) LD($targetLebar)");
      return null;
    }

    // Size terbesar masih di bawah target tapi dalam batas wajar:
    // tidak ada size yang pas, kembalikan null (bukan ukuran yang muat).
    debugPrint("⚠️ Tidak ada size yang muat (size terbesar masih lebih kecil dari tubuh).");
    return null;
  }

  void prosesRekomendasi() async {
    if (!isDataLoaded) return;
    final int inputUsia = int.tryParse(usiaController.text) ?? 0;

    int usiaBulan = selectedSatuanUsia == "Tahun" ? inputUsia * 12 : inputUsia;
    if (usiaController.text.isEmpty ||
        selectedGender == null ||
        selectedPakaian == null ||
        (usiaBulan > 60 &&
            (bbController.text.isEmpty || tbController.text.isEmpty)) ||
        (usiaBulan <= 60 && (selectedBB == null || selectedTB == null))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua data harus diisi")));
      return;
    }

    if (selectedSatuanUsia == "Tahun") {
      usiaBulan = inputUsia * 12;
    } else {
      usiaBulan = inputUsia;
    }

    final double usiaTahun = usiaBulan / 12.0;

    double bb;
    double tb;

    if (usiaBulan <= 60) {
      bb = selectedBB ?? 0;
      tb = selectedTB ?? 0;
    } else {
      bb = double.tryParse(bbController.text) ?? 0;
      tb = double.tryParse(tbController.text) ?? 0;
    }

    // --- 0️⃣ Validasi BB & TB (universal: anak kecil & besar) ---
    final validation = validateNilaiAnak(
      bb: bb,
      tb: tb,
      usiaBulan: usiaBulan,
      gender: selectedGender!,
    );
    if (validation != null) {
      final lanjutPaksa = await showValidasiDialog(
        context,
        jenis: validation.jenis,
        nilai: validation.nilai,
        minIdeal: validation.minIdeal,
        maxIdeal: validation.maxIdeal,
        minAbs: validation.minAbs,
        maxAbs: validation.maxAbs,
        usiaBulan: usiaBulan,
        gender: selectedGender!,
      );
      if (!lanjutPaksa) return; // user pilih Input Ulang
      // Setelah user pilih Lanjut Paksa, cek mounted sebelum lanjut
      if (!mounted) return;
    }

    // --- 1️⃣ Ambil Data Standar dari JSON ---
    final bbParams = getStandarParams(usiaBulan, selectedGender!, "bb");
    final tbParams = getStandarParams(usiaBulan, selectedGender!, "tb");

    if (bbParams.isEmpty || tbParams.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data standar tidak ditemukan")),
      );
      return;
    }
    // --- 2️⃣ Fuzzifikasi BB & TB (untuk validasi data) ---
    // (Fungsi ini dulu dipakai untuk inferensi fuzzy dan menghasilkan
    // alpha kecil/sedang/besar. Sekarang logika utama hanya
    // menggunakan estimasi tubuh + matching, tapi fuzzify tetap
    // dipertahankan untuk memvalidasi bahwa data anak berada di
    // dalam jangkauan standar.)
    final muBB = fuzzifyBB(bb, bbParams);
    final muTB = fuzzifyTB(tb, tbParams);

    final double totalAlpha = muBB.values.fold(0.0, (a, b) => a + b) +
        muTB.values.fold(0.0, (a, b) => a + b);

    if (totalAlpha <= 0.001) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data tubuh di luar jangkauan")),
      );
      return;
    }
    // --- 4️⃣ Ambil Size Produk (TANPA filter usia yang agresif) ---
    final allSizes = await getSizes(selectedPakaian!);
    if (allSizes.isEmpty) return;

    // Urutkan size dari kecil ke besar berdasarkan panjang baju
    allSizes.sort((a, b) => a['panjang'].compareTo(b['panjang']));

    // Filter usia sebagai SAFETY: exclude size yang sangat ekstrem
    // (misal usia 2 tahun tidak boleh dapat XXL).
    // Hanya memotong 1-2 size paling ekstrem, bukan membagi 3 kategori.
    final filteredSizes = filterByUsia(usiaTahun.toInt(), allSizes);
    if (filteredSizes.isEmpty) {
      filteredSizes.addAll(allSizes);
    }

    // --- 5️⃣ Estimasi Ukuran Tubuh Anak (dari BB & TB, independen dari baju) ---
    // Logika: setiap size di baju apapun punya LD & PB sendiri.
    // Yang harus diestimasi adalah TUBUH ANAK, bukan baju.
    // Estimasi tubuh anak = fungsi dari TB anak (proporsi standar tubuh).
    final tubuh = estimasiTubuhDariAntro(bb, tb);
    final estimasiLebar = tubuh.lebarDada;
    final estimasiPanjang = tubuh.panjangBaju;

    debugPrint("📊 Estimasi tubuh akhir:");
    debugPrint("   Lebar Dada: ${estimasiLebar.toStringAsFixed(1)} cm");
    debugPrint("   Panjang Baju: ${estimasiPanjang.toStringAsFixed(1)} cm");

    // --- 6️⃣ Matching ke Size Produk (berdasarkan LD & PB saja) ---
    final sizeRekomendasi = await cariSizeFirestore(
      selectedPakaian!,
      estimasiPanjang,
      estimasiLebar,
    );

    // --- 7️⃣ Jika tidak ada size yang muat (terlalu besar untuk produk) ---
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
            "terlalu besar untuk produk \"${namaProduk ?? 'ini'}\". "
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

    // --- 8️⃣ Navigasi ke Hasil ---
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HasilRekomendasiPage(
          lebarDada: estimasiLebar,
          panjangBaju: estimasiPanjang,
          size: sizeRekomendasi,
          produkId: selectedPakaian!,
          umur: usiaTahun.toInt(),
          berat: bb.toInt(),
          tinggi: tb.toInt(),
          jenisKelamin: selectedGender!,
          namaPakaian: namaProduk ?? "-", // ✅ sekarang nama asli
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
                        color: const Color(0xFFE7C27D).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Pilih Satuan Usia ---
                          const Text(
                            "Satuan Usia",
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedSatuanUsia,
                            hint: const Text("Pilih Satuan"),
                            items: ["Bulan", "Tahun"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => selectedSatuanUsia = v),
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 16),

                          // --- Input Usia ---
                          TextField(
                            controller: usiaController,
                            onChanged: (_) => handleAntroRange(),
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
                          // --- Pilih Jenis Kelamin ---
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
                            onChanged: (v) {
                              setState(() => selectedGender = v);
                              handleAntroRange();
                            },
                            decoration: _dropdownDecoration(),
                          ),

                          const SizedBox(height: 20),
                          // --- Input Berat Badan ---
                          isAntroMode()
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Berat Badan (kg)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Slider(
                                      value: (selectedBB ?? minBB).clamp(
                                        minBB,
                                        maxBB == 0 ? 1 : maxBB,
                                      ),
                                      min: minBB,
                                      max: maxBB == 0 ? 1 : maxBB,
                                      onChanged: (val) {
                                        setState(() => selectedBB = val);
                                      },
                                    ),
                                    Text(
                                      "Dipilih: ${selectedBB?.toStringAsFixed(1)} kg",
                                    ),
                                  ],
                                )
                              : _field("Berat Badan (kg)", bbController),
                          const SizedBox(height: 16),

                          // --- Input Tinggi Badan ---
                          isAntroMode()
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Tinggi Badan (cm)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Slider(
                                      value: selectedTB ?? minTB,
                                      min: minTB,
                                      max: maxTB,
                                      onChanged: (val) {
                                        setState(() => selectedTB = val);
                                      },
                                    ),
                                    Text(
                                      "Dipilih: ${selectedTB?.toStringAsFixed(1)} cm",
                                    ),
                                  ],
                                )
                              : _field("Tinggi Badan (cm)", tbController),
                          const SizedBox(height: 20),

                          // --- Pilih Produk ---
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
                                value: selectedPakaian,
                                hint: const Text("Pilih Produk"),
                                items: snapshot.data!.docs.map((doc) {
                                  return DropdownMenuItem(
                                    value: doc.id,
                                    child: Text(doc["nama"] ?? "Produk"),
                                  );
                                }).toList(),

                                onChanged: (v) {
                                  final doc = snapshot.data!.docs.firstWhere(
                                    (d) => d.id == v,
                                  );
                                  setState(() {
                                    selectedPakaian = v; // ID
                                    namaProduk = doc["nama"]; // ✅ Nama Produk
                                  });
                                },

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
