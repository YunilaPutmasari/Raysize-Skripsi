import 'package:flutter/material.dart';
import 'home_host_page.dart';
import 'package:raysize/shared/bottom_navbar.dart';
import 'package:raysize/shared/profile.dart';
import 'package:raysize/shared/riwayat_rekomendasi_page.dart';


class HostMainPage extends StatefulWidget {
  const HostMainPage({super.key});

  @override
  State<HostMainPage> createState() => _HostMainPageState();
}

class _HostMainPageState extends State<HostMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeHostPage(),
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
