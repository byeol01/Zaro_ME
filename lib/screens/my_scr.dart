import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:zaro_me_app/screens/activity_history_screen.dart';
import 'package:zaro_me_app/services/auth_service.dart';
import 'package:zaro_me_app/screens/login_scr.dart';

class MyScreen extends StatefulWidget {
  final User user;
  const MyScreen({super.key, required this.user});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '정보 없음';
    return DateFormat('yyyy.MM.dd').format(date);
  }

  Future<void> _showEditProfileDialog(
    String currentName,
    String currentEmail,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('프로필 수정'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: '이메일'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () async {
                final newName = nameController.text;
                final newEmail = emailController.text;
                if (newName.isEmpty || newEmail.isEmpty) return;
                try {
                  await widget.user.updateDisplayName(newName);
                  await _firestore.collection('users').doc(widget.user.uid).set(
                    {'displayName': newName, 'email': newEmail},
                    SetOptions(merge: true),
                  );
                  if (mounted) Navigator.of(context).pop();
                } catch (e) {
                  debugPrint("프로필 업데이트 실패: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildProfileUI(
            userName: widget.user.displayName ?? '사용자',
            email: widget.user.email ?? '이메일 정보 없음',
            level: 1,
            totalPoints: 0,
            trashCount: 0,
            foodGrams: 0,
            transportCount: 0,
            recycleCount: 0,
          );
        }

        final data = snapshot.data!.data()!;
        final totalPoints = data['totalPoints'] ?? 0;
        final userName =
            data['displayName'] ?? widget.user.displayName ?? '사용자';
        final email = data['email'] ?? widget.user.email ?? '이메일 정보 없음';
        final level = (totalPoints / 500).floor() + 1;
        final trashCount = data['trash_count'] ?? 0;
        final foodGrams = data['food_grams'] ?? 0;
        final transportCount = data['transport_count'] ?? 0;
        final recycleCount = data['recycle_count'] ?? 0;

        return _buildProfileUI(
          userName: userName,
          email: email,
          level: level,
          totalPoints: totalPoints,
          trashCount: trashCount,
          foodGrams: foodGrams,
          transportCount: transportCount,
          recycleCount: recycleCount,
        );
      },
    );
  }

  Widget _buildProfileUI({
    required String userName,
    required String email,
    required int level,
    required int totalPoints,
    required int trashCount,
    required int foodGrams,
    required int transportCount,
    required int recycleCount,
  }) {
    final creationDate = widget.user.metadata.creationTime;
    return Scaffold(
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
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/lv_$level.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/images/lv_1.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Level $level',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 24),
                children: [
                  TextSpan(
                    text: '총 기여 포인트: ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextSpan(
                    text: '$totalPoints',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard('개인정보', [
              '이름: $userName',
              '이메일: $email',
              '가입일: ${_formatDate(creationDate)}',
            ], () => _showEditProfileDialog(userName, email)),
            const SizedBox(height: 20),
            _buildInfoCard('환경 기여 통계', [
              '쓰레기 줄이기: ${trashCount}회',
              '줄인 잔반량: ${foodGrams}g',
              '대중교통 이용: ${transportCount}회',
              '분리수거: ${recycleCount}회',
            ]),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivityHistoryScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('내 기록 보기'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    List<String> items, [
    VoidCallback? onEditPressed,
  ]) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (onEditPressed != null)
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.green,
                      ),
                      onPressed: onEditPressed,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(item, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
