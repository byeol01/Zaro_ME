import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/eco_activity.dart';

class ActivityAuthPage extends StatefulWidget {
  final String activityType;
  final String activityTitle;

  const ActivityAuthPage({
    super.key,
    required this.activityType,
    required this.activityTitle,
  });

  @override
  State<ActivityAuthPage> createState() => _ActivityAuthPageState();
}

class _ActivityAuthPageState extends State<ActivityAuthPage> {
  int _count = 1;
  final TextEditingController _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.activityTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveActivity,
            child: const Text(
              '기록하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getActivityIcon(widget.activityType),
                size: 60,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              widget.activityTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '개수',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_count > 1) {
                            setState(() {
                              _count--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '$_count',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _count++;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '메모 (선택사항)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: '활동에 대한 메모를 작성해주세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFF2E7D32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '기록하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'trash':
        return Icons.delete_outline;
      case 'food':
        return Icons.restaurant_outlined;
      case 'transport':
        return Icons.train_outlined;
      case 'recycle':
        return Icons.recycling_outlined;
      default:
        return Icons.eco;
    }
  }

  void _saveActivity() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }

    final collection = FirebaseFirestore.instance.collection('activities');
    final docId = collection.doc().id;

    final activity = EcoActivity(
      id: docId,
      userId: user.uid,
      type: widget.activityType,
      title: widget.activityTitle,
      count: _count,
      createdAt: DateTime.now(),
    );

    try {
      await collection.doc(docId).set(activity.toJson());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
