import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../components/header.dart';
import '../components/bottom_nav.dart';
import 'my_scr.dart';
import 'home_sec1.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _userLevel = 1;

  static const CameraPosition _seoulCityHall = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 15.0,
  );

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToMyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyScreen(userLevel: _userLevel)),
    ).then((result) {
      if (result != null && result is int) {
        setState(() {
          _userLevel = result;
        });
      }
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
      body: _getBody(),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildSearchContent();
      case 2:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return const SingleChildScrollView(child: Column(children: [HomeSec1()]));
  }

  Widget _buildSearchContent() {
    return const GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _seoulCityHall,
    );
  }

  Widget _buildProfileContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 100, color: Colors.green),
          SizedBox(height: 20),
          Text(
            '프로필 화면',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '사용자 프로필이 여기에 들어갑니다.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
