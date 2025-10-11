import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/header.dart';
import '../components/bottom_nav.dart';
import 'my_scr.dart';
import 'home_sec1.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _userLevel = 1;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeSec1(user: widget.user),
      const MapScreen(),
      MyScreen(user: widget.user),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToMyPage() {
    setState(() {
      _currentIndex = 2;
    });
  }

  void _navigateToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        userLevel: _userLevel,
        onProfileTap: _navigateToMyPage,
        onLogoTap: _navigateToHome,
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
