import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RiwayatRekomendasiPage extends StatefulWidget {
  const RiwayatRekomendasiPage({super.key});

  @override
  State<RiwayatRekomendasiPage> createState() => _RiwayatRekomendasiPageState();
}

class _RiwayatRekomendasiPageState extends State<RiwayatRekomendasiPage> {
  final TextEditingController searchController = TextEditingController();
  String searchText = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User belum login")));
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Image.asset('assets/images/raywise_logo.png', height: 70),
            const SizedBox(height: 16),
            const Text(
              'RIWAYAT REKOMENDASI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            /// 🔍 SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() => searchText = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: 'Search produk...',
                  hintStyle: const TextStyle(color: Color(0xFF7A6A4F)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFB88700),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF6CC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔥 LIST RIWAYAT — dibungkus Builder + cek mounted
            Expanded(
              child: _RiwayatList(uid: uid, searchText: searchText),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔥 Pisahkan list ke widget sendiri biar StreamBuilder
/// terisolasi dan aman saat parent widget di-dispose
class _RiwayatList extends StatelessWidget {
  final String uid;
  final String searchText;

  const _RiwayatList({required this.uid, required this.searchText});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('riwayat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // 🔥 Cegah error "deactivated widget" — cek dulu
        if (!context.mounted) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "Terjadi kesalahan: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("Belum ada riwayat"));
        }

        /// 🔍 FILTER SEARCH
        final filteredDocs = docs.where((doc) {
          try {
            final nama = (doc['namaPakaian'] ?? "").toString().toLowerCase();
            return nama.contains(searchText);
          } catch (_) {
            return false;
          }
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text("Data tidak ditemukan"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final item = filteredDocs[index];
            final docId = item.id;
            final deletedData = (item.data() as Map<String, dynamic>?) ?? {};

            return Dismissible(
              key: Key(docId),

              confirmDismiss: (direction) async {
                // 🔥 Cegah error deactivated
                if (!context.mounted) return false;

                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: const Color(0xFFFFF6CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      "Hapus Riwayat",
                      style: TextStyle(
                        color: Color(0xFF4A3A1A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      "Yakin ingin menghapus riwayat ini?",
                      style: TextStyle(color: Color(0xFF7A6A4F)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text(
                          "Batal",
                          style: TextStyle(
                            color: Color(0xFFB88700),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB88700),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text("Hapus"),
                      ),
                    ],
                  ),
                );

                return result ?? false;
              },

              onDismissed: (direction) async {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('riwayat')
                      .doc(docId)
                      .delete();

                  // 🔥 WAJIB cek mounted sebelum pakai context
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF4A3A1A),
                      content: const Text(
                        "Riwayat dihapus",
                        style: TextStyle(color: Colors.white),
                      ),
                      action: SnackBarAction(
                        label: "Urungkan",
                        textColor: const Color(0xFFFFD54F),
                        onPressed: () async {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('riwayat')
                                .doc(docId)
                                .set(deletedData);
                          } catch (e) {
                            debugPrint("Gagal undo: $e");
                          }
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint("Gagal hapus: $e");
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal menghapus: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },

              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(right: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),

              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6C98F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.checkroom, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Umur: ${item['umur'] ?? '-'} th | ${item['berat'] ?? '-'} kg | ${item['tinggi'] ?? '-'} cm",
                          ),
                          Text("Gender: ${item['jenisKelamin'] ?? '-'}"),
                          Text("Produk: ${item['namaPakaian'] ?? '-'}"),
                          Text(
                            "Rekomendasi: ${item['rekomendasi'] ?? '-'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
