import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final int userLevel;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoTap;
  
  const CustomHeader({
    super.key,
    this.userLevel = 1,
    this.onProfileTap,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // 연한 라임색 배경
      foregroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: onLogoTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16),
            Image.asset(
              'assets/images/logo2.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text(
              'Zaro_ME',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32), // 진한 녹색 글자
                fontSize: 18,
                
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 200,
      actions: [
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/images/lv_$userLevel.png',
              height: 32,
              width: 32,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
