import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/eco_activity.dart';
import 'activity_auth_page.dart';

class HomeSec1 extends StatefulWidget {
  const HomeSec1({super.key});

  @override
  State<HomeSec1> createState() => _HomeSec1State();
}

class _HomeSec1State extends State<HomeSec1> {
  String _locationText = "지역인증을 해주세요!";
  bool _isLocationAuthenticated = false;
  String _localRanking = "";
  String _contribution = "";
  late final EcoActivityData _activityData; // late로 변경
  
  @override
  void initState() {
    super.initState();
    _activityData = EcoActivityData(); // initState에서 초기화
  }

  void _authenticateLocation() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 필요합니다')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다')),
        );
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 위치 기반 지역 인증
      String location = _getLocationFromCoordinates(position.latitude, position.longitude);
      
      setState(() {
        _isLocationAuthenticated = true;
        _locationText = "지역인증 완료!";
        _localRanking = location;
        _contribution = "상위 12%";
      });

      // 지역인증 완료 시 스낵바 제거 (UI에서만 표시)
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('$location 지역인증이 완료되었습니다!')),
      // );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치를 가져올 수 없습니다: $e')),
      );
    }
  }

  String _getLocationFromCoordinates(double lat, double lng) {
    // 간단한 지역 매핑 (실제로는 더 정확한 지오코딩 서비스 사용)
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 말풍선과 캐릭터
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                // 말풍선 (지역인증 전에만 표시)
                if (!_isLocationAuthenticated)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                // 지역랭킹과 기여도 (이미지와 상단 사이)
                if (_isLocationAuthenticated)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRankingCard(
                            label: "지역랭킹",
                            value: _localRanking,
                          ),
                          const SizedBox(width: 16),
                          _buildRankingCard(
                            label: "기여도",
                            value: _contribution,
                          ),
                        ],
                      ),
                    ),
                  ),
                // 캐릭터 이미지
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
          ),
          
          const SizedBox(height: 50),
          
          // 통계 카드
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatCard(
                icon: Icons.delete_outline,
                value: "${_getActivityCount('trash')}개",
                color: const Color(0xFF2E7D32),
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                icon: Icons.restaurant_outlined,
                value: "${_getActivityCount('food')}g",
                color: const Color(0xFF2E7D32),
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                icon: Icons.train_outlined,
                value: "${_getActivityCount('transport')}회",
                color: const Color(0xFF2E7D32),
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _buildStatCard(
                icon: Icons.recycling_outlined,
                value: "${_getActivityCount('recycle')}개",
                color: const Color(0xFF2E7D32),
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // 기록하기 섹션 - 작은 박스와 같은 위치로 조정
          Padding(
            padding: const EdgeInsets.only(left: 20), // 작은 박스와 같은 위치
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '기록하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 4개 카드 (2x2 그리드) - 중앙 정렬
          Column(
            children: [
              // 첫 번째 줄 - 중앙 정렬
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRecordCard(
                    icon: Icons.delete_outline,
                    title: '쓰레기줄이기',
                    type: 'trash',
                  ),
                  const SizedBox(width: 20),
                  _buildRecordCard(
                    icon: Icons.restaurant_outlined,
                    title: '잔반안남기기',
                    type: 'food',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 두 번째 줄 - 중앙 정렬
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRecordCard(
                    icon: Icons.train_outlined,
                    title: '대중교통이용하기',
                    type: 'transport',
                  ),
                  const SizedBox(width: 20),
                  _buildRecordCard(
                    icon: Icons.recycling_outlined,
                    title: '분리수거하기',
                    type: 'recycle',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard({
    required String label,
    required String value,
  }) {
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
          const Icon(
            Icons.trending_up,
            size: 16,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  int _getActivityCount(String type) {
    try {
      return _activityData.activityCounts[type] ?? 0;
    } catch (e) {
      return 0; // 오류 발생 시 0 반환
    }
  }

  void _navigateToRecordPage(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityAuthPage(
          activityType: type,
          activityTitle: title,
        ),
      ),
    ).then((result) {
      if (result != null && result is EcoActivity) {
        setState(() {
          _activityData.addActivity(result);
        });
      }
    });
  }

  Widget _buildRecordCard({
    required IconData icon,
    required String title,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => _navigateToRecordPage(type, title),
      child: Container(
        width: 180, // 너비 더 증가
        height: 140, // 높이 더 증가
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30), // 30px 패딩
          child: Column(
            children: [
              // 상단: 아이콘과 + 버튼
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: const Color(0xFF2E7D32),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // 하단: 텍스트 (왼쪽 정렬)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, // 70에서 80으로 증가
        height: 90, // 80에서 90으로 증가
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28, // 24에서 28로 증가
              color: color,
            ),
            const SizedBox(height: 8),
            Container(
              width: 30,
              height: 1,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13, // 12에서 13으로 증가
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

