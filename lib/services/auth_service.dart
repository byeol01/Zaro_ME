import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 이메일 & 비밀번호로 로그인
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // 로그인 실패 시 예외 처리
      print('Failed to sign in: $e');
      return null;
    }
  }

  // 이메일 & 비밀번호로 회원가입
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // 회원가입 실패 시 예외 처리
      print('Failed to sign up: $e');
      return null;
    }
  }

  // TODO: 로그아웃, 소셜 로그인 등 추가
}
