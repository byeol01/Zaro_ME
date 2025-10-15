import 'package:flutter/material.dart';

typedef OnRecordTap = void Function(String type, String title);

class ActivityRecordSection extends StatelessWidget {
  final OnRecordTap onRecordTap;

  const ActivityRecordSection({super.key, required this.onRecordTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Align(
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
        Column(
          children: [
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
    );
  }

  Widget _buildRecordCard({
    required IconData icon,
    required String title,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => onRecordTap(type, title),
      child: Container(
        width: 180,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 48, color: const Color(0xFF2E7D32)),
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
}
