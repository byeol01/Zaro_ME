import 'package:flutter/material.dart';
import '../components/header.dart';

class MyScreen extends StatefulWidget {
  final int userLevel;
  
  const MyScreen({
    super.key,
    this.userLevel = 1,
  });

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late int currentLevel;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.userLevel;
  }

  void _updateLevel(int newLevel) {
    setState(() {
      currentLevel = newLevel;
    });
    Navigator.pop(context, newLevel);
  }

  void _navigateToHome() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomHeader(
        userLevel: currentLevel,
        onProfileTap: () {
        },
        onLogoTap: _navigateToHome,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/lv_$currentLevel.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Level $currentLevel',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '환경 기여도 레벨',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '레벨 테스트 (개발용)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(8, (index) {
                int level = index + 1;
                return ElevatedButton(
                  onPressed: () => _updateLevel(level),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentLevel == level ? Colors.green : Colors.grey[300],
                    foregroundColor: currentLevel == level ? Colors.white : Colors.black,
                  ),
                  child: Text('Lv.$level'),
                );
              }),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              '개인정보',
              [
                '이름: 사용자',
                '이메일: user@example.com',
                '가입일: 2024.01.01',
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              '환경 기여 통계',
              [
                '총 기여 포인트: ${currentLevel * 100}',
                '리사이클링 횟수: ${currentLevel * 5}',
                '탄소 절약량: ${currentLevel * 2.5}kg',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            )),
          ],
        ),
      ),
    );
  }
}