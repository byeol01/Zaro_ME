import 'package:flutter/material.dart';
import 'package:zaro_me_app/services/auth_service.dart';
import 'home_scr.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final email = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요')),
      );
      return;
    }

    final userCredential = await _authService.signInWithEmailAndPassword(email, password);

    if (userCredential != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인에 실패했습니다. 아이디 또는 비밀번호를 확인하세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 사이즈 정보를 가져옵니다.
    final screenSize = MediaQuery.of(context).size;
    
    // 모바일 앱에 최적화된 크기 설정
    final horizontalPadding = 24.0; // 모바일 앱에 적합한 패딩
    final logoSize = 0.5; // 모바일 앱에 적합한 로고 크기

    return Scaffold(
      body: SafeArea(
        // SingleChildScrollView로 감싸서 스크롤 가능하게 만듭니다.
        // 화면이 작은 기기에서 키보드가 올라올 때 UI가 가려지는 것을 방지합니다.
        child: SingleChildScrollView(
          child: Container(
            // 정렬을 위해 화면 전체 높이만큼 최소 높이를 확보합니다.
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.top,
            ),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. 로고 섹션 (모바일 앱 최적화)
                Image.asset(
                  'assets/images/logo.png',
                  // 모바일 앱에 적합한 로고 크기
                  width: screenSize.width * logoSize,
                ),
                const SizedBox(height: 40),

                // 2. 아이디/비밀번호 입력창 섹션 (모바일 앱 최적화)
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    hintText: '아이디 입력',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16, // 모바일 앱에 적합한 터치 영역
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide.none, // 테두리 없음
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true, // 비밀번호 가리기
                  decoration: const InputDecoration(
                    hintText: '비밀번호 입력',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16, // 모바일 앱에 적합한 터치 영역
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 로그인 버튼 (모바일 앱 최적화)
                SizedBox(
                  width: double.infinity,
                  height: 52, // 모바일 앱에 적합한 터치 영역
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      '로그인하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 3. 아이디찾기/비밀번호찾기/회원가입 링크 섹션 (모바일 앱 최적화)
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '아이디찾기',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text('|', style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    )),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        '비밀번호 찾기',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text('|', style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    )),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 4. SNS 간편로그인 섹션 (모바일 앱 최적화)
                const Text(
                  '--------- SNS 간편로그인 ---------',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Image.asset(
                        'assets/images/naver.png', 
                        width: 48, // 모바일 앱에 적합한 터치 영역
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {},
                      child: Image.asset(
                        'assets/images/kakao.png', 
                        width: 48, // 모바일 앱에 적합한 터치 영역
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {},
                      child: Image.asset(
                        'assets/images/google.png', 
                        width: 48, // 모바일 앱에 적합한 터치 영역
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
