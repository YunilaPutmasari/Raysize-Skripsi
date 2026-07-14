import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RiwayatRekomendasiPage extends StatefulWidget {
  const RiwayatRekomendasiPage({super.key});

  @override
  State<RiwayatRekomendasiPage> createState() => _RiwayatRekomendasiPageState();
}

class _RiwayatRekomendasiPageState extends State<RiwayatRekomendasiPage> {
  final searchController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  String searchText = '';
  String selectedWeight = '';
  String selectedHeight = '';
  String selectedGender = 'Semua';

  @override
  void dispose() {
    searchController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User belum login')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      body: SafeArea(
        child: Column(
          children: [
            // Header dipertahankan sesuai desain awal.
            const SizedBox(height: 30),
            Image.asset('assets/images/raywise_logo.png', height: 70),
            const SizedBox(height: 16),
            const Text(
              'RIWAYAT REKOMENDASI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => searchText = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Cari nama, produk, ukuran, umur, berat, tinggi...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchText.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchText = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: ['Semua', 'Laki-laki', 'Perempuan'].map((gender) {
                  final selected = selectedGender == gender;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(gender),
                      selected: selected,
                      selectedColor: const Color(0xFFB88700),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF4A3A1A),
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => selectedGender = gender),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _NumberFilterField(
                      controller: weightController,
                      label: 'BB (kg)',
                      icon: Icons.monitor_weight_outlined,
                      onChanged: (value) =>
                          setState(() => selectedWeight = value.trim()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NumberFilterField(
                      controller: heightController,
                      label: 'TB (cm)',
                      icon: Icons.height_rounded,
                      onChanged: (value) =>
                          setState(() => selectedHeight = value.trim()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _RiwayatList(
                uid: user.uid,
                searchText: searchText,
                selectedGender: selectedGender,
                selectedWeight: selectedWeight,
                selectedHeight: selectedHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberFilterField extends StatelessWidget {
  const _NumberFilterField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _RiwayatList extends StatelessWidget {
  const _RiwayatList({
    required this.uid,
    required this.searchText,
    required this.selectedGender,
    required this.selectedWeight,
    required this.selectedHeight,
  });

  final String uid;
  final String searchText;
  final String selectedGender;
  final String selectedWeight;
  final String selectedHeight;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('riwayat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _message('Riwayat tidak bisa dimuat.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final gender = _value(data, 'jenisKelamin');
          final matchesGender =
              selectedGender == 'Semua' || gender == selectedGender;
          // Jika BB dan TB sama-sama diisi, kedua syarat wajib cocok (AND).
          final matchesWeight =
              selectedWeight.isEmpty ||
              _numberEquals(_value(data, 'berat'), selectedWeight);
          final matchesHeight =
              selectedHeight.isEmpty ||
              _numberEquals(_value(data, 'tinggi'), selectedHeight);
          final query = searchText.toLowerCase();
          if (query.isEmpty) {
            return matchesGender && matchesWeight && matchesHeight;
          }

          // Tambahkan field namaPelanggan/noHp ketika menyimpan data agar
          // riwayat juga dapat dicari berdasarkan identitas pelanggan.
          final searchable = [
            'namaPelanggan',
            'nama',
            'noHp',
            'namaPakaian',
            'rekomendasi',
            'umur',
            'berat',
            'tinggi',
            'jenisKelamin',
          ].map((key) => _value(data, key).toLowerCase()).join(' ');
          return matchesGender &&
              matchesWeight &&
              matchesHeight &&
              searchable.contains(query);
        }).toList();

        if (docs.isEmpty) {
          return _message(
            searchText.isEmpty
                ? 'Belum ada riwayat rekomendasi.'
                : 'Tidak ada data yang sesuai dengan pencarian.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _HistoryCard(doc: docs[index], uid: uid),
        );
      },
    );
  }

  static String _value(Map<String, dynamic> data, String key) =>
      (data[key] ?? '').toString().trim();

  static bool _numberEquals(String storedValue, String filterValue) {
    final stored = _firstNumber(storedValue);
    final filter = _firstNumber(filterValue);
    return stored != null && filter != null && stored == filter;
  }

  static double? _firstNumber(String value) {
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(value);
    return match == null
        ? null
        : double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.manage_search_rounded,
            size: 54,
            color: Color(0xFFB8A77F),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7A6A4F)),
          ),
        ],
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.doc, required this.uid});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    String value(String key) => (data[key] ?? '-').toString();
    final customer = (data['namaPelanggan'] ?? data['nama'] ?? '').toString();

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context, data),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E7C8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: Color(0xFFB88700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value('namaPakaian'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (customer.isNotEmpty)
                          Text(
                            customer,
                            style: const TextStyle(color: Color(0xFF7A6A4F)),
                          ),
                      ],
                    ),
                  ),
                  _SizeBadge(size: value('rekomendasi')),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.cake_outlined,
                    label: '${value('umur')} th',
                  ),
                  _InfoChip(
                    icon: Icons.monitor_weight_outlined,
                    label: '${value('berat')} kg',
                  ),
                  _InfoChip(
                    icon: Icons.height_rounded,
                    label: '${value('tinggi')} cm',
                  ),
                  _InfoChip(
                    icon: Icons.person_outline,
                    label: value('jenisKelamin'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hapus riwayat?'),
          content: const Text('Data rekomendasi ini akan dihapus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _delete(BuildContext context, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('riwayat')
          .doc(doc.id)
          .delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Riwayat dihapus'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('riwayat')
                .doc(doc.id)
                .set(data),
          ),
        ),
      );
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus riwayat.')),
        );
    }
  }
}

class _SizeBadge extends StatelessWidget {
  const _SizeBadge({required this.size});
  final String size;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFB88700),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      size,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF7A6A4F)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5C513E)),
        ),
      ],
    ),
  );
}
