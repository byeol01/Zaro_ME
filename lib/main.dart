import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/login_scr.dart';
import 'screens/home_scr.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: Could not load .env file: $e");
  }

  try {
    if (kIsWeb) {
      final kakaoJavaScriptKey = dotenv.env['KAKAO_JAVASCRIPT_KEY'] ?? '';
      if (kakaoJavaScriptKey.isNotEmpty) {
        kakao.KakaoSdk.init(javaScriptAppKey: kakaoJavaScriptKey);
      } else {
        print("Warning: KAKAO_JAVASCRIPT_KEY not found in .env");
      }
    } else {
      final kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
      if (kakaoNativeAppKey.isNotEmpty) {
        kakao.KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
      } else {
        print("Warning: KAKAO_NATIVE_APP_KEY not found in .env");
      }
    }
  } catch (e) {
    print("Warning: Failed to initialize Kakao SDK: $e");
  }

  try {
    await NaverLoginSDK.initialize(
      clientId: dotenv.env['NAVER_CLIENT_ID'] ?? '',
      clientSecret: dotenv.env['NAVER_CLIENT_SECRET'] ?? '',
      clientName: dotenv.env['NAVER_APP_NAME'] ?? '',
    );
  } catch (e) {
    print("Warning: Failed to initialize NaverLoginSDK: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
      print("Firebase App Check (Android) initialized successfully");
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.appAttest,
      );
      print("Firebase App Check (iOS) initialized successfully");
    } else {
      print("Firebase App Check skipped for web/desktop platform");
    }
  } catch (e) {
    print("Warning: Failed to initialize Firebase App Check: $e");
  }

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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomeScreen(user: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}
