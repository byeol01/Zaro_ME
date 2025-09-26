import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_scr.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ZeroMeApp());
}

class ZeroMeApp extends StatelessWidget {
  const ZeroMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 디버그 모드에서 오른쪽 상단에 뜨는 "DEBUG" 배너 제거
      debugShowCheckedModeBanner: false,
      title: 'ZeroMe',
      theme: ThemeData(
        // 앱의 전반적인 색상 테마 설정
        primarySwatch: Colors.green,
        // 배경색 설정
        scaffoldBackgroundColor: const Color(0xFFF0F4C3), // 연한 라임색 배경
      ),
      home: const LoginScreen(),
    );
  }
}
