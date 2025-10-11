import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/eco_activity.dart';
import './photo_view_screen.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  Future<List<EcoActivity>> _loadActivities() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('activities')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => EcoActivity.fromJson(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 활동 기록'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 1,
      ),
      body: FutureBuilder<List<EcoActivity>>(
        future: _loadActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('아직 활동 기록이 없습니다.'));
          }

          final activities = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ActivityCard(activity: activity);
            },
          );
        },
      ),
    );
  }
}

class ActivityCard extends StatefulWidget {
  final EcoActivity activity;
  const ActivityCard({super.key, required this.activity});

  @override
  State<ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy년 MM월 dd일 HH:mm',
    ).format(widget.activity.createdAt);
    final unit = widget.activity.type == 'food' ? 'g' : '회';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.activity.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${widget.activity.count}$unit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.activity.imageUrl != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotoViewScreen(
                                  imageUrl: widget.activity.imageUrl!,
                                  heroTag: widget.activity.id,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: widget.activity.id,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.activity.imageUrl!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 180,
                                        alignment: Alignment.center,
                                        child:
                                            const CircularProgressIndicator(),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      if (widget.activity.imageUrl != null)
                        const SizedBox(height: 12),
                      if (widget.activity.note != null &&
                          widget.activity.note!.isNotEmpty)
                        Text(
                          '메모: ${widget.activity.note}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
