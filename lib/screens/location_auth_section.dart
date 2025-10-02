import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationAuthSection extends StatefulWidget {
  const LocationAuthSection({super.key});

  @override
  State<LocationAuthSection> createState() => _LocationAuthSectionState();
}

class _LocationAuthSectionState extends State<LocationAuthSection> {
  String _locationText = "지역인증을 해주세요!";
  bool _isLocationAuthenticated = false;
  String _localRanking = "";
  String _contribution = "";

  void _authenticateLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('위치 권한이 필요합니다')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다')));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String location = _getLocationFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _isLocationAuthenticated = true;
        _locationText = "지역인증 완료!";
        _localRanking = location;
        _contribution = "상위 12%";
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('위치를 가져올 수 없습니다: $e')));
    }
  }

  String _getLocationFromCoordinates(double lat, double lng) {
    if (lat >= 37.4 && lat <= 37.6 && lng >= 126.8 && lng <= 127.0) {
      return "금천구";
    } else if (lat >= 37.5 && lat <= 37.6 && lng >= 127.0 && lng <= 127.1) {
      return "강남구";
    } else if (lat >= 37.5 && lat <= 37.6 && lng >= 126.9 && lng <= 127.0) {
      return "서초구";
    } else if (lat >= 37.6 && lat <= 37.7 && lng >= 126.9 && lng <= 127.1) {
      return "성북구";
    } else if (lat >= 37.4 && lat <= 37.5 && lng >= 126.9 && lng <= 127.0) {
      return "영등포구";
    } else {
      return "서울시";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          if (!_isLocationAuthenticated)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _locationText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            ),
          if (_isLocationAuthenticated)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRankingCard(label: "지역랭킹", value: _localRanking),
                    const SizedBox(width: 16),
                    _buildRankingCard(label: "기여도", value: _contribution),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _authenticateLocation,
                child: Image.asset(
                  'assets/images/zarome.png',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 250,
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.trending_up, size: 16, color: Colors.red),
        ],
      ),
    );
  }
}
