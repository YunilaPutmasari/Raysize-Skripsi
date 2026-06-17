import 'package:flutter/material.dart';
import 'package:raysize/shared/bottom_navbar.dart';
import 'package:raysize/shared/profile.dart';
import 'package:raysize/shared/riwayat_rekomendasi_page.dart';

import 'home_admin_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeAdminPage(),
    RiwayatRekomendasiPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
