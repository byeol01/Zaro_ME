import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/eco_activity.dart';
import 'activity_auth_page.dart';
import 'location_auth_section.dart';
import 'activity_stats_section.dart';
import 'activity_record_section.dart';

class HomeSec1 extends StatefulWidget {
  final User user;

  const HomeSec1({super.key, required this.user});

  @override
  State<HomeSec1> createState() => _HomeSec1State();
}

class _HomeSec1State extends State<HomeSec1> {
  late final EcoActivityData _activityData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activityData = EcoActivityData();
    _loadInitialData(widget.user);
  }

  Future<void> _loadInitialData(User user) async {
    await _activityData.loadActivitiesFromFirestore(user);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRecordPage(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActivityAuthPage(activityType: type, activityTitle: title),
      ),
    ).then((result) {
      if (result != null && result is EcoActivity) {
        setState(() {
          _activityData.addActivity(result);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const LocationAuthSection(),
            const SizedBox(height: 50),
            ActivityStatsSection(activityData: _activityData),
            const SizedBox(height: 30),
            ActivityRecordSection(onRecordTap: _navigateToRecordPage),
          ],
        ),
      ),
    );
  }
}
