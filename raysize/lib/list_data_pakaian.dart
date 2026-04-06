import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PakaianListPage extends StatelessWidget {
  const PakaianListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1C1),
      appBar: AppBar(
        title: const Text("Data Pakaian Anak"),
        backgroundColor: const Color(0xFFB88700),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pakaian')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Belum ada data pakaian"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final sizes = List<Map<String, dynamic>>.from(
                data['sizes'] ?? [],
              );
              final timestamp = data['createdAt'] as Timestamp?;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7C27D).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),

                  title: Text(
                    data['nama'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  subtitle: Text(
                    "Brand: ${data['brand']} • Jenis: ${data['jenis']}",
                  ),

                  children: [
                    // 🔹 DETAIL INFO
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6CC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow("Kategori Size", data['sizeType']),
                          _infoRow(
                            "Range",
                            "${sizes.first['size']} - ${sizes.last['size']}",
                          ),
                          _infoRow("Total Size", sizes.length.toString()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 TABEL SIZE
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFB88700),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Size",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Lebar Dada",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Panjang Baju",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                        rows: sizes.map<DataRow>((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(item['size'].toString())),
                              DataCell(Text(item['lebar_dada'].toString())),
                              DataCell(Text(item['panjang_baju'].toString())),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🔹 BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _showEditDialog(context, doc.id, data);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('pakaian')
                                .doc(doc.id)
                                .delete();
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text("Hapus"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label : $value",
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  static void _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final brandController = TextEditingController(text: data['brand']);
    final namaController = TextEditingController(text: data['nama']);
    final jenisController = TextEditingController(text: data['jenis']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Data Pakaian"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: "Brand"),
              ),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama"),
              ),
              TextField(
                controller: jenisController,
                decoration: const InputDecoration(labelText: "Jenis"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('pakaian')
                    .doc(docId)
                    .update({
                      'brand': brandController.text,
                      'nama': namaController.text,
                      'jenis': jenisController.text,
                    });

                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }
}
