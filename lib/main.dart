import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/login_scr.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final kakaoAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'];
  if (kakaoAppKey != null) {
    KakaoSdk.init(nativeAppKey: kakaoAppKey);
  } else {
    print("FATAL: KAKAO_NATIVE_APP_KEY not found in .env file");
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(const ZeroMeApp());
}

class ZeroMeApp extends StatelessWidget {
  const ZeroMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroMe',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF0F4C3),
      ),
      home: const LoginScreen(),
    );
  }
}
