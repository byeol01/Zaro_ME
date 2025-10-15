import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _countController.text = '1';
  }

  @override
  void dispose() {
    _noteController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isUploading) return;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("이미지 선택 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사진을 가져오는 데 실패했습니다.')));
      }
    }
  }

  void _incrementCount() {
    int currentVal = int.tryParse(_countController.text) ?? 0;
    currentVal++;
    setState(() {
      _countController.text = currentVal.toString();
    });
  }

  void _decrementCount() {
    int currentVal = int.tryParse(_countController.text) ?? 1;
    if (currentVal > 1) {
      currentVal--;
      setState(() {
        _countController.text = currentVal.toString();
      });
    }
  }

  Widget _buildInputSection() {
    if (widget.activityType == 'food') {
      return Container(
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
              '줄인 잔반량 (g)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _countController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                decoration: const InputDecoration(
                  hintText: 'g',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
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
              '횟수',
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
                  onPressed: _decrementCount,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _countController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: _incrementCount,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '사진 인증 (필수)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                      SizedBox(height: 8),
                      Text('터치해서 사진 찍기', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

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
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
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
      body: SingleChildScrollView(
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
            _buildInputSection(),
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
            const SizedBox(height: 30),
            _buildPhotoSection(),
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
    if (_isUploading) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }

    final inputValue = int.tryParse(_countController.text) ?? 0;
    if (inputValue <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('1 이상의 값을 입력해주세요.')));
      }
      return;
    }

    if (_imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('인증을 위한 사진을 첨부해주세요.')));
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl;
    final docId = FirebaseFirestore.instance.collection('activities').doc().id;

    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('activity_photos')
            .child(user.uid)
            .child('$docId.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('사진 업로드 실패: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('사진 업로드에 실패했습니다.')));
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }
    }

    final activity = EcoActivity(
      id: docId,
      userId: user.uid,
      type: widget.activityType,
      title: widget.activityTitle,
      count: inputValue,
      createdAt: DateTime.now(),
      note: _noteController.text,
      imageUrl: imageUrl,
    );

    try {
      await FirebaseFirestore.instance
          .collection('activities')
          .doc(activity.id)
          .set(activity.toJson());

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      Map<String, dynamic> statsToUpdate = {};
      int pointsToAdd = 0;

      switch (activity.type) {
        case 'food':
          statsToUpdate['food_grams'] = FieldValue.increment(inputValue);
          pointsToAdd = (inputValue / 10).floor();
          break;
        case 'trash':
          statsToUpdate['trash_count'] = FieldValue.increment(inputValue);
          pointsToAdd = inputValue * 15;
          break;
        case 'transport':
          statsToUpdate['transport_count'] = FieldValue.increment(inputValue);
          pointsToAdd = inputValue * 10;
          break;
        case 'recycle':
          statsToUpdate['recycle_count'] = FieldValue.increment(inputValue);
          pointsToAdd = inputValue * 20;
          break;
      }

      if (pointsToAdd > 0) {
        statsToUpdate['totalPoints'] = FieldValue.increment(pointsToAdd);
      }

      if (statsToUpdate.isNotEmpty) {
        await userRef.set(statsToUpdate, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pop(context, activity);
      }
    } catch (e) {
      debugPrint('저장 및 통계 업데이트 실패: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}
