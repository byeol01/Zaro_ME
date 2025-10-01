import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Failed to sign in: $e');
      return null;
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Failed to sign up in service: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Failed to sign in with Google: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithKakao() async {
    try {
      kakao.OAuthToken token;
      if (await kakao.isKakaoTalkInstalled()) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final idToken = token.idToken;
      if (idToken == null) {
        throw Exception('Kakao ID token is null');
      }

      final providerId = kIsWeb ? 'oidc.kakao2' : 'oidc.kakao';
      final provider = OAuthProvider(providerId);
      final credential = provider.credential(idToken: idToken);

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Failed to sign in with Kakao (OIDC): $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithNaver() async {
    final Completer<String?> completer = Completer<String?>();

    try {
      await NaverLoginSDK.authenticate(
        callback: OAuthLoginCallback(
          onSuccess: () async {
            final token = await NaverLoginSDK.getAccessToken();
            completer.complete(token);
          },
          onFailure: (httpStatus, message) {
            print("Naver Login Failed: $httpStatus - $message");
            completer.complete(null);
          },
          onError: (errorCode, message) {
            print("Naver Login Error: $errorCode - $message");
            completer.complete(null);
          },
        ),
      );

      final String? naverAccessToken = await completer.future;

      if (naverAccessToken == null) {
        return null;
      }

      final cloudFunctionUrl = Uri.parse(
        'https://us-central1-zerome.cloudfunctions.net/naverAuth',
      );

      final response = await http.post(
        cloudFunctionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': naverAccessToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final firebaseCustomToken = data['firebase_token'];
        return await _auth.signInWithCustomToken(firebaseCustomToken);
      } else {
        print('Cloud Function failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('An error occurred during Naver sign-in process: $e');
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return null;
    }
  }
}
