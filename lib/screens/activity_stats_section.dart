import 'package:flutter/material.dart';
import '../models/eco_activity.dart';

class ActivityStatsSection extends StatelessWidget {
  final EcoActivityData activityData;

  const ActivityStatsSection({super.key, required this.activityData});

  int _getActivityCount(String type) {
    try {
      return activityData.activityCounts[type] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
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
        width: 80,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Container(width: 30, height: 1, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
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
