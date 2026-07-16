import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Halaman untuk mengubah seluruh data satu produk pakaian.
class EditPakaianPage extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> pakaian;

  const EditPakaianPage({
    super.key,
    required this.documentId,
    required this.pakaian,
  });

  @override
  State<EditPakaianPage> createState() => _EditPakaianPageState();
}

class _EditPakaianPageState extends State<EditPakaianPage> {
  static const _bahan = ['Stretchy', 'Non-Stretchy'];
  static const _gender = ['Laki-laki', 'Perempuan', 'Unisex'];
  static const _tipeUkuran = ['Huruf', 'Angka', 'Bulan', 'Tahun'];

  late final TextEditingController _brandController;
  late final TextEditingController _namaController;
  late final TextEditingController _jenisController;
  late final TextEditingController _usiaMinController;
  late final TextEditingController _usiaMaxController;
  late String _jenisBahan;
  late String _genderPakaian;
  late String _sizeType;
  late List<_UkuranController> _ukuran;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final data = widget.pakaian;
    _brandController = TextEditingController(text: '${data['brand'] ?? ''}');
    _namaController = TextEditingController(text: '${data['nama'] ?? ''}');
    _jenisController = TextEditingController(text: '${data['jenis'] ?? ''}');
    _usiaMinController = TextEditingController(text: _angka(data['usiaMinBulan']));
    _usiaMaxController = TextEditingController(text: _angka(data['usiaMaxBulan']));
    _jenisBahan = _pilihanValid(data['jenisBahan'], _bahan, _bahan.first);
    _genderPakaian = _pilihanValid(data['genderPakaian'], _gender, 'Unisex');
    _sizeType = _pilihanValid(data['sizeType'], _tipeUkuran, _tipeUkuran.first);
    final sizes = (data['sizes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _ukuran = sizes.map(_UkuranController.fromMap).toList();
    if (_ukuran.isEmpty) _ukuran = [_UkuranController()];
  }

  String _angka(dynamic value) => value == null ? '' : value.toString();

  String _pilihanValid(dynamic value, List<String> pilihan, String fallback) {
    final text = value?.toString();
    return pilihan.contains(text) ? text! : fallback;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _namaController.dispose();
    _jenisController.dispose();
    _usiaMinController.dispose();
    _usiaMaxController.dispose();
    for (final item in _ukuran) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    final brand = _brandController.text.trim();
    final nama = _namaController.text.trim();
    final jenis = _jenisController.text.trim();
    final usiaMin = _parseUsia(_usiaMinController.text);
    final usiaMax = _parseUsia(_usiaMaxController.text);

    if (brand.isEmpty || nama.isEmpty || jenis.isEmpty) {
      _pesan('Brand, nama, dan jenis pakaian wajib diisi.');
      return;
    }
    if ((_usiaMinController.text.trim().isNotEmpty && usiaMin == null) ||
        (_usiaMaxController.text.trim().isNotEmpty && usiaMax == null)) {
      _pesan('Rentang usia harus berupa angka bulat positif.');
      return;
    }
    if ((usiaMin == null) != (usiaMax == null)) {
      _pesan('Isi usia dari dan usia sampai, atau kosongkan keduanya.');
      return;
    }
    if (usiaMin != null && usiaMin > usiaMax!) {
      _pesan('Usia dari tidak boleh lebih besar dari usia sampai.');
      return;
    }

    final ukuran = <Map<String, dynamic>>[];
    final namaUkuran = <String>{};
    for (final item in _ukuran) {
      final ukuranItem = item.validasi();
      if (ukuranItem == null) {
        _pesan('Setiap ukuran harus memiliki nama, lebar dada, dan panjang baju lebih dari 0.');
        return;
      }
      if (!namaUkuran.add(ukuranItem['size'] as String)) {
        _pesan('Nama ukuran tidak boleh sama.');
        return;
      }
      ukuran.add(ukuranItem);
    }

    setState(() => _menyimpan = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('pakaian').doc(widget.documentId).update({
        'brand': brand,
        'nama': nama,
        'jenis': jenis,
        'jenisBahan': _jenisBahan,
        'genderPakaian': _genderPakaian,
        'usiaMinBulan': usiaMin,
        'usiaMaxBulan': usiaMax,
        'sizeType': _sizeType,
        'sizes': ukuran,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Data pakaian berhasil diperbarui.')),
      );
    } on FirebaseException catch (error) {
      _pesan('Gagal menyimpan data: ${error.message ?? error.code}');
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  int? _parseUsia(String value) {
    if (value.trim().isEmpty) return null;
    final result = int.tryParse(value.trim());
    return result != null && result >= 0 ? result : null;
  }

  void _pesan(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.85;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF1C1),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Image.asset('assets/images/raywise_logo.png', height: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Data Pakaian',
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
                          _field('Brand', _brandController),
                          const SizedBox(height: 16),
                          _field('Nama Pakaian', _namaController),
                          const SizedBox(height: 16),
                          _field('Jenis Pakaian', _jenisController),
                          const SizedBox(height: 16),
                          _dropdown('Jenis Bahan', _jenisBahan, _bahan,
                              (value) => setState(() => _jenisBahan = value)),
                          const SizedBox(height: 16),
                          _dropdown('Target Jenis Kelamin', _genderPakaian,
                              _gender, (value) => setState(() => _genderPakaian = value)),
                          const SizedBox(height: 16),
                          const Text('Rentang Usia Target', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _field('Usia Dari (Bulan)', _usiaMinController, angka: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _field('Usia Sampai (Bulan)', _usiaMaxController, angka: true)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _dropdown('Tipe Size', _sizeType, _tipeUkuran,
                              (value) => setState(() => _sizeType = value)),
                          const SizedBox(height: 8),
                          const Text('Detail Ukuran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 10),
                          ..._ukuran.asMap().entries.map((entry) => _ukuranCard(entry.key, entry.value)),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _ukuran.add(_UkuranController())),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Ukuran'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB88700),
                                side: const BorderSide(color: Color(0xFFB88700)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
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
                      onPressed: _menyimpan ? null : _simpan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB88700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: _menyimpan
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: -57,
            bottom: -40,
            child: IgnorePointer(child: Image.asset('assets/images/boneka2.png', height: 180)),
          ),
        ],
      ),
    );
  }

  Widget _ukuranCard(int index, _UkuranController item) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFFFF6CC), borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Text('Ukuran ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), IconButton(onPressed: _ukuran.length == 1 ? null : () => setState(() { final removed = _ukuran.removeAt(index); removed.dispose(); }), icon: const Icon(Icons.delete_outline, color: Color(0xFFB88700)))]),
      const Divider(color: Color(0xFFE7C27D), thickness: 1),
      const SizedBox(height: 8),
      _field('Nama Size', item.size),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(color: Color(0xFFE7C27D), thickness: 1),
      ),
      Row(children: [Expanded(child: _field('Lebar Dada', item.lebarDada, angka: true)), const SizedBox(width: 12), Expanded(child: _field('Panjang Baju', item.panjangBaju, angka: true))]),
    ]),
  );

  Widget _field(String label, TextEditingController controller, {bool angka = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), TextField(controller: controller, keyboardType: angka ? TextInputType.number : TextInputType.text, decoration: _inputDecoration()),]);

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), DropdownButtonFormField<String>(value: value, decoration: _inputDecoration(), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) { if (value != null) onChanged(value); }),]);

  InputDecoration _inputDecoration() => InputDecoration(filled: true, fillColor: const Color(0xFFFFF6CC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none));
}

class _UkuranController {
  final size = TextEditingController();
  final lebarDada = TextEditingController();
  final panjangBaju = TextEditingController();

  _UkuranController();

  _UkuranController.fromMap(Map<String, dynamic> data) {
    size.text = '${data['size'] ?? ''}';
    lebarDada.text = '${data['lebar_dada'] ?? ''}';
    panjangBaju.text = '${data['panjang_baju'] ?? ''}';
  }

  Map<String, dynamic>? validasi() {
    final nama = size.text.trim();
    final dada = int.tryParse(lebarDada.text.trim());
    final panjang = int.tryParse(panjangBaju.text.trim());
    if (nama.isEmpty || dada == null || panjang == null || dada <= 0 || panjang <= 0) return null;
    return {'size': nama, 'lebar_dada': dada, 'panjang_baju': panjang};
  }

  void dispose() { size.dispose(); lebarDada.dispose(); panjangBaju.dispose(); }
}
