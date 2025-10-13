import 'package:flutter/material.dart';

class LocationAuthSection extends StatefulWidget {
  const LocationAuthSection({super.key});

  @override
  State<LocationAuthSection> createState() => _LocationAuthSectionState();
}

class _LocationAuthSectionState extends State<LocationAuthSection> {
  bool _isLocationAuthenticated = false;
  String _localRanking = "";
  String _contribution = "";

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          if (_isLocationAuthenticated)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRankingCard(label: "지역랭킹", value: _localRanking),
                    const SizedBox(width: 16),
                    _buildRankingCard(label: "기여도", value: _contribution),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: null,
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
    );
  }

  Widget _buildRankingCard({required String label, required String value}) {
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
          const Icon(Icons.trending_up, size: 16, color: Colors.red),
        ],
      ),
    );
  }
}
