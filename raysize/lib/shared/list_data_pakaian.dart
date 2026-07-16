import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raysize/admin/edit_pakaian_page.dart';

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
                    "Brand: ${data['brand']} • Jenis: ${data['jenis']} • Bahan: ${data['jenisBahan'] ?? '-'}",
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
                          _infoRow("Jenis Bahan", data['jenisBahan'] ?? '-'),
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
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xFFB88700),
                          ),

                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            verticalInside: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            left: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
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
                    ),

                    const SizedBox(height: 16),

                    // 🔹 BUTTON
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPakaianPage(
                                  documentId: doc.id,
                                  pakaian: data,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ), // optional tapi aman
                          label: const Text(
                            "Edit",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB88700),
                            foregroundColor: Colors.white, // 🔥 INI WAJIB
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('pakaian')
                                .doc(doc.id)
                                .delete();
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            "Hapus",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB88700),
                            foregroundColor: Colors.white, // 🔥 INI WAJIB
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

}
