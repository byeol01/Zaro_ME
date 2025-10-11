import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:zaro_me_app/services/auth_service.dart';
import 'package:zaro_me_app/screens/login_scr.dart';

class MyScreen extends StatefulWidget {
  final User user;

  const MyScreen({super.key, required this.user});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  late int currentLevel;
  late String _currentUserName;
  late String _currentEmail;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    currentLevel = 1;
    _loadInitialUserData();
  }

  void _loadInitialUserData() {
    _currentUserName = widget.user.displayName ?? '사용자';
    _currentEmail = widget.user.email ?? '이메일 정보 없음';

    _firestore.collection('users').doc(widget.user.uid).get().then((doc) {
      if (mounted && doc.exists && doc.data() != null) {
        setState(() {
          _currentUserName = doc.data()!['displayName'] ?? _currentUserName;
          _currentEmail = doc.data()!['email'] ?? _currentEmail;
        });
      }
    });
  }

  void _updateLevel(int newLevel) {
    setState(() {
      currentLevel = newLevel;
    });
  }

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

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _currentUserName);
    final emailController = TextEditingController(text: _currentEmail);

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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () async {
                final newName = nameController.text;
                final newEmail = emailController.text;

                if (newName.isEmpty || newEmail.isEmpty) {
                  return;
                }

                try {
                  await widget.user.updateDisplayName(newName);
                  await _firestore.collection('users').doc(widget.user.uid).set(
                    {'displayName': newName, 'email': newEmail},
                    SetOptions(merge: true),
                  );

                  setState(() {
                    _currentUserName = newName;
                    _currentEmail = newEmail;
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  print("프로필 업데이트 실패: $e");
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
    final creationDate = widget.user.metadata.creationTime;

    return SingleChildScrollView(
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          _buildInfoCard('개인정보', [
            '이름: $_currentUserName',
            '이메일: $_currentEmail',
            '가입일: ${_formatDate(creationDate)}',
          ]),
          const SizedBox(height: 20),
          _buildInfoCard('환경 기여 통계', [
            '총 기여 포인트: ${currentLevel * 100}',
            '리사이클링 횟수: ${currentLevel * 5}',
            '탄소 절약량: ${currentLevel * 2.5}kg',
          ]),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: const Text('로그아웃'),
          ),
          const SizedBox(height: 40),
          const Text(
            '레벨 테스트 (개발용)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(8, (index) {
              int level = index + 1;
              return ElevatedButton(
                onPressed: () => _updateLevel(level),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLevel == level
                      ? Colors.green
                      : Colors.grey[300],
                  foregroundColor: currentLevel == level
                      ? Colors.white
                      : Colors.black,
                ),
                child: Text('Lv.$level'),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      elevation: 2,
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
                  if (title == '개인정보')
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: _showEditProfileDialog,
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
